extends CanvasLayer
# LOCKER (P8-15, owner Q3 a; Flow screen "locker", args {"back": "title"}): the star rewards and what you wear.
#   Left: the star ladder (stars.gd REWARDS), one row per reward with the stars it opens at, what it is, and GOT /
#   "N TO GO" (the next one, lit) / a lock. It scrolls (drag or wheel) and opens scrolled to the next reward. Court
#   looks and roster slots are listed but not picked here (courts are on the Quick Game COURT button).
#   Right: three rows, JERSEY, BALL and VAN, each with four big tiles: CLASSIC (the default) and the three rewards.
#   A tile is its own preview: Deuce in that jersey (his v2 card through Sheets), the ball's first spin frame, the
#   van paint. Tap an open tile to wear it (Cosmetics.pick saves at once; the worn one is lit gold with ON). A
#   locked tile shows a lock and the stars it needs; tapping it says so in the line under the title.
#   Header: BACK (top-left, to args.back), LOCKER, your stars of 72 and the next reward.
# Picks are saved by cosmetics.gd in Difficulty.unlock_path(); any test run uses the test settings file, never the
# owner's settings.cfg. Desktop: Escape = BACK (main.gd turns the Android back gesture into an Escape press).
# Like howto.gd the taps are ignored for ARM_T s after the screen opens, so a double tap on the title's LOCKER button
# can't land on a tile. auto_step() (test drivers): keep the picks and go BACK.

const UI = preload("res://scripts/ui_kit.gd")
const Flow = preload("res://scripts/flow.gd")
const Stars = preload("res://scripts/stars.gd")
const Cosmetics = preload("res://scripts/cosmetics.gd")
const Sheets = preload("res://scripts/sheets.gd")

const ARM_T := 0.4                       # s the taps are ignored after the screen opens
const STATUS_T := 2.6                    # s a "locked" message stays in the status line
const FRAME_SIZE := Vector2(1280, 720)   # the layout box, centred on wider / taller screens
const BACK_POS := Vector2(16, 10)        # BACK, top-left (UI.SMALL_SIZE)
const TITLE_Y := 4.0                     # LOCKER
const STATUS_Y := 74.0                   # the next reward / a locked message
const STARS_BOX := Rect2(1004, 18, 260, 92)   # your stars, top-right
const STARS_FONT := 44
const STATUS_FONT := 26
const CONTENT_Y := 134.0                 # top of the ladder and of the pick rows
const LADDER_RECT := Rect2(16, 134, 400, 572)   # the ladder panel
const LADDER_HEAD := 38.0                # px: "STAR REWARDS" over the list
const LADDER_ROW_H := 58.0               # px per reward row
const PICKS_X := 434.0                   # left edge of the pick rows
const PICK_LABEL_H := 32.0               # px: "JERSEY: HOME WHITES" over the tiles
const TILE_SIZE := Vector2(200, 152)     # one tile (>= UI.MIN_BUTTON)
const TILE_GAP := 10.0                   # px between tiles
const ROW_GAP := 10.0                    # px between pick rows
const TILE_NAME_H := 30.0                # px at the bottom of a tile: the item name
const TILE_PAD := 8.0
const TILE_FILL := Color(0.12, 0.14, 0.2, 0.96)
const TILE_FILL_LOCKED := Color(0.09, 0.09, 0.12, 0.96)
const TILE_BORDER_W := 3
const TILE_PICKED_W := 8
const LOCKED_TINT := Color(0.32, 0.32, 0.38, 1.0)   # art of a locked item (a dark silhouette of what is to come)
const DIM_TEXT := Color(0.66, 0.68, 0.75)
const GOT_TINT := Color(1.0, 0.82, 0.25, 0.10)     # ladder row you have
const NEXT_TINT := Color(0.45, 0.65, 1.0, 0.22)    # ladder rows of the next reward
const STAR_COLOR := Color(1.0, 0.82, 0.25)
const STAR_OFF := Color(0.42, 0.43, 0.5)
const NAME_FONT := 20
const OPT_LABEL_FONT := 24               # the pick row's label
const KIND_FONT := 16
const LADDER_NAME_FONT := 22
const LADDER_AT_FONT := 22
const BADGE_R := 24.0                    # ladder star badge radius
# previews
const CARD_CROP := Rect2(14, 38, 36, 54)   # px of a 64 x 96 v2 card frame that hold the player (P8 cards: 18..46, 40..90)
const BALL_SCALE := 5.0                  # the 16 x 16 ball frame
const BALL_FRAME := 16                   # px: one spin frame (the sheet is 4 of them side by side)
const VAN_SCALE := 3.0                   # one van frame (van.png is 2 x 2 frames: drive frames x facing right / left)
const BALL_SHADOW := Color(0, 0, 0, 0.35)
const DEFAULT_NAME := "CLASSIC"          # the tile of the default look
const JERSEY_SHEET := "ud_deuce"         # the jersey preview: Deuce (you), <sheet>_j<N> for jersey N
const DEFAULT_BALL := "res://assets/ball/ball.png"
const DEFAULT_VAN := "res://assets/map/van.png"
const KIND_TITLE := {"jersey": "JERSEY", "ball": "BALL", "van": "VAN PAINT", "court": "QUICK GAME COURT",
		"slot": "ROSTER SLOT", "legend": "LEVEL"}

