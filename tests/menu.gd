extends Node
const D := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/"
var g
var f := 0
func shot(n): get_viewport().get_texture().get_image().save_png(D + n + ".png")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Loc.set_lang("ru"); g = load("res://scenes/game.tscn").instantiate(); add_child(g)
func _process(_d):
	f += 1
	if f == 10: g.touch_mode = true; g._press(Vector2(600, 530))
	if f == 14: shot("m_hole")
	if f == 50: shot("m_vol"); print("page ", g.menu_page)
	if f == 52: g._press(Vector2(500, 330)); print("drag ", g.vol_drag, " music ", Sound.music)
	if f == 54: g.vol_drag = ""; g._press(Vector2(88, 88))
	if f == 90: print("page ", g.menu_page); g._press(Vector2(640, 410))
	if f == 130: print("state ", g.game_state); shot("c0")
	if f == 131: g._next_story()
	if f == 160: shot("c1"); g._next_story()
	if f == 175: shot("c2"); g._next_story()
	if f == 200: shot("c3"); g._next_story()
	if f == 210: print("state ", g.game_state, " music bus ", g.music.bus, " playing ", g.music.playing); get_tree().quit()
