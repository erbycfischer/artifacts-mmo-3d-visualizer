extends CanvasLayer
class_name VisualizerUI

signal overlay_changed(overlay_name: String, enabled: bool)
signal connect_requested(url: String)
signal disconnect_requested
signal auth_requested(token: String)
signal logout_requested
signal character_selected(character_name: String)
signal action_requested(action_name: String, payload: Dictionary)
signal fixtures_only_toggled(enabled: bool)
signal grid_toggled(enabled: bool)
signal topdown_toggled(enabled: bool)
signal minimap_toggled(enabled: bool)
signal layer_selected(layer: String)

var _mode_label: Label
var _status_label: Label
var _summary_label: Label
var _selection_label: Label
var _session_label: Label
var _hud_label: Label
var _action_label: Label
var _decisions_label: Label
var _market_label: Label
var _logs_label: Label
var _character_option: OptionButton
var _host_edit: LineEdit
var _token_edit: LineEdit
var _fixtures_only: CheckButton
var _routes_toggle: CheckButton
var _market_toggle: CheckButton
var _labels_toggle: CheckButton
var _move_btn: Button
var _fight_btn: Button
var _gather_btn: Button
var _rest_btn: Button
var _bank_deposit_btn: Button
var _bank_withdraw_btn: Button
var _ge_scan_btn: Button
var _craft_btn: Button
var _task_new_btn: Button
var _task_complete_btn: Button
var _npc_buy_btn: Button
var _npc_sell_btn: Button
var _transition_btn: Button
var _bank_gold_deposit_btn: Button
var _bank_gold_withdraw_btn: Button
var _equip_btn: Button
var _use_btn: Button
var _ge_buy_btn: Button
var _ge_sell_btn: Button
var _count_edit: LineEdit
var _item_edit: LineEdit
var _grid_toggle: CheckButton
var _topdown_toggle: CheckButton
var _layer_option: OptionButton
var _coords_label: Label
var _legend_label: Label

var _selected_tile: Dictionary = {}
var _selected_character: String = ""
var _active_layer: String = "overworld"
var _characters_cooling: Dictionary = {}
var _authenticated := false


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
	_selected_tile = tile
	if _selection_label == null:
		return
	if tile.is_empty():
		_selection_label.text = "Selected: none"
		_refresh_coords()
		_update_action_buttons()
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
	_refresh_coords()
	_update_action_buttons()


func set_selected_character_info(character: Dictionary) -> void:
	# Mirror the selected character's grid position into the coordinate readout.
	if _hud_label == null:
		return
	_refresh_coords()


func set_layers(layers: Array) -> void:
	# Populate the layer switcher so the player can focus a band. Overworld is
	# always listed first; the rest follow roughly top-to-bottom of the stack.
	if _layer_option == null:
		return
	_layer_option.clear()
	var ordered: Array = ["overworld"]
	for layer in layers:
		var name := str(layer)
		if name != "overworld" and not ordered.has(name):
			ordered.append(name)
	for name in ordered:
		_layer_option.add_item(name)
	var idx := ordered.find(_active_layer)
	if idx < 0:
		idx = 0
	_layer_option.select(idx)


func set_top_down_state(enabled: bool) -> void:
	if _topdown_toggle:
		_topdown_toggle.set_pressed_no_signal(enabled)


func set_layer(layer: String) -> void:
	_active_layer = layer
	if _layer_option:
		var idx := _layer_option.get_item_index(0)
		# OptionButton has no direct name->index lookup; scan items.
		for i in range(_layer_option.item_count):
			if _layer_option.get_item_text(i) == layer:
				_layer_option.select(i)
				break


func _refresh_coords() -> void:
	if _coords_label == null:
		return
	var tile_part := "no tile"
	if not _selected_tile.is_empty():
		tile_part = "(%s, %s) %s" % [
			_selected_tile.get("x", 0),
			_selected_tile.get("y", 0),
			_selected_tile.get("layer", "overworld"),
		]
	_coords_label.text = "Coords: tile %s" % tile_part


