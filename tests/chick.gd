extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/chick_"
var g
var f := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir() + "/cgif")
	g = load("res://scenes/game.tscn").instantiate(); add_child(g)
func _process(_d):
	f += 1
	if f == 5:
		g.start_round(); g.hint_t = 0; g.touch_mode = true; g.touch_active = true; g.aim = Vector2(640, 420); g._spawn_rooster(); g._spawn_rooster(); g.cam = g.pan
		for i in 6: g._spawn_chicken(i % 3, i == 5)
		for tg in g.targets: if tg.get("ground", false): tg.x = 200 + randf() * 900
	if f > 5 and f < 66 and f % 2 == 0:
		get_viewport().get_texture().get_image().save_png(OUT.get_base_dir() + "/cgif/%03d.png" % f)
	if f == 40: g.shoot(g.screen_pos(g.targets.filter(func(t): return t.get("ground", false))[0]))
	if f == 70: get_tree().quit()
