extends Node
const OUT := "/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/gun_"
var g
var f := 0
var aims := [Vector2(150, 120), Vector2(640, 150), Vector2(1150, 130), Vector2(120, 400), Vector2(640, 380), Vector2(1160, 380), Vector2(150, 600), Vector2(640, 620), Vector2(1150, 600)]
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	g = load("res://scenes/game.tscn").instantiate(); add_child(g)
func _process(_d):
	f += 1
	if f == 5: g.start_round(); g.hint_t = 0; g.touch_mode = true; g.touch_active = true
	if f > 5:
		var i := (f - 6) / 20
		if i >= aims.size(): get_tree().quit(); return
		g.aim = aims[i]
		if (f - 6) % 20 == 19:
			if i == 4: g.shoot(g.aim)
			get_viewport().get_texture().get_image().save_png(OUT + "%d.png" % i)
