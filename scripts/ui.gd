class_name Ui
## Общие помощники отрисовки: текст с обводкой и загрузка кадров спрайтов.

const OUTLINE := Color(0.08, 0.06, 0.05)
static var _frames := {}


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, outline: int = 5) -> void:
	s = Loc.t(s)
	var f := ThemeDB.fallback_font
	var p := pos
	var w := -1.0
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		w = 1200.0
		p.x -= 600.0
	if outline > 0:
		ci.draw_string_outline(f, p, s, align, w, size, outline, OUTLINE)
	ci.draw_string(f, p, s, align, w, size, col)


## Кадры анимации: res://assets/targets/<вид>/<анимация>_<N>.png (пусто — рисуем заглушку).
static func frames(kind: String, anim: String) -> Array:
	var key := kind + "/" + anim
	if _frames.has(key):
		return _frames[key]
	var res: Array = []
	for i in 32:
		var path := "res://assets/targets/%s/%s_%d.png" % [kind, anim, i]
		if not ResourceLoader.exists(path):
			break
		res.append(load(path))
	_frames[key] = res
	return res
