extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/sky_"
var g
var f := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	g = load("res://scenes/game.tscn").instantiate(); add_child(g)
func _process(_d):
	f += 1
	if f == 8: g.story_i = 1; g.story_t = 1.0
	if f == 14: get_viewport().get_texture().get_image().save_png(OUT + "intro.png"); g.game_state = "title"
	if f == 20: get_viewport().get_texture().get_image().save_png(OUT + "title.png"); g.start_round(); g.hint_t = 0; g._spawn_rooster(); g.cam = 0
	if f > 20 and f % 15 == 0 and g.game_state == "play":
		# бот стреляет по ближайшей цели
		for tg in g.targets:
			if tg.state == "fly":
				var p = g.screen_pos(tg)
				if p.x > 40 and p.x < 1240:
					g.shoot(p); break
		if g.ammo == 0: g.reload()
	if f == 196: g.aim = Vector2(820, 300); g.shoot(Vector2(10,10))
	if f == 198: g.aim = Vector2(820, 300); get_viewport().get_texture().get_image().save_png(OUT + "play.png")
	if f == 210: g.time_left = 0.05
	if f == 300: get_viewport().get_texture().get_image().save_png(OUT + "over.png"); print("score ", g.score, " hits ", g.hits, "/", g.shots); get_tree().quit()
