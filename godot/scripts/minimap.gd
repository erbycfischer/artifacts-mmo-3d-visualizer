extends Control
class_name Minimap

## A lightweight 2D top-down projection of the active layer, drawn from the same
## world snapshot the 3D scene uses: content dots (one color per content type,
## matching the MapRenderer legend) plus character positions (ring markers). The
## selected character is drawn larger and brighter so the player can read their
## place in the world at a glance — the official 2D client shows exactly this.

const SIZE := 220.0
const MARGIN := 12.0
const PAD := 10.0

var _active_layer := "overworld"
var _tile_bounds := Rect2(0, 0, 1, 1)
var _content_points: Array = []
var _char_points: Array = []
var _selected_character := ""


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = -MARGIN
	offset_bottom = -MARGIN
	custom_minimum_size = Vector2(SIZE, SIZE)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	visible = false


func set_active_layer(layer: String) -> void:
	_active_layer = layer
	queue_redraw()


func set_selected_character(name: String) -> void:
	_selected_character = name
	queue_redraw()


func render(state: Node, active_layer: String) -> void:
	_active_layer = active_layer
	_collect(state)
	queue_redraw()


func _collect(state: Node) -> void:
	var maps: Array = state.get("maps")
	var chars: Array = state.get("characters")
	var events: Array = state.get("events")
	var raids: Array = state.get("raids")

	_content_points.clear()
	_char_points.clear()

	var min_x := 999999
	var max_x := -999999
	var min_y := 999999
	var max_y := -999999

	for tile in maps:
		if not (tile is Dictionary):
			continue
		if str(tile.get("layer", "overworld")) != _active_layer:
			continue
		var x := int(tile.get("x", 0))
		var y := int(tile.get("y", 0))
		min_x = mini(min_x, x)
		max_x = maxi(max_x, x)
		min_y = mini(min_y, y)
		max_y = maxi(max_y, y)
		var ct := _content_type(tile)
		if ct != "terrain" and not ct.is_empty():
			_content_points.append({"x": x, "y": y, "type": ct})

	for character in chars:
		if not (character is Dictionary):
			continue
		if str(character.get("layer", "overworld")) != _active_layer:
			continue
		_char_points.append({
			"x": int(character.get("x", 0)),
			"y": int(character.get("y", 0)),
			"name": str(character.get("name", "")),
			"other": bool(character.get("other", false)),
		})
	for item in events:
		if _in_layer(item):
			_content_points.append({"x": int(item.get("x", 0)), "y": int(item.get("y", 0)), "type": "event"})
	for item in raids:
		if _in_layer(item):
			_content_points.append({"x": int(item.get("x", 0)), "y": int(item.get("y", 0)), "type": "raid"})

	if min_x > max_x:
		min_x = 0; max_x = 0
	if min_y > max_y:
		min_y = 0; max_y = 0
	_tile_bounds = Rect2(min_x, min_y, maxi(1, max_x - min_x), maxi(1, max_y - min_y))


func _in_layer(item: Variant) -> bool:
	return item is Dictionary and str(item.get("layer", "overworld")) == _active_layer


func _content_type(tile: Dictionary) -> String:
	var direct := str(tile.get("content_type", ""))
	if not direct.is_empty():
		return direct
	var interactions: Variant = tile.get("interactions", {})
	if interactions is Dictionary:
		var content: Variant = interactions.get("content", {})
		if content is Dictionary:
			return str(content.get("type", "terrain"))
	return "terrain"


func _draw() -> void:
	if not visible:
		return
	var rect := Rect2(Vector2.ZERO, size)
	var bg := Color(0.05, 0.07, 0.05, 0.82)
	draw_rect(rect, bg, true)
	draw_rect(rect, Color(0.4, 0.6, 0.35, 0.6), false, 1.5)

	if _content_points.is_empty() and _char_points.is_empty():
		_draw_title("Layer: %s (empty)" % _active_layer)
		return

	var plot := Rect2(PAD, PAD + 16.0, size.x - PAD * 2.0, size.y - PAD * 2.0 - 16.0)
	var span := _tile_bounds.size
	var sx := plot.size.x / span.x
	var sy := plot.size.y / span.y
	var scale := mini(sx, sy)

	for point in _content_points:
		var px := plot.position.x + float(point.get("x", 0) - int(_tile_bounds.position.x)) * scale + scale * 0.5
		var py := plot.position.y + float(point.get("y", 0) - int(_tile_bounds.position.y)) * scale + scale * 0.5
		draw_circle(Vector2(px, py), maxf(2.5, scale * 0.45), _dot_color(str(point.get("type", ""))))

	for character in _char_points:
		var px := plot.position.x + float(character.get("x", 0) - int(_tile_bounds.position.x)) * scale + scale * 0.5
		var py := plot.position.y + float(character.get("y", 0) - int(_tile_bounds.position.y)) * scale + scale * 0.5
		var is_self := str(character.get("name", "")) == _selected_character
		var color := Color(1.0, 0.72, 0.25) if character.get("other", false) else Color(0.2, 0.85, 0.95)
		if is_self:
			color = Color(1.0, 0.95, 0.4)
		var r := 4.5 if is_self else 3.0
		draw_circle(Vector2(px, py), r, color)
		if is_self:
			draw_arc(Vector2(px, py), r + 3.0, 0.0, TAU, 24, color, 1.5)

	_draw_title("Layer: %s" % _active_layer)


func _draw_title(text: String) -> void:
	draw_string(ThemeDB.get_default_font(), Vector2(PAD, PAD + 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, size.x - PAD * 2.0, 14, Color(0.85, 0.95, 0.8))


func _dot_color(content_type: String) -> Color:
	match content_type:
		"resource":
			return Color(0.25, 0.55, 0.3)
		"monster":
			return Color(0.78, 0.26, 0.2)
		"raid":
			return Color(0.55, 0.12, 0.1)
		"bank":
			return Color(0.3, 0.45, 0.85)
		"grand_exchange":
			return Color(0.9, 0.75, 0.2)
		"workshop":
			return Color(0.55, 0.4, 0.25)
		"npc", "tasks_master":
			return Color(0.55, 0.45, 0.75)
		"event":
			return Color(0.95, 0.5, 0.2)
		_:
			return Color(0.5, 0.5, 0.5)
