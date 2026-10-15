extends Node
const D := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/arm/"
var g
var f := 0
var a
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(D)
	g = load("res://scenes/game.tscn").instantiate(); add_child(g)
func _process(_d):
	f += 1
	if f == 5:
		g.start_round(); g.hint_t = 0; g.touch_mode = true; g.touch_active = true; g.aim = Vector2(640, 380); g.cam = 0
		g.targets.clear(); g._spawn_flyer(true); a = g.targets[0]; a.x = 300; a.y = 220
	if f > 5:
		g.spawn_t = 99
		if f in [20, 32, 44]: g.shoot(g.screen_pos(a)); print("hp ", a.get("hp"), " state ", a.state, " score ", g.score)
		if f % 2 == 0: get_viewport().get_texture().get_image().save_png(D + "%03d.png" % f)
	if f == 70: get_tree().quit()
