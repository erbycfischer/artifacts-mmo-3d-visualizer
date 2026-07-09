extends CanvasLayer
class_name VisualizerUI

signal overlay_changed(overlay_name: String, enabled: bool)

var _mode_label: Label
var _status_label: Label
var _summary_label: Label
var _selection_label: Label
var _decisions_label: Label
var _market_label: Label
var _routes_toggle: CheckButton
var _market_toggle: CheckButton
var _labels_toggle: CheckButton


func _ready() -> void:
	_build_ui()


func set_mode(mode: String, detail: String = "") -> void:
	if _mode_label == null:
		return
	if detail.is_empty():
		_mode_label.text = "Mode: %s" % mode
	else:
		_mode_label.text = "Mode: %s — %s" % [mode, detail]


func set_status(status: String) -> void:
	if _status_label:
		_status_label.text = "Status: %s" % status


func set_world_summary(map_count: int, character_count: int) -> void:
	if _summary_label:
		_summary_label.text = "Maps: %d | Characters: %d" % [map_count, character_count]


func set_selected_tile(tile: Dictionary) -> void:
	if _selection_label == null:
		return
	if tile.is_empty():
		_selection_label.text = "Selected: none"
		return

	var content_type := str(tile.get("content_type", ""))
	var content_code := str(tile.get("content_code", ""))
	var interactions: Variant = tile.get("interactions", {})
	if content_type.is_empty() and interactions is Dictionary:
		var content: Variant = interactions.get("content", {})
		if content is Dictionary:
			content_type = str(content.get("type", "terrain"))
			content_code = str(content.get("code", ""))

	_selection_label.text = "Selected: %s (%s,%s) %s/%s" % [
		tile.get("layer", "overworld"),
		tile.get("x", 0),
		tile.get("y", 0),
		content_type if not content_type.is_empty() else "terrain",
		content_code if not content_code.is_empty() else "-",
	]


func set_decisions(decisions: Dictionary) -> void:
	if _decisions_label == null:
		return
	if decisions.is_empty():
		_decisions_label.text = "Decisions: none"
		return

	var lines: PackedStringArray = []
	for character_name in decisions.keys():
		var decision: Variant = decisions[character_name]
		if decision is Dictionary:
			lines.append("%s -> %s (%s)" % [
				character_name,
				decision.get("action", "?"),
				decision.get("reason", ""),
			])
	_decisions_label.text = "Decisions:\n" + "\n".join(lines)


func set_market_signals(signals: Array) -> void:
	if _market_label == null:
		return
	if signals.is_empty():
		_market_label.text = "Market: none"
		return

	var lines: PackedStringArray = []
	for signal_data in signals:
		if signal_data is Dictionary:
			lines.append("%s spread=%s score=%.2f" % [
				signal_data.get("code", "?"),
				signal_data.get("spread", "?"),
				float(signal_data.get("score", 0.0)),
			])
	_market_label.text = "Market:\n" + "\n".join(lines)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 12.0
	panel.offset_top = 12.0
	panel.offset_right = 420.0
	panel.offset_bottom = 380.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = "Artifacts 3D Visualizer"
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)

	_mode_label = Label.new()
	_mode_label.text = "Mode: starting"
	_mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_mode_label)

	_status_label = Label.new()
	_status_label.text = "Status: starting"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status_label)

	_summary_label = Label.new()
	_summary_label.text = "Maps: 0 | Characters: 0"
	column.add_child(_summary_label)

	_selection_label = Label.new()
	_selection_label.text = "Selected: none"
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_selection_label)

	_routes_toggle = CheckButton.new()
	_routes_toggle.text = "Show routes"
	_routes_toggle.button_pressed = true
	_routes_toggle.toggled.connect(func(enabled: bool) -> void: overlay_changed.emit("routes", enabled))
	column.add_child(_routes_toggle)

	_market_toggle = CheckButton.new()
	_market_toggle.text = "Show market signals"
	_market_toggle.button_pressed = true
	_market_toggle.toggled.connect(func(enabled: bool) -> void: overlay_changed.emit("market", enabled))
	column.add_child(_market_toggle)

	_labels_toggle = CheckButton.new()
	_labels_toggle.text = "Show tile labels"
	_labels_toggle.button_pressed = true
	_labels_toggle.toggled.connect(func(enabled: bool) -> void: overlay_changed.emit("labels", enabled))
	column.add_child(_labels_toggle)

	_decisions_label = Label.new()
	_decisions_label.text = "Decisions: none"
	_decisions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_decisions_label)

	_market_label = Label.new()
	_market_label.text = "Market: none"
	_market_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_market_label)

	var help := Label.new()
	help.text = "Move: WASD | Orbit: middle-drag | Zoom: wheel | Select: left-click tile"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(help)