var main                     # main.gd (set by Flow.build_screen)
var audio                    # this screen's audio.gd
var music := "menu"

var _root: Control
var _frame: Control
var _back := "title"
var _arm_t := ARM_T
var _busy := false
var _status: Label
var _status_t := 0.0
var _scroll: ScrollContainer
var _ladder: LadderArt
var _scroll_frames := 0      # frames left until the ladder is scrolled to the next reward (after layout)
var _rows := {}              # kind -> {"label": Label, "tiles": [Button], "ids": ["", "jersey_1", ...]}
var _back_btn: Button

func _ready() -> void:
	var a: Dictionary = Flow.args
	_back = str(a.get("back", "title"))
	if _back == "" or (_back != Flow.GAME and not Flow.SCREENS.has(_back)) or _back == "locker":
		_back = "title"
	_root = UI.screen_root(self)
	_frame = Control.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.offset_left = -FRAME_SIZE.x / 2.0
	_frame.offset_top = -FRAME_SIZE.y / 2.0
	_frame.offset_right = FRAME_SIZE.x / 2.0
	_frame.offset_bottom = FRAME_SIZE.y / 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frame)
	_build()
	_refresh()
	_stat("locker_screen")
	print("LOCKER stars %d/%d, picks %s" % [Stars.total(), Stars.MAX, _picks_text()])

func _process(delta: float) -> void:
	if _arm_t > 0.0:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_refresh()
	if _status_t > 0.0:
		_status_t -= delta
		if _status_t <= 0.0:
			_status.text = _next_text()
			_status.label_settings.font_color = UI.TEXT_COLOR
	if _scroll_frames > 0:
		_scroll_frames -= 1
		if _scroll_frames == 0:
			_scroll_to_next()

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_back()

func _stat(key: String) -> void:
	if main != null and main.has_method("stat"):
		main.stat(key)

func _sfx(sfx_name: String, db := 0.0) -> void:
	if audio != null:
		audio.play(sfx_name, db)

# ---------------- building ----------------

func _build() -> void:
	_back_btn = UI.button(_frame, "BACK", _on_back, UI.KIND_OPT, UI.SMALL_SIZE)
	_back_btn.position = BACK_POS
	var head := VBoxContainer.new()
	head.position = Vector2(0, TITLE_Y)
	head.size = Vector2(FRAME_SIZE.x, 64)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(head)
	UI.title(head, "LOCKER")
	_status = UI.label(_frame, _next_text(), STATUS_FONT)
	_status.position = Vector2(230, STATUS_Y)
	_status.size = Vector2(FRAME_SIZE.x - 460, 44)
	_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status.clip_text = true
	var sc := StarCount.new()
	sc.position = STARS_BOX.position
	sc.size = STARS_BOX.size
	sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(sc)
	_build_ladder()
	var y: float = CONTENT_Y
	for kind in Cosmetics.PICK_KINDS:
		_build_pick_row(str(kind), y)
		y += PICK_LABEL_H + TILE_SIZE.y + ROW_GAP

