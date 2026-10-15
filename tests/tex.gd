extends Node
func _ready():
	var t: Texture2D = load("res://assets/targets/brown/pose_scared.png")
	var im := t.get_image(); print(im.get_size(), " ", im.get_format(), " ", im.get_pixel(120,150), " ", im.get_pixel(5,5))
	im.save_png("/tmp/claude-0/-home-claude/46c1a8cd-926e-5d35-b886-20647ed4312e/scratchpad/texchk.png")
	get_tree().quit()
