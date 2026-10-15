extends Node
const D := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/gnr/"
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
		g.start_round(); g.hint_t = 0; g.touch_mode = true; g.touch_active = true; g.aim = Vector2(900, 300); g.cam = 0; g.score = 100
		g.targets.clear(); g.time_left = 60
		g._spawn_hider(true); a = g.targets[-1]
		print("gunner spot ", a.spot, " x ", a.x)
		g.awake = 30
	if f > 5:
		g.spawn_t = 99
		if f % 3 == 0: get_viewport().get_texture().get_image().save_png(D + "%03d.png" % f)
		if f == 200: print("awake ", g.awake, " score ", g.score); g.cam = 0 if a.x < 1000 else g.pan
		if f == 215: g.shoot(g.screen_pos(a)); print("shot -> ", a.kind, " awake ", g.awake)
	if f == 250: get_tree().quit()