func _build_ladder() -> void:
	var p := UI.panel(_frame, LADDER_RECT.size)
	p.position = LADDER_RECT.position
	p.size = LADDER_RECT.size
	var sb := UI.style_box(UI.PANEL_COLOR, UI.PANEL_BORDER, UI.BORDER)
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(col)
	var h := UI.label(col, "STAR REWARDS", KIND_FONT + 6, STAR_COLOR)
	h.custom_minimum_size = Vector2(0, LADDER_HEAD - 6.0)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	col.add_child(_scroll)
	_ladder = LadderArt.new()
	_ladder.custom_minimum_size = Vector2(LADDER_RECT.size.x - 40.0, LADDER_ROW_H * Stars.REWARDS.size())
	_ladder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ladder.mouse_filter = Control.MOUSE_FILTER_PASS   # drags reach the ScrollContainer
	_scroll.add_child(_ladder)
	_scroll_frames = 2

func _build_pick_row(kind: String, y: float) -> void:
	var ids: Array = [""]
	ids.append_array(Cosmetics.ids_of(kind))
	var lbl := UI.label(_frame, "", OPT_LABEL_FONT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.position = Vector2(PICKS_X + 4.0, y)
	lbl.size = Vector2(FRAME_SIZE.x - PICKS_X - 20.0, PICK_LABEL_H)
	var tiles: Array = []
	for i in ids.size():
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = TILE_SIZE
		b.size = TILE_SIZE
		b.position = Vector2(PICKS_X + i * (TILE_SIZE.x + TILE_GAP), y + PICK_LABEL_H)
		b.pressed.connect(_on_tile.bind(kind, str(ids[i])))
		_frame.add_child(b)
		var art := TileArt.new()
		art.setup(kind, str(ids[i]))
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(art)
		tiles.append(b)
	_rows[kind] = {"label": lbl, "tiles": tiles, "ids": ids}

# tile looks, labels and what can be tapped now
func _refresh() -> void:
	var armed: bool = _arm_t <= 0.0 and not _busy
	UI.set_enabled(_back_btn, not _busy)
	for kind in _rows:
		var row: Dictionary = _rows[kind]
		var cur: String = Cosmetics.picked(str(kind))
		var nm: String = Cosmetics.item_name(cur) if cur != "" else DEFAULT_NAME
		(row["label"] as Label).text = "%s:  %s" % [str(KIND_TITLE.get(kind, str(kind).to_upper())), nm]
		var tiles: Array = row["tiles"]
		var ids: Array = row["ids"]
		for i in tiles.size():
			var b: Button = tiles[i]
			var id: String = str(ids[i])
			var art: TileArt = b.get_child(0) as TileArt
			art.state = _state(id)
			art.worn = id == cur
			var fill: Color = TILE_FILL_LOCKED if art.state != "open" else TILE_FILL
			var border: Color = UI.LIT_COLOR if art.worn else (UI.OFF_BORDER if art.state == "open" else UI.OPT_BORDER.darkened(0.4))
			var sb := UI.style_box(fill, border, TILE_PICKED_W if art.worn else TILE_BORDER_W)
			for k in ["normal", "hover", "disabled"]:
				b.add_theme_stylebox_override(k, sb)
			b.add_theme_stylebox_override("pressed", UI.style_box(fill.lightened(0.12), UI.LIT_BORDER, TILE_PICKED_W))
			b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			b.disabled = not armed
			art.queue_redraw()
	if _ladder != null:
		_ladder.queue_redraw()

# "open" (can be worn), "locked" (needs more stars) or "missing" (open, but its file is not made yet)
func _state(id: String) -> String:
	if id == "":
		return "open"
	if not Cosmetics.is_unlocked(id):
		return "locked"
	return "open" if Cosmetics.available(id) else "missing"

func _next_text() -> String:
	var nr: Dictionary = Stars.next_reward()
	if nr.is_empty():
		return "EVERY REWARD IS OPEN!"
	var at: int = int(nr["at"])
	var togo: int = at - Stars.total()
	return "NEXT AT %d STARS: %s  (%d TO GO)" % [at, Kit.reward_text(nr), togo]

func _picks_text() -> String:
	var parts: Array = []
	for kind in Cosmetics.PICK_KINDS:
		var id: String = Cosmetics.picked(str(kind))
		parts.append("%s=%s" % [kind, id if id != "" else "default"])
	return " ".join(PackedStringArray(parts))

func _show_status(text: String, color: Color) -> void:
	_status.text = text
	_status.label_settings.font_color = color
	_status_t = STATUS_T

# the ladder scrolled so the next reward's row is the second one shown
func _scroll_to_next() -> void:
	var i: int = Kit.next_row()
	if i < 0:
		i = Stars.REWARDS.size() - 1
	_scroll.scroll_vertical = int(maxf(0.0, (i - 1) * LADDER_ROW_H))

# ---------------- taps ----------------

func _on_tile(kind: String, id: String) -> void:
	if _busy or _arm_t > 0.0:
		return
	var st: String = _state(id)
	if st == "locked":
		_sfx("rim", -10.0)
		_stat("locker_locked_tap")
		_show_status("%s OPENS AT %d STARS  (YOU HAVE %d)" % [Cosmetics.item_name(id), Kit.stars_needed(id), Stars.total()],
				DIM_TEXT)
		return
	if st == "missing":
		_sfx("rim", -10.0)
		_show_status("%s IS NOT READY YET" % Cosmetics.item_name(id), DIM_TEXT)
		return
	if Cosmetics.picked(kind) == id:
		return
	if Cosmetics.pick(kind, id):
		_sfx("bounce", -6.0)
		_stat("locker_pick")
		print("LOCKER pick %s = %s" % [kind, id if id != "" else "default"])
		_show_status("NOW WEARING %s" % (Cosmetics.item_name(id) if id != "" else DEFAULT_NAME + " " +
				str(KIND_TITLE.get(kind, kind))), STAR_COLOR)
	else:
		push_warning("Locker: Cosmetics.pick('%s', '%s') refused" % [kind, id])
	_refresh()

func _on_back() -> void:
	if _busy:
		return
	_busy = true
	_refresh()
	_sfx("bounce", -8.0)
	Flow.go(_back)

# ---------------- test drivers ----------------

# The default choice: keep the picks and go BACK (true once it has left).
func auto_step() -> bool:
	if _busy:
		return false
	_arm_t = 0.0
	_on_back()
	return true


# ---------------- your stars (top-right) ----------------

class StarCount extends Control:
	func _draw() -> void:
		var h: float = size.y
		var c := Vector2(h * 0.5, h * 0.5)
		var pts: PackedVector2Array = Kit.star_points(c, h * 0.42, h * 0.18)
		draw_colored_polygon(pts, STAR_COLOR)
		pts.append(pts[0])
		draw_polyline(pts, UI.OUTLINE_COLOR, 3.0)
		Kit.text(self, "%d/%d" % [Stars.total(), Stars.MAX], Vector2(h, (h - STARS_FONT) / 2.0 - 6.0), size.x - h,
				STARS_FONT, UI.TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)


# ---------------- the ladder (drawn; it scrolls in a ScrollContainer) ----------------

class LadderArt extends Control:
	func _draw() -> void:
		var t: int = Stars.total()
		var nxt: int = Kit.next_row()
		var next_at: int = int(Stars.REWARDS[nxt]["at"]) if nxt >= 0 else -1
		var w: float = size.x
		var rh: float = LADDER_ROW_H
		for i in Stars.REWARDS.size():
			var r: Dictionary = Stars.REWARDS[i]
			var at: int = int(r["at"])
			var y: float = i * rh
			var got: bool = t >= at
			var first: bool = i == 0 or int(Stars.REWARDS[i - 1]["at"]) != at
			if got:
				draw_rect(Rect2(0, y + 2.0, w, rh - 4.0), GOT_TINT)
			elif at == next_at:
				draw_rect(Rect2(0, y + 2.0, w, rh - 4.0), NEXT_TINT)
				draw_rect(Rect2(0, y + 2.0, w, rh - 4.0), UI.OFF_BORDER, false, 2.0)
			# the star badge with its count (once per group of rewards that open together)
			var bc := Vector2(BADGE_R + 6.0, y + rh / 2.0)
			if first:
				draw_colored_polygon(Kit.star_points(bc, BADGE_R, BADGE_R * 0.5), STAR_COLOR if got else STAR_OFF)
				Kit.text(self, str(at), bc - Vector2(BADGE_R, LADDER_AT_FONT * 0.62), BADGE_R * 2.0,
						LADDER_AT_FONT, UI.TEXT_COLOR)
			else:
				draw_line(bc + Vector2(0, -rh / 2.0), bc + Vector2(0, -4.0), STAR_COLOR if got else STAR_OFF, 3.0)
			# what it is
			var x: float = BADGE_R * 2.0 + 18.0
			var kind: String = str(r["kind"])
			var tw: float = w - x - 96.0
			Kit.text(self, str(KIND_TITLE.get(kind, kind.to_upper())), Vector2(x, y + 4.0), tw, KIND_FONT,
					DIM_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
			Kit.text(self, _name(r), Vector2(x, y + 22.0), tw, LADDER_NAME_FONT,
					UI.TEXT_COLOR if got or at == next_at else DIM_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
			# GOT / N TO GO / a lock
			var sx: float = w - 92.0
			if got:
				Kit.text(self, "GOT", Vector2(sx, y + (rh - LADDER_NAME_FONT) / 2.0 - 4.0), 88.0, LADDER_NAME_FONT,
						STAR_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
			elif at == next_at:
				Kit.text(self, "%d TO GO" % (at - t), Vector2(sx - 20.0, y + (rh - KIND_FONT - 2) / 2.0 - 4.0), 108.0,
						KIND_FONT + 2, UI.TEXT_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
			else:
				Kit.padlock(self, Vector2(w - 30.0, y + rh / 2.0 + 4.0), 16.0, STAR_OFF)

	func _name(r: Dictionary) -> String:
		var kind: String = str(r["kind"])
		var id: String = str(r["id"])
		match kind:
			"slot":
				return "EXTRA PLAYER " + id.trim_prefix("slot_")
			"legend":
				return "LEGEND"
		return Cosmetics.item_name(id)


# ---------------- a pick tile (drawn; the Button under it takes the tap) ----------------

class TileArt extends Control:
	var kind := ""
	var id := ""
	var state := "open"      # open / locked / missing (set by _refresh())
	var worn := false
	var _card: Dictionary = {}
	var _tex: Texture2D = null

	func setup(k: String, item: String) -> void:
		kind = k
		id = item
		var n: int = int((Cosmetics.ITEMS.get(id, {}) as Dictionary).get("n", 0))
		match kind:
			"jersey":
				var sheet: String = JERSEY_SHEET + ("_j%d" % n if n > 0 else "")
				_card = Sheets.card_first(Sheets.with_base(sheet))
				_tex = _card.get("texture", null)
			"ball":
				_tex = _load(_file(DEFAULT_BALL))
			"van":
				_tex = _load(_file(DEFAULT_VAN))

	func _file(default_path: String) -> String:
		if id == "":
			return default_path
		var files: Array = (Cosmetics.ITEMS[id] as Dictionary)["files"]
		return str(files[0]) if files.size() > 0 else default_path

	func _load(path: String) -> Texture2D:
		return load(path) as Texture2D if ResourceLoader.exists(path) else null

	func _draw() -> void:
		var pad: float = TILE_PAD
		var art := Rect2(pad, pad, size.x - pad * 2.0, size.y - pad * 2.0 - TILE_NAME_H)
		var tint: Color = Color.WHITE if state == "open" else LOCKED_TINT
		var c: Vector2 = art.get_center()
		if _tex != null:
			match kind:
				"jersey":
					var fr: Vector2 = _tex.get_size()
					var src := Rect2(Vector2.ZERO, fr)
					if fr == Vector2(64, 96):
						src = CARD_CROP
					var k: float = minf(art.size.x / src.size.x, art.size.y / src.size.y)
					var dst := Rect2(c - src.size * k / 2.0, src.size * k)
					draw_texture_rect_region(_tex, dst, src, tint)
				"ball":
					var s: float = BALL_FRAME * BALL_SCALE
					draw_set_transform(c + Vector2(0, s * 0.56), 0.0, Vector2(1.0, 0.3))
					draw_circle(Vector2.ZERO, s * 0.34, BALL_SHADOW)
					draw_set_transform(Vector2.ZERO)
					draw_texture_rect_region(_tex, Rect2(c - Vector2(s, s) / 2.0, Vector2(s, s)),
							Rect2(0, 0, BALL_FRAME, BALL_FRAME), tint)
				"van":
					var fr: Vector2 = _tex.get_size() / 2.0   # frame 0, facing right
					var vs: Vector2 = fr * VAN_SCALE
					draw_texture_rect_region(_tex, Rect2((c - vs / 2.0).round(), vs), Rect2(Vector2.ZERO, fr), tint)
		else:
			draw_rect(Rect2(c - Vector2(30, 30), Vector2(60, 60)), STAR_OFF, false, 3.0)
		var nm: String = Cosmetics.item_name(id) if id != "" else DEFAULT_NAME
		var ny: float = size.y - pad - TILE_NAME_H + 2.0
		Kit.text(self, nm, Vector2(pad, ny), size.x - pad * 2.0, NAME_FONT,
				UI.LIT_COLOR if worn else (UI.TEXT_COLOR if state == "open" else DIM_TEXT))
		if worn:
			_badge("ON", UI.LIT_COLOR, UI.LIT_TEXT)
		elif state == "locked":
			# the lock and the stars it needs, over the dark preview
			Kit.padlock(self, c + Vector2(0, -8.0), 26.0, UI.TEXT_COLOR)
			var need: int = Kit.stars_needed(id)
			var sc := Vector2(c.x - 26.0, c.y + 34.0)
			draw_colored_polygon(Kit.star_points(sc, 13.0, 6.0), STAR_COLOR)
			Kit.text(self, str(need), Vector2(sc.x + 14.0, sc.y - 14.0), 60.0, 24, UI.TEXT_COLOR,
					HORIZONTAL_ALIGNMENT_LEFT)
		elif state == "missing":
			Kit.text(self, "SOON", Vector2(pad, c.y - 14.0), size.x - pad * 2.0, 24, UI.TEXT_COLOR)

	func _badge(t: String, fill: Color, col: Color) -> void:
		var r := Rect2(size.x - 62.0, 6.0, 54.0, 28.0)
		draw_rect(r, fill)
		Kit.text(self, t, r.position + Vector2(0, 2.0), r.size.x, 20, col)


# ---------------- helpers (static; the drawing classes use them too) ----------------

class Kit:

	# the stars a reward id opens at (0 = not on the ladder)
	static func stars_needed(id: String) -> int:
		for r in Stars.REWARDS:
			if str(r["id"]) == id:
				return int(r["at"])
		return 0

	# the ladder row index of the next reward (-1 when everything is open)
	static func next_row() -> int:
		var t: int = Stars.total()
		for i in Stars.REWARDS.size():
			if int(Stars.REWARDS[i]["at"]) > t:
				return i
		return -1

	# what a ladder row gives, in words
	static func reward_text(r: Dictionary) -> String:
		var kind: String = str(r.get("kind", ""))
		var id: String = str(r.get("id", ""))
		match kind:
			"slot":
				return "ROSTER SLOT " + id.trim_prefix("slot_")
			"legend":
				return "LEGEND LEVEL"
			"court":
				return "COURT " + Cosmetics.item_name(id)
		return "%s %s" % [str(KIND_TITLE.get(kind, kind.to_upper())), Cosmetics.item_name(id)]

	# the 10 points of a five-pointed star around c
	static func star_points(c: Vector2, r_out: float, r_in: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 10:
			var ang: float = -PI / 2.0 + i * PI / 5.0
			var r: float = r_out if i % 2 == 0 else r_in
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		return pts

	static func text(ci: CanvasItem, t: String, pos: Vector2, width: float, fsize: int, color: Color,
			align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
		var font: Font = ThemeDB.fallback_font
		var base: Vector2 = pos + Vector2(0, fsize)
		ci.draw_string_outline(font, base, t, align, width, fsize, 6, UI.OUTLINE_COLOR)
		ci.draw_string(font, base, t, align, width, fsize, color)

	# a small padlock centred at c (h = body height)
	static func padlock(ci: CanvasItem, c: Vector2, h: float, color: Color) -> void:
		var w: float = h * 1.25
		ci.draw_arc(c + Vector2(0, -h * 0.45), w * 0.32, PI, TAU, 12, color, maxf(2.0, h * 0.18))
		ci.draw_rect(Rect2(c + Vector2(-w / 2.0, -h * 0.45), Vector2(w, h)), color)
		ci.draw_circle(c + Vector2(0, h * 0.05), h * 0.13, Color(0, 0, 0, 0.7))


