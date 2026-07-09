extends Node3D

const FIXTURE_PATHS: Array[String] = [
	"res://fixtures/world_snapshot.json",
	"res://fixtures/bot_decision.json",
	"res://fixtures/market_signal.json",
]

const VisualStateScript = preload("res://scripts/visual_state.gd")
const StateClientScript = preload("res://scripts/state_client.gd")
const MapRendererScript = preload("res://scripts/map_renderer.gd")
const MarkerRendererScript = preload("res://scripts/marker_renderer.gd")
const VisualizerUIScript = preload("res://scripts/visualizer_ui.gd")

@onready var visual_state: Node = $VisualState
@onready var state_client: Node = $StateClient
@onready var map_renderer: Node3D = $WorldRoot/MapRenderer
@onready var marker_renderer: Node3D = $WorldRoot/MarkerRenderer
@onready var ui_root: CanvasLayer = $UIRoot

var _live_connected := false
var _saw_live_message := false


func _ready() -> void:
	_connect_signals()
	_load_fixture_messages()
	state_client.call("connect_to_server")


func _connect_signals() -> void:
	state_client.status_changed.connect(_on_client_status)
	state_client.message_received.connect(_on_protocol_message)
	visual_state.world_snapshot_updated.connect(_on_world_snapshot_updated)
	visual_state.bot_decision_received.connect(_on_overlay_state_changed)
	visual_state.market_signal_received.connect(_on_overlay_state_changed)
	visual_state.selection_changed.connect(ui_root.set_selected_tile)
	map_renderer.tile_selected.connect(visual_state.select_tile)
	ui_root.overlay_changed.connect(_on_overlay_changed)


func _load_fixture_messages() -> void:
	for path in FIXTURE_PATHS:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_warning("Missing visualizer fixture: %s" % path)
			continue

		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			visual_state.call("apply_message", parsed)
		else:
			push_warning("Fixture did not contain a protocol message: %s" % path)

	_live_connected = false
	_saw_live_message = false
	ui_root.call("set_mode", "Offline", "fixtures; waiting for hub")
	ui_root.call("set_status", "offline fixtures loaded; connecting to ws://127.0.0.1:8787")


func _on_client_status(status: String) -> void:
	ui_root.call("set_status", status)
	var lower := status.to_lower()
	if lower.begins_with("connected"):
		_live_connected = true
		if _saw_live_message:
			ui_root.call("set_mode", "Live", "hub streaming")
		else:
			ui_root.call("set_mode", "Connected", "waiting for first snapshot")
	elif "closed" in lower or "retrying" in lower or "error" in lower:
		_live_connected = false
		if _saw_live_message:
			ui_root.call("set_mode", "Reconnecting", "last live data kept")
		else:
			ui_root.call("set_mode", "Offline", "fixtures; hub unavailable")


func _on_protocol_message(message: Dictionary) -> void:
	_saw_live_message = true
	if _live_connected:
		ui_root.call("set_mode", "Live", "hub streaming")
	visual_state.call("apply_message", message)


func _on_world_snapshot_updated() -> void:
	map_renderer.call("render_world", visual_state.get("maps"))
	marker_renderer.call("render_state", visual_state)
	ui_root.call("set_world_summary", visual_state.get("maps").size(), visual_state.get("characters").size())


func _on_overlay_state_changed(_payload: Dictionary) -> void:
	marker_renderer.call("render_state", visual_state)
	ui_root.call("set_decisions", visual_state.get("latest_decisions"))
	ui_root.call("set_market_signals", visual_state.get("market_signals"))


func _on_overlay_changed(overlay_name: String, enabled: bool) -> void:
	match overlay_name:
		"routes":
			marker_renderer.set("show_routes", enabled)
		"market":
			marker_renderer.set("show_market_signals", enabled)
		"labels":
			map_renderer.set("show_labels", enabled)
			map_renderer.call("render_world", visual_state.get("maps"))
		_:
			return
	marker_renderer.call("render_state", visual_state)
