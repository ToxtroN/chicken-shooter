extends Node
var g
var f := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	g = load("res://scenes/game.tscn").instantiate(); add_child(g)
func _process(_d):
	f += 1
	if f == 5: g.start_round(); g.hint_t = 0; g.touch_mode = true; g.touch_active = true
	if f > 5: g.aim = Vector2([60.0, 640.0, 1220.0][(f / 30) % 3], 5)
	if f in [28, 58, 88]:
		var img := get_viewport().get_texture().get_image()
		var gap := 0
		for x in range(0, 1280, 4):
			pass
		img.save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/top_%d.png" % f)
	if f == 90: get_tree().quit()
