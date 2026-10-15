extends Node2D
var f := 0
func _draw():
	draw_rect(Rect2(0,0,1280,720), Color(0.3,0.5,0.8))
	var t: Texture2D = load("res://assets/targets/brown/pose_scared.png")
	draw_texture(t, Vector2(50,50))
	var k := 0.3
	draw_set_transform(Vector2(600,300), 0.1, Vector2(k,k))
	draw_texture(t, -t.get_size()*0.5)
	draw_set_transform(Vector2(900,300), 0, Vector2(-k,k))
	draw_texture(t, -t.get_size()*0.5, Color.WHITE)
func _process(_d):
	f += 1
	if f == 5: get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/tex2.png"); get_tree().quit()
