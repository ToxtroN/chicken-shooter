extends Node
const D := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/mix/"
var g
var f := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(D)
	g = load("res://scenes/game.tscn").instantiate(); add_child(g)
func _process(_d):
	f += 1
	if f == 5:
		g.start_round(); g.hint_t = 0; g.touch_mode = true; g.touch_active = true; g.aim = Vector2(640, 380); g.cam = 0
		g.targets.clear()
		for i in 4: g._spawn_flyer()
		for tg in g.targets: tg.x = 150 + randf() * 1000
		for i in 4: g._spawn_hider()
		for tg in g.targets: if tg.kind == "hider": tg.life = 3.0
		for i in 3: g._spawn_chicken(i, false)
		for tg in g.targets: if tg.get("ground", false): tg.x = 300 + randf() * 800
	if f > 5:
		g.spawn_t = 99
		if f == 40:
			for tg in g.targets:
				if tg.kind == "flyer": g.shoot(g.screen_pos(tg)); break
		if f == 46:
			for tg in g.targets:
				if tg.kind == "hider" and g.hit_radius(tg) > 0: g.shoot(g.screen_pos(tg)); break
		if f % 2 == 0: get_viewport().get_texture().get_image().save_png(D + "%03d.png" % f)
	if f == 90: get_tree().quit()