func set_session_status(status: Dictionary) -> void:
	if _session_label == null:
		return
	var authenticated := bool(status.get("authenticated", false))
	_authenticated = authenticated
	var selected := str(status.get("selected", ""))
	var err := str(status.get("error", ""))
	var chars: Array = status.get("characters", [])
	_refresh_character_options(chars, selected)
	var pending := int(status.get("pending_items", 0))
	var text := "Session: %s" % ("authenticated" if authenticated else "unauthenticated")
	if not selected.is_empty():
		text += " | selected %s" % selected
	if pending > 0:
		text += " | pending %d" % pending
	if not err.is_empty() and err != "Null" and err != "<null>":
		text += " | error: %s" % err
	_session_label.text = text
	if authenticated:
		set_mode("Playing" if not selected.is_empty() else "Authenticated", "official API actions enabled")
	else:
		set_mode("Unauthenticated", "enter token or set ARTIFACTS_API_TOKEN on bridge")
	_update_action_buttons()


func set_action_result(result: Dictionary) -> void:
	if _action_label == null:
		return
	var ok := bool(result.get("ok", false))
	_action_label.text = "Action: %s %s — %s" % [
		result.get("character", "?"),
		result.get("action", "?"),
		("ok" if ok else str(result.get("message", "failed"))),
	]


func set_login_required(payload: Dictionary) -> void:
	# Artifacts has no OAuth: the player token is issued on the website. Send the
	# user there to copy it, then they paste it here or set ARTIFACTS_API_TOKEN.
	var login_url := str(payload.get("login_url", "https://artifactsmmo.com"))
	var message := str(payload.get("message", "Login required to play."))
	if _action_label:
		_action_label.text = "Action: %s" % message
	if DisplayServer.has_feature(DisplayServer.FEATURE_POINTER):
		OS.shell_open(login_url)
	set_mode("Login required", "token page opened — paste token below or set ARTIFACTS_API_TOKEN")


func set_account_logs(entries: Array) -> void:
	if _logs_label == null:
		return
	if entries.is_empty():
		_logs_label.text = "Logs: none"
		return
	var lines: PackedStringArray = []
	var count := mini(entries.size(), 6)
	for i in range(entries.size() - count, entries.size()):
		var entry: Variant = entries[i]
		if entry is Dictionary:
			lines.append("%s: %s" % [entry.get("type", "log"), entry.get("description", "")])
	_logs_label.text = "Logs:\n" + "\n".join(lines)


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


func set_characters_from_snapshot(characters: Array) -> void:
	_characters_cooling.clear()
	var selected_hud := {}
	for character in characters:
		if character is Dictionary:
			var name := str(character.get("name", ""))
			_characters_cooling[name] = float(character.get("cooldown", 0))
			if name == _selected_character:
				selected_hud = character
	_update_character_hud(selected_hud)
	_update_action_buttons()


func _update_character_hud(character: Dictionary) -> void:
	if _hud_label == null:
		return
	if character.is_empty():
		_hud_label.text = "HUD: select a character"
		return
	var inv: Variant = character.get("inventory", {})
	var used := 0
	var inv_max := 0
	if inv is Dictionary:
		used = int(inv.get("used", 0))
		inv_max = int(inv.get("max", 0))
	var coords := "(%s,%s) %s" % [
		character.get("x", "?"),
		character.get("y", "?"),
		character.get("layer", "overworld"),
	]
	_hud_label.text = "HUD: %s @ %s | HP %s/%s | xp %s | gold %s | inv %s/%s | CD %.0fs" % [
		character.get("name", "?"),
		coords,
		character.get("hp", "?"),
		character.get("max_hp", "?"),
		character.get("xp", 0),
		character.get("gold", 0),
		used,
		inv_max,
		float(character.get("cooldown", 0)),
	]


func get_host_url() -> String:
	return _host_edit.text.strip_edges() if _host_edit else "ws://127.0.0.1:8787"


func set_host_url(url: String) -> void:
	if _host_edit:
		_host_edit.text = url


