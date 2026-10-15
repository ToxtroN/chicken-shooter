extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/gif/"
var g
var f := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(OUT)
	g = load("res://scenes/game.tscn").instantiate(); add_child(g)
func _process(_d):
	f += 1
	if f == 5: g.start_round(); g.hint_t = 0; g.touch_mode = true; g.touch_active = true
	if f > 5:
		var k := float(f - 6) / 150.0
		if k > 1.0: get_tree().quit(); return
		var a := k * TAU
		g.aim = Vector2(640 + cos(a) * 520, 360 - sin(a * 2.0) * 120 + sin(a) * 160)
		if (f - 6) % 25 == 12: g.shoot(g.aim)
		if (f - 6) % 2 == 0:
			get_viewport().get_texture().get_image().save_png(OUT + "%03d.png" % ((f - 6) / 2))