func fixtures_only() -> bool:
	return _fixtures_only.button_pressed if _fixtures_only else false


func set_fixtures_only(enabled: bool) -> void:
	if _fixtures_only:
		_fixtures_only.set_pressed_no_signal(enabled)


func _refresh_character_options(chars: Array, selected: String) -> void:
	if _character_option == null:
		return
	_character_option.clear()
	var index := 0
	var selected_index := 0
	for character in chars:
		if character is Dictionary:
			var name := str(character.get("name", ""))
			_character_option.add_item(name)
			if name == selected:
				selected_index = index
			index += 1
	if _character_option.item_count > 0:
		_character_option.select(selected_index)
		_selected_character = _character_option.get_item_text(selected_index)


func _update_action_buttons() -> void:
	var cooling := float(_characters_cooling.get(_selected_character, 0.0)) > 0.0
	var content_type := str(_selected_tile.get("content_type", ""))
	var no_char := _selected_character.is_empty() or not _authenticated
	if _move_btn:
		_move_btn.disabled = cooling or _selected_tile.is_empty() or no_char
	if _fight_btn:
		_fight_btn.disabled = cooling or content_type != "monster" or no_char
	if _gather_btn:
		_gather_btn.disabled = cooling or content_type != "resource" or no_char
	if _rest_btn:
		_rest_btn.disabled = cooling or no_char
	if _bank_deposit_btn:
		_bank_deposit_btn.disabled = cooling or content_type != "bank" or no_char
	if _bank_withdraw_btn:
		_bank_withdraw_btn.disabled = cooling or content_type != "bank" or no_char
	if _bank_gold_deposit_btn:
		_bank_gold_deposit_btn.disabled = cooling or content_type != "bank" or no_char
	if _bank_gold_withdraw_btn:
		_bank_gold_withdraw_btn.disabled = cooling or content_type != "bank" or no_char
	if _ge_scan_btn:
		_ge_scan_btn.disabled = cooling or content_type != "grand_exchange" or no_char
	if _ge_buy_btn:
		_ge_buy_btn.disabled = cooling or content_type != "grand_exchange" or no_char
	if _ge_sell_btn:
		_ge_sell_btn.disabled = cooling or content_type != "grand_exchange" or no_char
	if _craft_btn:
		_craft_btn.disabled = cooling or content_type != "workshop" or no_char
	if _equip_btn:
		_equip_btn.disabled = cooling or content_type != "workshop" or no_char
	if _use_btn:
		_use_btn.disabled = cooling or content_type != "workshop" or no_char
	if _task_new_btn:
		_task_new_btn.disabled = cooling or (content_type != "tasks_master" and content_type != "npc") or no_char
	if _task_complete_btn:
		_task_complete_btn.disabled = cooling or (content_type != "tasks_master" and content_type != "npc") or no_char
	if _npc_buy_btn:
		_npc_buy_btn.disabled = cooling or content_type != "npc" or no_char
	if _npc_sell_btn:
		_npc_sell_btn.disabled = cooling or content_type != "npc" or no_char
	if _transition_btn:
		_transition_btn.disabled = cooling or no_char


func _emit_action(action_name: String, payload: Dictionary = {}) -> void:
	if _selected_character.is_empty():
		return
	action_requested.emit(action_name, payload)


func _parsed_quantity() -> int:
	var raw := _count_edit.text.strip_edges() if _count_edit else ""
	var value := int(raw)
	if value <= 0:
		value = 1
	return value


func _parsed_item() -> String:
	var raw := _item_edit.text.strip_edges() if _item_edit else ""
	return raw if not raw.is_empty() else str(_selected_tile.get("content_code", ""))


func _emit_ge(action_name: String) -> void:
	# Grand Exchange needs a code + quantity; default to the selected tile's
	# content code so a player parked on a resource/monster can one-click sell.
	var code := _parsed_item()
	if code.is_empty():
		return
	_emit_action(action_name, {"code": code, "quantity": _parsed_quantity()})


func _emit_npc(action_name: String) -> void:
	var code := _parsed_item()
	if code.is_empty():
		return
	_emit_action(action_name, {"code": code, "quantity": _parsed_quantity()})


func _legend_text() -> String:
	# Self-explanatory legend mapping content types to the marker colors/symbols
	# used by MapRenderer, mirroring the tile legend the 2D game conveys.
	var rows := PackedStringArray([
		"Legend:",
		"  ■ green  resource",
		"  ■ red    monster",
		"  ■ dark red raid",
		"  ■ blue   bank",
		"  ■ gold   grand exchange",
		"  ■ brown  workshop",
		"  ■ purple  npc / tasks master",
		"  ■ orange event",
		"  ring = own char  [world] = other",
	])
	return "\n".join(rows)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 12.0
	panel.offset_top = 12.0
	panel.offset_right = 460.0
	panel.offset_bottom = 720.0
	add_child(panel)

	var margin := MarginContainer.new()
	for key in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(key, 10)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	var title := Label.new()
	title.text = "Official Artifacts 3D Client"
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

	_session_label = Label.new()
	_session_label.text = "Session: unauthenticated"
	_session_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_session_label)

	_host_edit = LineEdit.new()
	_host_edit.placeholder_text = "ws://127.0.0.1:8787"
	_host_edit.text = "ws://127.0.0.1:8787"
	column.add_child(_host_edit)

	var conn_row := HBoxContainer.new()
	column.add_child(conn_row)
	var connect_btn := Button.new()
	connect_btn.text = "Connect"
	connect_btn.pressed.connect(func() -> void: connect_requested.emit(_host_edit.text.strip_edges()))
	conn_row.add_child(connect_btn)
	var disconnect_btn := Button.new()
	disconnect_btn.text = "Disconnect"
	disconnect_btn.pressed.connect(func() -> void: disconnect_requested.emit())
	conn_row.add_child(disconnect_btn)

	_fixtures_only = CheckButton.new()
	_fixtures_only.text = "Fixtures only (no hub)"
	_fixtures_only.toggled.connect(func(enabled: bool) -> void: fixtures_only_toggled.emit(enabled))
	column.add_child(_fixtures_only)

	_token_edit = LineEdit.new()
	_token_edit.placeholder_text = "Artifacts token"
	_token_edit.secret = true
	column.add_child(_token_edit)

	var auth_row := HBoxContainer.new()
	column.add_child(auth_row)
	var auth_btn := Button.new()
	auth_btn.text = "Auth"
	auth_btn.pressed.connect(func() -> void: auth_requested.emit(_token_edit.text.strip_edges()))
	auth_row.add_child(auth_btn)
	var logout_btn := Button.new()
	logout_btn.text = "Logout"
	logout_btn.pressed.connect(func() -> void: logout_requested.emit())
	auth_row.add_child(logout_btn)

	_character_option = OptionButton.new()
	_character_option.item_selected.connect(func(idx: int) -> void:
		_selected_character = _character_option.get_item_text(idx)
		character_selected.emit(_selected_character)
		_update_action_buttons()
	)
	column.add_child(_character_option)

	_hud_label = Label.new()
	_hud_label.text = "HUD: select a character"
	_hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_hud_label)

	_summary_label = Label.new()
	_summary_label.text = "Maps: 0 | Characters: 0"
	column.add_child(_summary_label)

	_selection_label = Label.new()
	_selection_label.text = "Selected: none"
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_selection_label)

	var action_row := HBoxContainer.new()
	column.add_child(action_row)
	_move_btn = Button.new()
	_move_btn.text = "Move"
	_move_btn.pressed.connect(func() -> void:
		var payload := {
			"x": int(_selected_tile.get("x", 0)),
			"y": int(_selected_tile.get("y", 0)),
			"layer": str(_selected_tile.get("layer", "overworld")),
		}
		var map_id: Variant = _selected_tile.get("map_id", null)
		if map_id != null and str(map_id) != "":
			payload["map_id"] = map_id
		_emit_action("move", payload)
	)
	action_row.add_child(_move_btn)
	_fight_btn = Button.new()
	_fight_btn.text = "Fight"
	_fight_btn.pressed.connect(func() -> void: _emit_action("fight", {}))
	action_row.add_child(_fight_btn)
	_gather_btn = Button.new()
	_gather_btn.text = "Gather"
	_gather_btn.pressed.connect(func() -> void: _emit_action("gather", {}))
	action_row.add_child(_gather_btn)
	_rest_btn = Button.new()
	_rest_btn.text = "Rest"
	_rest_btn.pressed.connect(func() -> void: _emit_action("rest", {}))
	action_row.add_child(_rest_btn)

	var bank_row := HBoxContainer.new()
	column.add_child(bank_row)
	_bank_deposit_btn = Button.new()
	_bank_deposit_btn.text = "Bank deposit"
	_bank_deposit_btn.pressed.connect(func() -> void: _emit_action("bank-deposit-item", {"items": []}))
	bank_row.add_child(_bank_deposit_btn)
	_bank_withdraw_btn = Button.new()
	_bank_withdraw_btn.text = "Bank withdraw"
	_bank_withdraw_btn.pressed.connect(func() -> void: _emit_action("bank-withdraw-item", {"items": []}))
	bank_row.add_child(_bank_withdraw_btn)
	_bank_gold_deposit_btn = Button.new()
	_bank_gold_deposit_btn.text = "Deposit gold"
	_bank_gold_deposit_btn.pressed.connect(func() -> void:
		_emit_action("bank-deposit-gold", {"quantity": _parsed_quantity()})
	)
	bank_row.add_child(_bank_gold_deposit_btn)
	_bank_gold_withdraw_btn = Button.new()
	_bank_gold_withdraw_btn.text = "Withdraw gold"
	_bank_gold_withdraw_btn.pressed.connect(func() -> void:
		_emit_action("bank-withdraw-gold", {"quantity": _parsed_quantity()})
	)
	bank_row.add_child(_bank_gold_withdraw_btn)

	var ge_row := HBoxContainer.new()
	column.add_child(ge_row)
	_ge_scan_btn = Button.new()
	_ge_scan_btn.text = "GE orders"
	_ge_scan_btn.pressed.connect(func() -> void: _emit_action("grand-exchange-orders", {}))
	ge_row.add_child(_ge_scan_btn)
	_ge_buy_btn = Button.new()
	_ge_buy_btn.text = "GE buy"
	_ge_buy_btn.pressed.connect(func() -> void: _emit_ge("grand-exchange-buy"))
	ge_row.add_child(_ge_buy_btn)
	_ge_sell_btn = Button.new()
	_ge_sell_btn.text = "GE sell"
	_ge_sell_btn.pressed.connect(func() -> void: _emit_ge("grand-exchange-create-sell-order"))
	ge_row.add_child(_ge_sell_btn)

	var craft_row := HBoxContainer.new()
	column.add_child(craft_row)
	_craft_btn = Button.new()
	_craft_btn.text = "Craft"
	_craft_btn.pressed.connect(func() -> void:
		_emit_action("craft", {"code": str(_selected_tile.get("content_code", "")), "quantity": 1})
	)
	craft_row.add_child(_craft_btn)
	_equip_btn = Button.new()
	_equip_btn.text = "Equip"
	_equip_btn.pressed.connect(func() -> void:
		_emit_action("equip", {"code": _parsed_item(), "quantity": _parsed_quantity()})
	)
	craft_row.add_child(_equip_btn)
	_use_btn = Button.new()
	_use_btn.text = "Use item"
	_use_btn.pressed.connect(func() -> void:
		_emit_action("use", {"code": _parsed_item(), "quantity": _parsed_quantity()})
	)
	craft_row.add_child(_use_btn)

	var d3_row := HBoxContainer.new()
	column.add_child(d3_row)
	_task_new_btn = Button.new()
	_task_new_btn.text = "Task new"
	_task_new_btn.pressed.connect(func() -> void: _emit_action("task-new", {}))
	d3_row.add_child(_task_new_btn)
	_task_complete_btn = Button.new()
	_task_complete_btn.text = "Task done"
	_task_complete_btn.pressed.connect(func() -> void: _emit_action("task-complete", {}))
	d3_row.add_child(_task_complete_btn)
	_npc_buy_btn = Button.new()
	_npc_buy_btn.text = "NPC buy"
	_npc_buy_btn.pressed.connect(func() -> void: _emit_npc("npc-buy"))
	d3_row.add_child(_npc_buy_btn)
	_npc_sell_btn = Button.new()
	_npc_sell_btn.text = "NPC sell"
	_npc_sell_btn.pressed.connect(func() -> void: _emit_npc("npc-sell"))
	d3_row.add_child(_npc_sell_btn)
	_transition_btn = Button.new()
	_transition_btn.text = "Transition"
	_transition_btn.pressed.connect(func() -> void: _emit_action("transition", {}))
	d3_row.add_child(_transition_btn)

	var args_row := HBoxContainer.new()
	column.add_child(args_row)
	_item_edit = LineEdit.new()
	_item_edit.placeholder_text = "item code (e.g. wooden_sword)"
	_item_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	args_row.add_child(_item_edit)
	_count_edit = LineEdit.new()
	_count_edit.placeholder_text = "qty"
	_count_edit.text = "1"
	_count_edit.max_length = 6
	_count_edit.custom_minimum_size = Vector2(56, 0)
	args_row.add_child(_count_edit)

	_action_label = Label.new()
	_action_label.text = "Action: none"
	_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_action_label)

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
	_labels_toggle.button_pressed = false
	_labels_toggle.toggled.connect(func(enabled: bool) -> void: overlay_changed.emit("labels", enabled))
	column.add_child(_labels_toggle)

	_grid_toggle = CheckButton.new()
	_grid_toggle.text = "Show grid lines"
	_grid_toggle.button_pressed = false
	_grid_toggle.toggled.connect(func(enabled: bool) -> void: grid_toggled.emit(enabled))
	column.add_child(_grid_toggle)

	_topdown_toggle = CheckButton.new()
	_topdown_toggle.text = "Top-down (2D) camera"
	_topdown_toggle.button_pressed = false
	_topdown_toggle.toggled.connect(func(enabled: bool) -> void: topdown_toggled.emit(enabled))
	column.add_child(_topdown_toggle)

	var minimap_toggle := CheckButton.new()
	minimap_toggle.name = "MinimapToggle"
	minimap_toggle.text = "Show minimap"
	minimap_toggle.button_pressed = false
	minimap_toggle.toggled.connect(func(enabled: bool) -> void: minimap_toggled.emit(enabled))
	column.add_child(minimap_toggle)

	_coords_label = Label.new()
	_coords_label.text = "Coords: tile no tile"
	_coords_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_coords_label)

	var layer_label := Label.new()
	layer_label.text = "Layer:"
	column.add_child(layer_label)
	_layer_option = OptionButton.new()
	_layer_option.item_selected.connect(func(idx: int) -> void:
		_active_layer = _layer_option.get_item_text(idx)
		layer_selected.emit(_active_layer)
	)
	column.add_child(_layer_option)

	_legend_label = Label.new()
	_legend_label.text = _legend_text()
	_legend_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_legend_label.add_theme_font_size_override("font_size", 13)
	column.add_child(_legend_label)

	_decisions_label = Label.new()
	_decisions_label.text = "Decisions: none"
	_decisions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_decisions_label)

	_market_label = Label.new()
	_market_label.text = "Market: none"
	_market_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_market_label)

	_logs_label = Label.new()
	_logs_label.text = "Logs: none"
	_logs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_logs_label)

	var help := Label.new()
	help.text = "Move: WASD | Orbit: middle-drag | Zoom: wheel | Select: left-click | Rest: R | Follow: F"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(help)

	_update_action_buttons()
