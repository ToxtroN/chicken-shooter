extends Node2D
## «Утро добрым не бывает» — тир в духе классических «охот».
## Мужик вернулся с ночной смены, а петух не даёт спать — берём ружьё и выходим во двор.
## Вид от первого лица: внизу ружьё, оно поворачивается за прицелом. 90 секунд, 8 патронов.
## ПК: прицел за мышью, ЛКМ — выстрел, ПКМ/пробел/R — перезарядка, мышь у края — осмотреться.
## Телефон: палец ведёт прицел (прицел чуть выше пальца), отпустил — выстрел; у края экрана — поворот.

const ROUND_TIME := 90.0
const MAG := 8
const RELOAD_TIME := 0.7
const VIEW_W := 1280.0
const PAN_DEFAULT := 1280.0      # на сколько можно сдвинуть ближний слой (без картинки фона)
const EDGE := 110.0              # зона у края экрана, где камера едет
const EDGE_SPEED := 1100.0
const SAVE := "user://save.cfg"

# Слои глубины: доля сдвига камеры, масштаб, очки, высота полёта (экран)
const LAYERS := [
	{"par": 0.35, "scale": 0.42, "points": 25, "y": [150.0, 300.0]},
	{"par": 0.65, "scale": 0.68, "points": 10, "y": [130.0, 360.0]},
	{"par": 1.00, "scale": 1.00, "points": 5, "y": [120.0, 420.0]},
]
# Укрытия на ближнем слое, из-за которых выглядывают цели (x в координатах слоя)
const PEEK_SPOTS := [260.0, 760.0, 1290.0, 1820.0, 2330.0]
# Крыши на среднем слое, где появляется петух (x в координатах слоя, y экрана)
const ROOF_SPOTS := [Vector2(330, 352), Vector2(1240, 352)]
const TOUCH_OFFSET := Vector2(0, -90)   # прицел над пальцем, чтобы его было видно
const STORY := [
	"6:00 утра. Ты только что вернулся с ночной смены...",
	"Лёг, закрыл глаза — и тут: «КУ-КА-РЕ-КУ!!!»",
	"Всё. Где моё ружьё?",
]

var game_state := "title"        # title (меню) | intro (история) | play | over
var story_seen := false
var menu_page := "main"            # main | volume
var vol_drag := ""                 # какой бегунок тянем: music | sfx
var menu_holes: Array = []         # следы выстрелов по дощечкам {p, t, rot, s}
var menu_pending := ""             # действие после выстрела по кнопке
var menu_delay := 0.0
var comic_i := 0
var comic_t := 0.0
var comic_tex: Array = []
var hole_tex: Texture2D
var menu_music: AudioStreamPlayer
var menu_bg: Texture2D
var ui_tex := {}
var story_i := 0
var story_t := 0.0
var touch_active := false
var overlay = null               # для platform_node: открыт ли экран поверх игры
var cam := 0.0                   # 0..pan
var pan := PAN_DEFAULT
# нарисованный фон двора: масштаб и сдвиг по вертикали
var bg_tex: Texture2D = null      # признак «есть нарисованный фон» (задний слой)
var bg_mid: Texture2D = null
var bg_front: Texture2D = null
const BG_SCALE := 1.0
const BG_Y := 0.0
# параллакс слоёв: задний двигается медленнее, передний — вместе с камерой
const PAR_BACK := 0.55
const PAR_MID := 1.0
# петух на крышах колодца и сарая (координаты исходной картинки фона)
const BG_ROOFS := [Vector2(2473, 183), Vector2(180, 272)]   # ноги петуха на коньке (координаты слоя mid)
# ружьё: 2 ряда по 13 кадров поворота на 180° (hi — ствол поднят, mid — пониже).
# Кадр 0 — до упора влево, 6 — прямо, 12 — вправо. Между кадрами и рядами — плавное смешивание.
const GUN_FRAMES := 13
const GUN_ROWS := ["hi", "mid"]
const GUN_MUZZLE := [
	[Vector2(92, 45), Vector2(106, 60), Vector2(118, 66), Vector2(138, 76), Vector2(150, 84), Vector2(161, 87),
		Vector2(152, 88), Vector2(143, 87), Vector2(156, 84), Vector2(174, 77), Vector2(189, 66), Vector2(197, 59), Vector2(203, 43)],
	[Vector2(110, 88), Vector2(106, 85), Vector2(104, 85), Vector2(113, 84), Vector2(121, 84), Vector2(132, 85),
		Vector2(150, 86), Vector2(169, 86), Vector2(175, 84), Vector2(183, 81), Vector2(188, 78), Vector2(185, 75), Vector2(181, 70)],
]
const GUN_CANVAS := Vector2(300, 240)
const GUN_SCALE := 1.55
var gun_u := 6.0                 # плавный индекс кадра по горизонтали
var gun_v := 0.5                 # 0 — ряд hi, 1 — ряд mid
var gun_x := 640.0
var score := 0
var best := 0
var time_left := ROUND_TIME
var ammo := MAG
var reload_t := 0.0
var shots := 0
var hits := 0
var targets: Array = []
var popups: Array = []
var feathers: Array = []
var spawn_t := 0.0
var t := 0.0
var flash := 0.0                 # вспышка выстрела
var pain := 0.0                  # попадание курицы-стрелка по игроку
# «Шкала сна»: растёт, когда куры убегают, кукарекают и стреляют. 100 — сон пропал, конец раунда.
var awake := 0.0
var awake_flash := 0.0
var sleep_lost := false
const GUNNER_SPOTS := [0, 4]      # бочка слева и забор справа (индексы HIDE_SPOTS)
var holes: Array = []            # следы дроби на «стекле» экрана
var recoil := 0.0
var aim := Vector2(640, 360)
var touch_mode := false
var touch_start := Vector2.ZERO
var touch_cam := 0.0
var touch_moved := false
var tick_sec := -1
var over_t := 0.0
var new_record := false
var hint_t := 0.0
var players: Dictionary = {}
var music: AudioStreamPlayer
var rng := RandomNumberGenerator.new()

const R_SOUND := Rect2(1210, 14, 56, 56)
const R_PAUSE := Rect2(1146, 14, 56, 56)
const R_AMMO := Rect2(930, 630, 340, 80)
const R_PLAY := Rect2(470, 365, 340, 99)
const R_VOL := Rect2(470, 475, 340, 108)
const R_EXIT := Rect2(470, 592, 340, 110)
const R_MBAR := Rect2(440, 300, 400, 60)
const R_SBAR := Rect2(440, 440, 400, 60)
const R_BACK := Rect2(40, 40, 96, 96)
const COMIC_TEXT_EN := ["After the night shift...", "Just went to bed...", "COCK-A-DOODLE-DOO!!!", "Oh, come ON!"]
const R_AGAIN := Rect2(400, 520, 230, 70)
const R_MENU := Rect2(650, 520, 230, 70)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	Sound.load_volume()
	for s in ["shot", "empty", "reload", "hit", "bonus", "gameover", "tick", "cluck_0", "cluck_1", "cluck_2", "clank"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/sfx/%s.wav" % s)
		p.max_polyphony = 4
		p.bus = "SFX"
		add_child(p)
		players[s] = p
	if ResourceLoader.exists("res://assets/music.mp3"):
		music = AudioStreamPlayer.new()
		var st: AudioStream = load("res://assets/music.mp3")
		if st is AudioStreamMP3:
			st.loop = true
		music.stream = st
		music.bus = "Music"
		add_child(music)
	if ResourceLoader.exists("res://assets/menu_music.mp3"):
		menu_music = AudioStreamPlayer.new()
		var st2: AudioStream = load("res://assets/menu_music.mp3")
		if st2 is AudioStreamMP3:
			st2.loop = true
		menu_music.stream = st2
		menu_music.bus = "Music"
		add_child(menu_music)
		menu_music.play()
	if ResourceLoader.exists("res://assets/ui/menu_bg.webp"):
		menu_bg = load("res://assets/ui/menu_bg.webp")
	if ResourceLoader.exists("res://assets/ui/bullet_hole.png"):
		hole_tex = load("res://assets/ui/bullet_hole.png")
	for i in 4:
		var cp := "res://assets/comic/panel_%d.webp" % i
		if ResourceLoader.exists(cp):
			comic_tex.append(load(cp))
	var cf := ConfigFile.new()
	if cf.load(SAVE) == OK:
		best = int(cf.get_value("score", "best", 0))
	if ResourceLoader.exists("res://assets/bg/back.webp"):
		bg_tex = load("res://assets/bg/back.webp")
		bg_mid = load("res://assets/bg/mid.png")
		bg_front = load("res://assets/bg/front.png")
		pan = maxf(0.0, bg_front.get_width() * BG_SCALE - VIEW_W)
	Yandex.game_ready()


func sfx(id: String) -> void:
	if players.has(id):
		players[id].play()


# ---------------------------------------------------------------- РАУНД
func start_round() -> void:
	game_state = "play"
	pain = 0.0
	holes.clear()
	awake = 0.0
	sleep_lost = false
	score = 0
	shots = 0
	hits = 0
	time_left = ROUND_TIME
	ammo = MAG
	reload_t = 0.0
	targets.clear()
	popups.clear()
	feathers.clear()
	cam = pan * 0.5
	spawn_t = 0.3
	tick_sec = -1
	hint_t = 4.0
	get_tree().paused = false
	for i in 5:
		_spawn()


func add_awake(v: float, why: String = "") -> void:
	if game_state != "play":
		return
	awake = clampf(awake + v, 0.0, 100.0)
	if v > 0.0:
		awake_flash = 1.0
		if why != "":
			popups.append({"p": Vector2(640, 128), "txt": why, "t": 0.0, "col": Color(0.75, 0.85, 1.0)})
	if awake >= 100.0:
		sleep_lost = true
		end_round()


func end_round() -> void:
	game_state = "over"
	over_t = 0.0
	sfx("gameover")
	new_record = score > best
	if new_record:
		best = score
		var cf := ConfigFile.new()
		cf.load(SAVE)
		cf.set_value("score", "best", best)
		cf.save(SAVE)


func _after_round(next_state: String) -> void:
	# между раундами — логическая пауза, здесь можно показать рекламу
	Yandex.show_fullscreen_ad(func():
		if next_state == "play":
			start_round()
		else:
			game_state = "title")


# ---------------------------------------------------------------- ЦЕЛИ
func _spawn() -> void:
	var r := rng.randf()
	if r < 0.14 and bg_tex == null:
		_spawn_peek()
	elif r < 0.20 and not _has_kind("rooster"):
		_spawn_rooster()
	elif r < 0.24 and not _has_kind("golden"):
		_spawn_bird(0, "golden")
	elif bg_tex != null and r < 0.31 and _count_kind_armor() < 2:
		_spawn_flyer(true)
	elif bg_tex != null and r < 0.46:
		_spawn_flyer()
	elif bg_tex != null and r < 0.56:
		_spawn_hider()
	elif bg_tex != null and r < 0.60 and time_left < ROUND_TIME - 6.0 and not _has_gunner():
		_spawn_hider(true)
	else:
		var layer := 0 if r < 0.45 else (1 if r < 0.75 else 2)
		_spawn_bird(layer, "bird")


func _has_kind(k: String) -> bool:
	for tg in targets:
		if tg.kind == k:
			return true
	return false


func _layer_w(layer: int) -> float:
	return VIEW_W + pan * float(LAYERS[layer].par)


# Дорожки бега кур по двору (экранная y лап, масштаб, очки): дальняя — мелкие и дорогие
const LANES := [
	{"y": 548.0, "scale": 0.34, "points": 25},
	{"y": 598.0, "scale": 0.5, "points": 10},
	{"y": 668.0, "scale": 0.72, "points": 5},
]
const BREEDS := ["white", "black", "spotted", "brown"]
const CHICKEN_H := 135.0     # высота курицы на ближней дорожке при scale=1


func _spawn_chicken(lane: int, golden: bool) -> void:
	var L: Dictionary = LANES[lane]
	var dir := 1.0 if rng.randf() < 0.5 else -1.0
	var w := VIEW_W + pan
	var sc: float = L.scale
	var spd := rng.randf_range(170.0, 280.0) * sc * (2.0 if golden else 1.0)
	targets.append({
		"kind": "golden" if golden else "bird", "breed": "white" if golden else BREEDS[rng.randi() % BREEDS.size()],
		"layer": 2, "lane": lane, "ground": true, "x": -100.0 if dir > 0 else w + 100.0,
		"y": float(L.y) + rng.randf_range(-8.0, 8.0), "vx": spd * dir, "phase": rng.randf() * TAU, "bob": 0.0,
		"scale": sc, "points": 100 if golden else int(L.points), "state": "fly", "vy": 0.0, "rot": 0.0,
		"age": rng.randf() * 3.0, "fps": rng.randf_range(11.0, 15.0),
	})


# Места, из-за которых выглядывают куры (x, верх предмета y, слой перед ними, высота курицы, очки)
const HIDE_SPOTS := [
	{"x": 570.0, "top": 494.0, "behind": "front", "h": 105.0, "pts": 15},
	{"x": 90.0, "top": 508.0, "behind": "front", "h": 105.0, "pts": 15},
	{"x": 1850.0, "top": 548.0, "behind": "front", "h": 95.0, "pts": 15},
	{"x": 2010.0, "top": 508.0, "behind": "front", "h": 105.0, "pts": 15},
	{"x": 2350.0, "top": 480.0, "behind": "front", "h": 105.0, "pts": 15},
	{"x": 655.0, "top": 452.0, "behind": "mid", "h": 62.0, "pts": 30},
	{"x": 980.0, "top": 466.0, "behind": "mid", "h": 58.0, "pts": 30},
	{"x": 1720.0, "top": 464.0, "behind": "mid", "h": 58.0, "pts": 30},
	{"x": 2130.0, "top": 392.0, "behind": "mid", "h": 62.0, "pts": 30},
]


## Летящая курица: пересекает небо, дальние мелкие (за деревьями) — дороже.
func _count_kind_armor() -> int:
	var n := 0
	for tg in targets:
		if tg.get("armor", false) and tg.kind == "flyer":
			n += 1
	return n


## armored — курица в доспехах: летит медленнее, сбивается только с 3 попаданий.
func _spawn_flyer(armored: bool = false) -> void:
	var dir := 1.0 if rng.randf() < 0.5 else -1.0
	var sc := rng.randf_range(0.28, 0.6)
	if armored:
		sc = rng.randf_range(0.5, 0.68)
	var far := sc < 0.42
	var breed: String = BREEDS[rng.randi() % BREEDS.size()]
	targets.append({
		"kind": "flyer", "breed": ("armor_" + breed) if armored else breed, "layer": 2, "far": far,
		"armor": armored, "hp": 3 if armored else 1, "hurt": 0.0,
		"x": -120.0 if dir > 0 else VIEW_W + pan + 120.0, "y": rng.randf_range(120.0, 360.0),
		"vx": rng.randf_range(190.0, 300.0) * dir * (0.7 + sc), "vy": rng.randf_range(-18.0, 18.0),
		"phase": rng.randf() * TAU, "bob": rng.randf_range(10.0, 24.0) * sc, "scale": sc,
		"points": 75 if armored else (30 if far else 20), "state": "fly", "rot": 0.0, "age": 0.0,
		"fps": rng.randf_range(12.0, 16.0),
	})
	if armored:
		var tg: Dictionary = targets[-1]
		tg.vx *= 0.6
		tg.fps *= 0.75


## Курица выглядывает из-за бочки, куста, колодца и т.п.
func _has_gunner() -> bool:
	for tg in targets:
		if tg.get("gunner", false) and tg.kind == "hider":
			return true
	return false


## gunner — курица с ружьём: высовывается, целится и стреляет в игрока, если её не сбить.
func _spawn_hider(gunner: bool = false) -> void:
	var free: Array = []
	for i in HIDE_SPOTS.size():
		if gunner and not GUNNER_SPOTS.has(i):
			continue
		var busy := false
		for tg in targets:
			if tg.kind == "hider" and tg.spot == i:
				busy = true
		if not busy:
			free.append(i)
	if free.is_empty():
		return
	var i: int = free[rng.randi() % free.size()]
	var sp: Dictionary = HIDE_SPOTS[i]
	targets.append({
		"kind": "hider", "spot": i, "behind": sp.behind, "layer": 2, "x": float(sp.x), "y": float(sp.top),
		"h": float(sp.h), "pose": ["scared", "scared", "angry"][rng.randi() % 3], "flip": rng.randf() < 0.5,
		"points": int(sp.pts), "state": "fly", "rot": 0.0, "age": 0.0, "vx": 0.0, "vy": 0.0,
		"life": rng.randf_range(1.6, 2.6), "scale": 1.0, "breed": "brown",
	})
	if gunner:
		var tg: Dictionary = targets[-1]
		var aim_t := clampf(1.9 - (ROUND_TIME - time_left) / ROUND_TIME * 0.6, 1.3, 1.9)
		tg.merge({"gunner": true, "gbreed": BREEDS[rng.randi() % BREEDS.size()], "fire_t": 0.3 + aim_t,
			"aim_t": aim_t, "fired": false, "life": 99999.0, "flip": false,
			"h": float(sp.h) * 1.45, "points": 50}, true)


func _hider_k(tg: Dictionary) -> float:
	var a: float = tg.age
	var life: float = tg.life
	return clampf(minf(a / 0.28, (life - a) / 0.28), 0.0, 1.0)


func _spawn_bird(layer: int, kind: String) -> void:
	if bg_tex != null and not Ui.frames("white", "run").is_empty():
		_spawn_chicken(2 - layer, kind == "golden")
		return
	var L: Dictionary = LAYERS[layer]
	var dir := 1.0 if rng.randf() < 0.5 else -1.0
	var w := _layer_w(layer)
	var spd := rng.randf_range(110.0, 190.0) * float(L.scale)
	if kind == "golden":
		spd *= 2.2
	targets.append({
		"kind": kind, "layer": layer, "x": -80.0 if dir > 0 else w + 80.0,
		"y": rng.randf_range(L.y[0], L.y[1]), "vx": spd * dir, "phase": rng.randf() * TAU,
		"bob": rng.randf_range(10.0, 30.0) * float(L.scale), "scale": float(L.scale),
		"points": 100 if kind == "golden" else int(L.points), "state": "fly", "vy": 0.0, "rot": 0.0, "age": 0.0,
	})


func _spawn_peek() -> void:
	var spot: float = PEEK_SPOTS[rng.randi() % PEEK_SPOTS.size()]
	for tg in targets:
		if tg.kind == "peek" and absf(tg.x - spot) < 1.0:
			return
	targets.append({"kind": "peek", "layer": 2, "x": spot, "y": 560.0, "vx": 0.0, "phase": 0.0, "bob": 0.0,
		"scale": 1.0, "points": 15, "state": "fly", "vy": 0.0, "rot": 0.0, "age": 0.0, "life": rng.randf_range(1.4, 2.2)})


## Петух — виновник побудки: на пару секунд встаёт на крышу и кукарекает. 50 очков.
func _spawn_rooster() -> void:
	var spot: Vector2 = ROOF_SPOTS[rng.randi() % ROOF_SPOTS.size()]
	var layer := 1
	if bg_tex != null:
		var roof: Vector2 = BG_ROOFS[rng.randi() % BG_ROOFS.size()]
		spot = roof * BG_SCALE
		layer = 2
	targets.append({"kind": "rooster", "layer": layer, "x": spot.x, "y": spot.y, "vx": 0.0, "phase": 0.0,
		"bob": 0.0, "scale": 0.8, "points": 50, "state": "fly", "vy": 0.0, "rot": 0.0, "age": 0.0,
		"life": rng.randf_range(2.2, 3.0)})


## Экранная позиция цели.
func screen_pos(tg: Dictionary) -> Vector2:
	var par: float = LAYERS[tg.layer].par
	var y: float = tg.y
	if tg.kind == "dead":
		return Vector2(tg.x - cam, tg.y)
	if tg.kind == "flyer":
		return Vector2(tg.x - cam, tg.y + sin(tg.age * 2.6 + tg.phase) * tg.bob)
	if tg.kind == "hider":
		# центр видимой части: голова над краем предмета
		var k := ease(_hider_k(tg), 0.5)
		return Vector2(tg.x - cam, tg.y + tg.h * 0.5 - k * tg.h * 0.72)
	if tg.kind == "rooster" and bg_tex != null:
		# петух стоит на крыше слоя mid: y — ноги, центр картинки выше
		return Vector2(tg.x - layer_off(PAR_MID), tg.y - 40.0)
	if tg.get("ground", false):
		var h: float = CHICKEN_H * tg.scale
		if tg.state == "fly":
			y += -absf(sin(tg.age * tg.fps * 0.5)) * 6.0 * tg.scale
		return Vector2(tg.x - cam, y - h * 0.45)
	if tg.kind == "bird" or tg.kind == "golden":
		if tg.state == "fly":
			y += sin(tg.age * 2.4 + tg.phase) * tg.bob
	elif tg.kind == "peek":
		y = _peek_y(tg)
	return Vector2(tg.x - cam * par, y)


func _peek_y(tg: Dictionary) -> float:
	if tg.state != "fly":
		return tg.y
	var a: float = tg.age
	var life: float = tg.life
	var k := minf(1.0, minf(a / 0.25, (life - a) / 0.25))
	return 600.0 - 95.0 * clampf(k, 0.0, 1.0)


func hit_radius(tg: Dictionary) -> float:
	match tg.kind:
		"rooster": return 40.0 * tg.scale
		"flyer": return 52.0 * tg.scale
		"hider": return tg.h * 0.42 if _hider_k(tg) > 0.45 else 0.0
		"bird", "golden":
			return (62.0 if tg.get("ground", false) else 34.0) * tg.scale
		"peek": return 40.0
		_: return 34.0 * tg.scale


func _update_targets(delta: float) -> void:
	for tg in targets:
		tg.age += delta
		if tg.has("hurt"):
			tg.hurt = maxf(0.0, tg.hurt - delta)
		match tg.state:
			"fly":
				if tg.get("gunner", false) and tg.age >= tg.fire_t:
					# стреляет снова и снова, пока её не собьют
					_chicken_fires(tg)
					tg.aim_t = maxf(1.2, tg.aim_t - 0.1)
					tg.last_fire = tg.fire_t
					tg.fire_t += 0.45 + tg.aim_t
				if tg.kind == "peek" or tg.kind == "rooster" or tg.kind == "hider":
					if tg.age >= tg.life:
						tg.state = "gone"
						if tg.kind == "rooster":
							add_awake(8.0, "КУ-КА-РЕ-КУ!")
						elif tg.kind == "hider":
							add_awake(2.0)
				else:
					tg.x += tg.vx * delta
					tg.y += tg.vy * delta
					var w := _layer_w(tg.layer)
					if tg.get("ground", false):
						w = VIEW_W + pan
					if tg.x < -150.0 or tg.x > w + 150.0 or tg.y < -120.0:
						tg.state = "gone"
						if tg.kind == "flyer" or tg.get("ground", false):
							add_awake(8.0 if tg.get("armor", false) else 5.0)
			"dead":
				tg.vy += 1100.0 * delta
				tg.y += tg.vy * delta
				tg.x += tg.vx * delta
				tg.rot += delta * tg.spin
				if tg.y > 820.0:
					tg.state = "gone"
			"fall":
				tg.vy += 900.0 * delta
				tg.y += tg.vy * delta
				tg.x += tg.vx * 0.3 * delta
				tg.rot += delta * 7.0 * signf(tg.vx + 0.01)
				if tg.y > 800.0:
					tg.state = "gone"
			"pop":
				if tg.age > 0.35:
					tg.state = "gone"
	targets = targets.filter(func(x): return x.state != "gone")


# ---------------------------------------------------------------- ЦИКЛ
func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 8.0)
	pain = maxf(0.0, pain - delta * 0.7)
	awake_flash = maxf(0.0, awake_flash - delta * 2.0)
	recoil = maxf(0.0, recoil - delta * 6.0)
	if not touch_mode:
		aim = get_global_mouse_position()
	if game_state == "over":
		over_t += delta
	if game_state == "intro":
		story_t += delta
		comic_t += delta
	for h in menu_holes:
		h.t += delta
	if menu_pending != "":
		menu_delay -= delta
		if menu_delay <= 0.0:
			var act := menu_pending
			menu_pending = ""
			_menu_action(act)
	_update_music()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if game_state == "play" and not get_tree().paused and not touch_mode \
		else Input.MOUSE_MODE_VISIBLE
	if game_state == "play" and not get_tree().paused:
		_play_tick(delta)
		_update_gun(delta)
	queue_redraw()


func _play_tick(delta: float) -> void:
	time_left -= delta
	hint_t = maxf(0.0, hint_t - delta)
	var sec := int(ceil(time_left))
	if sec <= 10 and sec != tick_sec and sec > 0:
		tick_sec = sec
		sfx("tick")
	if time_left <= 0.0:
		time_left = 0.0
		end_round()
		return
	# осмотр: прицел (мышь или палец) у края экрана
	if not touch_mode or touch_active:
		var mx := aim.x
		if mx < EDGE:
			cam -= EDGE_SPEED * delta * (1.0 - mx / EDGE)
		elif mx > VIEW_W - EDGE:
			cam += EDGE_SPEED * delta * (1.0 - (VIEW_W - mx) / EDGE)
	cam = clampf(cam, 0.0, pan)
	if reload_t > 0.0:
		reload_t -= delta
		if reload_t <= 0.0:
			ammo = MAG
	spawn_t -= delta
	var alive := 0
	for tg in targets:
		if tg.state == "fly":
			alive += 1
	if spawn_t <= 0.0 and alive < 9:
		_spawn()
		spawn_t = rng.randf_range(0.35, 0.9)
	_update_targets(delta)
	for p in popups:
		p.t += delta
	popups = popups.filter(func(p): return p.t < 1.0)
	for f in feathers:
		f.t += delta
		f.v.y += 260.0 * delta
		f.v *= 0.97
		f.p += f.v * delta
	feathers = feathers.filter(func(f): return f.t < 1.2)


# ---------------------------------------------------------------- ВЫСТРЕЛ
func shoot(p: Vector2) -> void:
	if reload_t > 0.0:
		return
	if ammo <= 0:
		sfx("empty")
		hint_t = 2.5
		return
	ammo -= 1
	shots += 1
	flash = 1.0
	recoil = 1.0
	sfx("shot")
	# ближние слои перекрывают дальние: проверяем от ближнего к дальнему
	var best_tg = null
	for layer in [2, 1, 0]:
		for tg in targets:
			if tg.layer != layer or tg.state != "fly":
				continue
			if screen_pos(tg).distance_to(p) <= hit_radius(tg):
				best_tg = tg
				break
		if best_tg != null:
			break
	if best_tg == null:
		return
	hits += 1
	if best_tg.get("hp", 1) <= 1:
		awake = maxf(0.0, awake - 2.0)
	if best_tg.get("hp", 1) > 1:
		# броня выдержала: искры, «ДЗЫНЬ», курицу отбрасывает
		best_tg.hp -= 1
		best_tg.hurt = 0.25
		best_tg.y += rng.randf_range(-14.0, 14.0)
		var hp_sp := screen_pos(best_tg)
		_burst(hp_sp, Color(0.85, 0.88, 0.95), 10)
		popups.append({"p": hp_sp + Vector2(0, -40), "txt": "ДЗЫНЬ!", "t": 0.0, "col": Color(0.8, 0.85, 1.0)})
		players["clank"].pitch_scale = rng.randf_range(0.9, 1.1)
		players["clank"].play()
		return
	score += int(best_tg.points)
	var sp := screen_pos(best_tg)
	popups.append({"p": sp + Vector2(0, -30), "txt": "+%d" % best_tg.points, "t": 0.0,
		"col": Color(1, 0.85, 0.2) if best_tg.points >= 50 else Color.WHITE})
	# кудахтанье сбитой курицы (одно из трёх), для бонусных целей — ещё и «дзынь»
	var cl: AudioStreamPlayer = players["cluck_%d" % (rng.randi() % 3)]
	cl.pitch_scale = rng.randf_range(0.9, 1.15)
	cl.play()
	if best_tg.points >= 50:
		sfx("bonus")
	if bg_tex != null and best_tg.kind != "rooster":
		# превращаем в падающую тушку: подлетает и кувыркается
		var sc: float = best_tg.get("scale", 1.0)
		var hh: float = CHICKEN_H * sc
		if best_tg.kind == "hider":
			hh = best_tg.h
			if best_tg.get("gunner", false):
				best_tg["dead_tex"] = "res://assets/targets/gunner/%s_3.png" % best_tg.gbreed
		elif best_tg.kind == "flyer":
			hh = 125.0 * sc
		var dvx: float = clampf(best_tg.get("vx", 0.0) * 0.35, -120.0, 120.0)
		if absf(dvx) < 20.0:
			dvx = rng.randf_range(-80.0, 80.0)
		best_tg.merge({"kind": "dead", "state": "dead", "x": sp.x + cam, "y": sp.y, "vy": -420.0, "vx": dvx,
			"h": hh, "spin": rng.randf_range(6.0, 10.0) * signf(dvx), "rot": 0.0, "age": 0.0,
			"flip": best_tg.get("vx", 1.0) < 0.0 if best_tg.has("vx") else false}, true)
		_burst(sp, Color(1, 0.95, 0.85), 12)
	else:
		best_tg.y = sp.y
		best_tg.state = "fall"
		best_tg.vy = -380.0 if best_tg.get("ground", false) else -120.0
		best_tg.age = 0.0
		_burst(sp, Color(1, 0.95, 0.85) if best_tg.kind != "golden" else Color(1, 0.85, 0.3), 10)
	if ammo == 0:
		hint_t = 2.5


func _burst(p: Vector2, col: Color, n: int) -> void:
	for i in n:
		feathers.append({"p": p, "v": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(60.0, 220.0),
			"t": 0.0, "col": col, "rot": rng.randf() * TAU})


func reload() -> void:
	if reload_t > 0.0 or ammo == MAG or game_state != "play":
		return
	reload_t = RELOAD_TIME
	sfx("reload")


# ---------------------------------------------------------------- ВВОД
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_R, KEY_ENTER:
				if game_state == "play":
					reload()
				elif game_state == "title":
					_start_from_menu()
				elif game_state == "intro":
					_next_story()
			KEY_P, KEY_ESCAPE:
				_toggle_pause()
			KEY_M:
				Sound.toggle_mute()
		return
	if event is InputEventMouseButton and not event.pressed:
		vol_drag = ""
	if event is InputEventMouseMotion and vol_drag != "":
		_set_vol_from(event.position.x)
		return
	if event is InputEventScreenDrag and vol_drag != "":
		_set_vol_from(event.position.x)
		return
	if event is InputEventScreenTouch and not event.pressed:
		vol_drag = ""
	if event is InputEventMouseButton and event.pressed:
		touch_mode = false
		if event.button_index == MOUSE_BUTTON_RIGHT:
			reload()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_press(event.position)
		return
	# касания: в бою палец ведёт прицел, отпустил — выстрел; кнопки срабатывают сразу
	if event is InputEventScreenTouch:
		touch_mode = true
		var p: Vector2 = event.position
		if event.pressed:
			if game_state == "play" and not get_tree().paused and not _on_button(p):
				touch_active = true
				aim = _touch_aim(p)
			else:
				_press(p)
		elif touch_active:
			touch_active = false
			aim = _touch_aim(p)
			if game_state == "play" and not get_tree().paused:
				shoot(aim)
	elif event is InputEventScreenDrag and touch_active:
		aim = _touch_aim(event.position)


func _touch_aim(p: Vector2) -> Vector2:
	return (p + TOUCH_OFFSET).clamp(Vector2(4, 4), Vector2(1276, 716))


func _on_button(p: Vector2) -> bool:
	return R_SOUND.has_point(p) or R_PAUSE.has_point(p) or R_AMMO.has_point(p)


func _press(p: Vector2) -> void:
	if R_SOUND.has_point(p) and game_state == "play":
		Sound.toggle_mute()
		return
	if Platform.ad_open:
		return
	match game_state:
		"intro":
			_next_story()
		"title":
			if menu_page == "volume":
				if R_BACK.grow(10).has_point(p):
					_menu_shoot(p, "back")
				elif R_MBAR.grow(14).has_point(p):
					vol_drag = "music"
					_set_vol_from(p.x)
				elif R_SBAR.grow(14).has_point(p):
					vol_drag = "sfx"
					_set_vol_from(p.x)
					sfx("shot")
			elif R_PLAY.has_point(p):
				_menu_shoot(p, "play")
			elif R_VOL.has_point(p):
				_menu_shoot(p, "volume")
			elif R_EXIT.has_point(p) and not Platform.on_web:
				_menu_shoot(p, "exit")
		"over":
			if over_t < 0.8:
				return
			if R_AGAIN.has_point(p):
				_after_round("play")
			elif R_MENU.has_point(p):
				_after_round("title")
		"play":
			if R_PAUSE.has_point(p):
				_toggle_pause()
			elif get_tree().paused:
				_toggle_pause()
			elif R_AMMO.has_point(p):
				reload()
			else:
				shoot(p)


## Меню и история — музыка меню; бой и итоги — игровая музыка.
func _update_music() -> void:
	var in_menu := game_state == "title" or game_state == "intro"
	for pair in [[menu_music, in_menu], [music, not in_menu]]:
		var pl: AudioStreamPlayer = pair[0]
		if pl == null:
			continue
		if pair[1] and not pl.playing:
			pl.volume_db = 0.0
			pl.play()
		elif not pair[1] and pl.playing:
			pl.stop()


func _ui(name: String) -> Texture2D:
	var key := name + ("_en" if Loc.is_en() else "")
	if not ui_tex.has(key):
		var path := "res://assets/ui/%s.png" % key
		if not ResourceLoader.exists(path):
			path = "res://assets/ui/%s.png" % name
		ui_tex[key] = load(path)
	return ui_tex[key]


## Выстрел по дощечке: звук, дыра от пули, через мгновение — само действие.
func _menu_shoot(p: Vector2, action: String) -> void:
	if menu_pending != "":
		return
	sfx("shot")
	recoil = 0.8
	menu_holes.append({"p": p, "t": 0.0, "rot": rng.randf() * TAU, "s": rng.randf_range(0.85, 1.1)})
	menu_pending = action
	menu_delay = 0.45


func _menu_action(act: String) -> void:
	menu_holes.clear()
	match act:
		"play": _start_from_menu()
		"volume": menu_page = "volume"
		"back": menu_page = "main"
		"exit": get_tree().quit()


func _start_from_menu() -> void:
	menu_page = "main"
	if comic_tex.is_empty():
		start_round()
		return
	comic_i = 0
	comic_t = 0.0
	game_state = "intro"


func _menu_bar_value(r: Rect2, x: float) -> float:
	return clampf((x - r.position.x - 24.0) / (r.size.x - 48.0), 0.0, 1.0)


func _set_vol_from(x: float) -> void:
	if vol_drag == "music":
		Sound.set_music(_menu_bar_value(R_MBAR, x))
	elif vol_drag == "sfx":
		Sound.set_sfx(_menu_bar_value(R_SBAR, x))


func _next_story() -> void:
	if not comic_tex.is_empty():
		if comic_t < 0.35:
			return
		comic_i += 1
		comic_t = 0.0
		if comic_i == 2:
			sfx("cluck_0")
		if comic_i >= comic_tex.size():
			start_round()
		return
	if story_t < 0.3:
		return
	story_i += 1
	story_t = 0.0
	if story_i >= STORY.size():
		start_round()


func _toggle_pause() -> void:
	if game_state != "play":
		return
	get_tree().paused = not get_tree().paused


## Вызывается из platform_node при потере фокуса.
func toggle_pause() -> void:
	_toggle_pause()


# ---------------------------------------------------------------- ОТРИСОВКА
func _draw() -> void:
	var shake := Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)) * recoil
	draw_set_transform(shake, 0, Vector2.ONE)
	if bg_tex != null:
		_draw_layer(bg_tex, PAR_BACK)
		for tg in targets:
			if tg.kind == "flyer" and tg.far:
				_draw_flyer(tg)
			elif tg.kind == "hider" and tg.behind == "mid":
				_draw_hider(tg)
		_draw_layer(bg_mid, PAR_MID)
		for tg in targets:
			if tg.kind == "rooster":
				_draw_targets_one(tg)
			elif tg.kind == "flyer" and not tg.far:
				_draw_flyer(tg)
		for lane in 3:
			for tg in targets:
				if tg.get("lane", -1) == lane and tg.kind != "dead":
					_draw_bird(tg, screen_pos(tg))
		for tg in targets:
			if tg.kind == "hider" and tg.behind == "front":
				_draw_hider(tg)
		_draw_layer(bg_front, 1.0)
		for tg in targets:
			if tg.kind == "dead":
				_draw_dead(tg)
	else:
		_draw_sky()
		_draw_layer_bg(0)
		_draw_targets(0)
		_draw_layer_bg(1)
		_draw_targets(1)
		_draw_layer_bg(2)
		_draw_targets(2)
		_draw_layer_front()
	for f in feathers:
		var a: float = 1.0 - f.t / 1.2
		var c: Color = f.col
		c.a = a
		var d: Vector2 = Vector2.from_angle(f.rot + f.t * 4.0) * 6.0
		draw_line(f.p - d, f.p + d, c, 3.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(1, 0.95, 0.8, flash * 0.12))
	if pain > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.9, 0.05, 0.0, pain * 0.35))
		for i in 6:
			draw_rect(Rect2(i * 10, i * 10, 1280 - i * 20, 720 - i * 20), Color(0.6, 0, 0, pain * 0.12), false, 10)
		for h in holes:
			var a := minf(1.0, pain * 1.5)
			draw_circle(h, 9, Color(0.05, 0.05, 0.05, a))
			for j in 6:
				var d := Vector2.from_angle(j * TAU / 6.0 + h.x) * (16.0 + fmod(h.y * 7.0 + j * 13.0, 14.0))
				draw_line(h, h + d, Color(1, 1, 1, a * 0.7), 2)
	for p in popups:
		var c: Color = p.col
		c.a = 1.0 - p.t
		Ui.text(self, p.p + Vector2(0, -40.0 * p.t), p.txt, 30, c)
	if game_state == "play" or game_state == "over":
		_draw_gun()
	match game_state:
		"intro": _draw_intro()
		"title": _draw_title()
		"play": _draw_hud()
		"over":
			_draw_hud()
			_draw_over()


func _draw_sky() -> void:
	var top := Color(0.36, 0.62, 0.9)
	var bot := Color(0.86, 0.93, 0.98)
	for i in 18:
		var k := float(i) / 18.0
		draw_rect(Rect2(0, i * 30, 1280, 31), top.lerp(bot, k))
	var sun := Vector2(980 - cam * 0.08, 140)
	draw_circle(sun, 70, Color(1, 0.96, 0.75, 0.35))
	draw_circle(sun, 48, Color(1, 0.93, 0.6))
	# облака
	for i in 6:
		var cx := fmod(i * 410.0 + t * 8.0 - cam * 0.15, 1700.0) - 200.0
		var cy := 80.0 + (i % 3) * 45.0
		for j in 4:
			draw_circle(Vector2(cx + j * 34, cy + sin(j * 1.7) * 8), 30 - absf(j - 1.5) * 5, Color(1, 1, 1, 0.85))


func _hill_poly(off: float, base_y: float, amp: float, freq: float, w: float, col: Color) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, 720))
	var x := 0.0
	while x <= 1280.0:
		var wx := x + off
		pts.append(Vector2(x, base_y - amp * (0.6 * sin(wx * freq) + 0.4 * sin(wx * freq * 2.3 + 1.0))))
		x += 16.0
	pts.append(Vector2(1280, 720))
	draw_colored_polygon(pts, col)


## Задники слоёв (заглушки, пока нет нарисованной панорамы).
func _draw_layer_bg(layer: int) -> void:
	var off := cam * float(LAYERS[layer].par)
	match layer:
		0:
			_hill_poly(off, 430.0, 50.0, 0.004, 0, Color(0.55, 0.68, 0.78))
		1:
			_hill_poly(off, 520.0, 45.0, 0.006, 0, Color(0.42, 0.62, 0.35))
			# сараи с крышами, на которые встаёт петух
			for rs in ROOF_SPOTS:
				_draw_barn(Vector2(rs.x - off, rs.y + 34.0))
			# деревья среднего плана
			for i in 14:
				var tx := i * 190.0 + 60.0
				var near_barn := false
				for rs in ROOF_SPOTS:
					if absf(tx - rs.x) < 150.0:
						near_barn = true
				if near_barn:
					continue
				var x := tx - off
				if x < -60 or x > 1340:
					continue
				var by := 520.0 - 45.0 * (0.6 * sin((x + off) * 0.006) + 0.4 * sin((x + off) * 0.0138 + 1.0))
				draw_rect(Rect2(x - 5, by - 30, 10, 34), Color(0.4, 0.28, 0.16))
				draw_circle(Vector2(x, by - 48), 30, Color(0.25, 0.48, 0.22))
				draw_circle(Vector2(x - 12, by - 58), 18, Color(0.32, 0.56, 0.26))
		2:
			_hill_poly(off, 610.0, 22.0, 0.005, 0, Color(0.48, 0.7, 0.3))


func _draw_barn(apex: Vector2) -> void:
	if apex.x < -200 or apex.x > 1480:
		return
	var red := Color(0.68, 0.18, 0.13)
	draw_rect(Rect2(apex.x - 82, apex.y + 40, 164, 120), Ui.OUTLINE)
	draw_rect(Rect2(apex.x - 79, apex.y + 43, 158, 117), red)
	for i in 6:
		draw_line(Vector2(apex.x - 79 + i * 31, apex.y + 43), Vector2(apex.x - 79 + i * 31, apex.y + 160), red.darkened(0.25), 2)
	draw_rect(Rect2(apex.x - 26, apex.y + 90, 52, 70), Color(0.35, 0.15, 0.08))
	draw_line(Vector2(apex.x - 26, apex.y + 90), Vector2(apex.x + 26, apex.y + 160), Color(0.95, 0.9, 0.8), 3)
	draw_line(Vector2(apex.x + 26, apex.y + 90), Vector2(apex.x - 26, apex.y + 160), Color(0.95, 0.9, 0.8), 3)
	draw_colored_polygon(PackedVector2Array([apex + Vector2(0, -6), apex + Vector2(104, 50), apex + Vector2(-104, 50)]), Ui.OUTLINE)
	draw_colored_polygon(PackedVector2Array([apex, apex + Vector2(96, 46), apex + Vector2(-96, 46)]), Color(0.4, 0.3, 0.25))


## Передний план: кусты-укрытия и забор (поверх целей ближнего слоя).
func _draw_layer_front() -> void:
	var off := cam
	for sx in PEEK_SPOTS:
		var x: float = sx - off
		if x < -120 or x > 1400:
			continue
		for j in 5:
			draw_circle(Vector2(x - 60 + j * 30, 612 - (j % 2) * 14), 40, Color(0.2, 0.45, 0.18))
		for j in 4:
			draw_circle(Vector2(x - 45 + j * 30, 600 - (j % 2) * 10), 26, Color(0.28, 0.55, 0.22))
	draw_rect(Rect2(0, 650, 1280, 70), Color(0.36, 0.56, 0.22))
	# забор
	var x0 := -fmod(off, 90.0)
	draw_rect(Rect2(0, 664, 1280, 8), Color(0.55, 0.38, 0.2))
	var x := x0
	while x < 1300.0:
		draw_rect(Rect2(x, 640, 12, 70), Color(0.6, 0.42, 0.22))
		x += 90.0


## Сдвиг слоя с параллаксом (слои центрированы, чтобы при среднем положении камеры совпадать).
func layer_off(par: float) -> float:
	return cam * par + pan * (1.0 - par) * 0.5


func _draw_layer(tex: Texture2D, par: float) -> void:
	if tex == null:
		return
	var w := tex.get_width() * BG_SCALE
	draw_texture_rect(tex, Rect2(-layer_off(par), 0, w, tex.get_height() * BG_SCALE), false)


func _sprite(tex: Texture2D, p: Vector2, h: float, rot: float, flip: bool, mod: Color = Color.WHITE) -> void:
	var k := h / tex.get_height()
	draw_set_transform(p, rot, Vector2(-k if flip else k, k))
	draw_texture(tex, -tex.get_size() * 0.5, mod)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_flyer(tg: Dictionary) -> void:
	var fr := Ui.frames(tg.breed, "fly")
	if fr.is_empty():
		return
	var tex: Texture2D = fr[int(tg.age * tg.fps) % fr.size()]
	var p := screen_pos(tg)
	var mod := Color(1.6, 1.6, 1.8) if tg.get("hurt", 0.0) > 0.0 else Color.WHITE
	_sprite(tex, p, 125.0 * tg.scale, sin(tg.get("hurt", 0.0) * 40.0) * 0.15, tg.vx < 0.0, mod)
	if tg.get("armor", false):
		# щитки прочности над курицей
		var n: int = tg.hp
		for i in 3:
			var c := p + Vector2((i - 1) * 16.0, -70.0 * tg.scale - 14.0)
			draw_circle(c, 6.5, Color(0.1, 0.1, 0.12))
			draw_circle(c, 5.0, Color(0.75, 0.8, 0.9) if i < n else Color(0.3, 0.3, 0.32))


var _poses := {}


## Текстуры поз держим в словаре: загруженная в _draw и сразу отпущенная текстура рисуется белым.
func _pose(name: String) -> Texture2D:
	if not _poses.has(name):
		_poses[name] = load("res://assets/targets/brown/pose_%s.png" % name)
	return _poses[name]


func _tex(path: String) -> Texture2D:
	if not _poses.has(path):
		_poses[path] = load(path)
	return _poses[path]


## Курица стреляет: вспышка, дробь по экрану, штраф −3 с и −30 очков.
func _chicken_fires(tg: Dictionary) -> void:
	players["shot"].pitch_scale = 1.35
	players["shot"].volume_db = -6.0
	players["shot"].play()
	get_tree().create_timer(0.6).timeout.connect(func():
		players["shot"].pitch_scale = 1.0
		players["shot"].volume_db = 0.0)
	pain = 1.0
	recoil = 1.2
	score = maxi(0, score - 30)
	var c := screen_pos(tg)
	popups.append({"p": Vector2(640, 300), "txt": "ОЙ! −30", "t": 0.0, "col": Color(1, 0.35, 0.3)})
	add_awake(12.0)
	holes.clear()
	for i in 7:
		holes.append(Vector2(640, 380) + Vector2(rng.randf_range(-260, 260), rng.randf_range(-170, 170)))
	_burst(c + Vector2(0, -10), Color(1, 0.8, 0.3), 8)


func _draw_hider(tg: Dictionary) -> void:
	if tg.get("gunner", false):
		_draw_gunner(tg)
		return
	var tex: Texture2D = _pose(tg.pose)
	var k := ease(_hider_k(tg), 0.5)
	# низ спрайта уходит за предмет; видна только верхняя часть
	var center := Vector2(tg.x - cam, tg.y + tg.h * 0.5 + 6.0 - k * tg.h * 0.72)
	var wob := sin(tg.age * 9.0) * 0.06 * k
	_sprite(tex, center, tg.h, wob, tg.flip)


func _draw_gunner(tg: Dictionary) -> void:
	var k := ease(_hider_k(tg), 0.5)
	var a: float = tg.age
	var lf: float = tg.get("last_fire", -10.0)
	var frame := 0
	if a > lf and a < lf + 0.4:
		frame = 2
	elif a > 0.3 and int(a * 2.5) % 3 == 2:
		frame = 1
	var tex := _tex("res://assets/targets/gunner/%s_%d.png" % [tg.gbreed, frame])
	var center := Vector2(tg.x - cam, tg.y + tg.h * 0.5 + 6.0 - k * tg.h * 0.72)
	var kick := 0.0
	if a > lf and a < lf + 0.15:
		kick = -0.12
	_sprite(tex, center, tg.h, kick, false)
	# вспышка выстрела из ствола
	if a > lf and a < lf + 0.12:
		var mz := center + Vector2(tg.h * 0.25, -tg.h * 0.08)
		draw_circle(mz, tg.h * 0.35, Color(1, 0.75, 0.2, 0.8))
		draw_circle(mz, tg.h * 0.2, Color(1, 0.97, 0.7))
	# предупреждение: красный круг-таймер и «!»
	if a > 0.3 and a < tg.fire_t and a > lf + 0.4:
		var left: float = clampf((tg.fire_t - a) / tg.aim_t, 0.0, 1.0)
		var r: float = tg.h * 0.6
		var blink := 0.6 + 0.4 * sin(a * (8.0 + (1.0 - left) * 20.0))
		draw_arc(center, r, -PI / 2, -PI / 2 + TAU * left, 40, Color(1, 0.15, 0.1, blink), 4)
		var ic := center + Vector2(0, -tg.h * 0.62 - 14)
		draw_circle(ic, 13, Color(0.1, 0.05, 0.05))
		draw_circle(ic, 11, Color(1, 0.2, 0.15, blink))
		Ui.text(self, ic + Vector2(0, 7), "!", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 0)


func _draw_dead(tg: Dictionary) -> void:
	var tex: Texture2D
	if tg.has("dead_tex"):
		tex = _tex(tg.dead_tex)
	elif tg.breed == "brown":
		tex = _pose("tumble")
	else:
		var fr := Ui.frames(tg.breed, "fly")
		tex = fr[3] if not fr.is_empty() else null
	if tex == null:
		return
	_sprite(tex, screen_pos(tg), tg.h, tg.rot, tg.flip)


func _draw_targets_one(tg: Dictionary) -> void:
	var p := screen_pos(tg)
	match tg.kind:
		"bird", "golden": _draw_bird(tg, p)
		"peek": _draw_peek(tg, p)
		"rooster": _draw_rooster(tg, p)


func _draw_targets(layer: int) -> void:
	for tg in targets:
		if tg.layer != layer:
			continue
		var p := screen_pos(tg)
		if p.x < -150 or p.x > 1430:
			continue
		match tg.kind:
			"bird", "golden": _draw_bird(tg, p)
			"peek": _draw_peek(tg, p)
			"rooster": _draw_rooster(tg, p)


func _draw_bird(tg: Dictionary, p: Vector2) -> void:
	var s: float = tg.scale
	var flip: bool = tg.vx < 0.0
	if tg.get("ground", false):
		var run := Ui.frames(tg.breed, "run")
		var tex2: Texture2D = run[int(tg.age * tg.fps) % run.size()] if tg.state == "fly" else run[2]
		var k2 := CHICKEN_H * s / tex2.get_height()
		var mod := Color(1.0, 0.85, 0.3) if tg.kind == "golden" else Color.WHITE
		if tg.kind == "golden":
			draw_circle(p, 70.0 * s, Color(1, 0.9, 0.3, 0.25 + 0.15 * sin(t * 8.0)))
		# тень на земле
		if tg.state == "fly":
			var gy: float = tg.y - p.y + 2.0
			_ellipse_at(p + Vector2(0, gy), 46.0 * s, 10.0 * s, Color(0, 0, 0, 0.22))
		draw_set_transform(p, tg.rot, Vector2(-k2 if flip else k2, k2))
		draw_texture(tex2, -tex2.get_size() * 0.5, mod)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	var fr := Ui.frames(tg.kind, "fly" if tg.state == "fly" else "hit")
	if not fr.is_empty():
		var tex: Texture2D = fr[int(tg.age * 10.0) % fr.size()]
		var h := 90.0 * s
		var k := h / tex.get_height()
		draw_set_transform(p, tg.rot, Vector2(-k if flip else k, k))
		draw_texture(tex, -tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	# заглушка: курица (белая, золотая — редкая)
	var golden: bool = tg.kind == "golden"
	var body := Color(1, 0.82, 0.2) if golden else Color(0.97, 0.95, 0.9)
	var dir := -1.0 if flip else 1.0
	draw_set_transform(p, tg.rot, Vector2(dir * s, s))
	var flap := sin(tg.age * 22.0) * 20.0 if tg.state == "fly" else 26.0
	# крыло сзади
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -4), Vector2(10, -6), Vector2(-8, -30 - flap)]), body.darkened(0.18))
	# тело
	Art2.ellipse(self, Vector2(0, 0), 27, 21, Ui.OUTLINE)
	Art2.ellipse(self, Vector2(0, 0), 25, 19, body)
	# хвост
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -6), Vector2(-38, -20), Vector2(-34, 4)]), body.darkened(0.1))
	# голова, гребешок, бородка, клюв
	draw_circle(Vector2(22, -16), 12, Ui.OUTLINE)
	draw_circle(Vector2(22, -16), 10.5, body)
	for i in 3:
		draw_circle(Vector2(16 + i * 5, -28 + absf(i - 1) * 2), 4.5, Color(0.9, 0.15, 0.12))
	draw_circle(Vector2(30, -8), 3.5, Color(0.9, 0.15, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(31, -18), Vector2(42, -14), Vector2(31, -11)]), Color(1, 0.65, 0.1))
	if tg.state == "fly":
		draw_circle(Vector2(25, -18), 3.2, Color.WHITE)
		draw_circle(Vector2(26, -18), 1.8, Color.BLACK)
	else:
		draw_line(Vector2(22, -21), Vector2(28, -15), Color.BLACK, 2)
		draw_line(Vector2(28, -21), Vector2(22, -15), Color.BLACK, 2)
	# крыло спереди и лапы
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(14, -2), Vector2(-2, 22 + flap * 0.4)]), body.lightened(0.05))
	draw_line(Vector2(-4, 18), Vector2(-8, 30), Color(1, 0.6, 0.1), 3)
	draw_line(Vector2(6, 18), Vector2(4, 30), Color(1, 0.6, 0.1), 3)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_peek(tg: Dictionary, p: Vector2) -> void:
	var fr := Ui.frames("peek", "idle" if tg.state == "fly" else "hit")
	if not fr.is_empty():
		var tex: Texture2D = fr[int(tg.age * 8.0) % fr.size()]
		var k := 110.0 / tex.get_height()
		draw_set_transform(p, tg.rot, Vector2(k, k))
		draw_texture(tex, -tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	draw_set_transform(p, tg.rot, Vector2.ONE)
	draw_circle(Vector2.ZERO, 34, Ui.OUTLINE)
	draw_circle(Vector2.ZERO, 32, Color(0.75, 0.55, 0.35))
	draw_circle(Vector2(-22, -26), 12, Color(0.75, 0.55, 0.35))
	draw_circle(Vector2(22, -26), 12, Color(0.75, 0.55, 0.35))
	draw_circle(Vector2(-11, -4), 6, Color.WHITE)
	draw_circle(Vector2(11, -4), 6, Color.WHITE)
	draw_circle(Vector2(-10, -3), 3, Color.BLACK)
	draw_circle(Vector2(12, -3), 3, Color.BLACK)
	draw_circle(Vector2(0, 10), 6, Color(0.3, 0.15, 0.1))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_rooster(tg: Dictionary, p: Vector2) -> void:
	var s: float = tg.scale
	var fr := Ui.frames("rooster", "idle")
	if not fr.is_empty():
		var tex: Texture2D = fr[int(tg.age * 8.0) % fr.size()]
		var kk := BG_SCALE if bg_tex != null else 110.0 * s / tex.get_height()
		draw_set_transform(p, tg.rot, Vector2(kk, kk))
		draw_texture(tex, -tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_set_transform(p, tg.rot, Vector2(s, s))
		var crow: float = sin(tg.age * 3.0) if tg.state == "fly" else 0.0
		# хвост
		for i in 4:
			var c: Color = [Color(0.1, 0.35, 0.25), Color(0.15, 0.2, 0.45), Color(0.1, 0.4, 0.3), Color(0.2, 0.15, 0.4)][i]
			draw_colored_polygon(PackedVector2Array([Vector2(-16, -2), Vector2(-46 + i * 3, -44 + i * 12), Vector2(-28 + i * 2, -30 + i * 12)]), c)
		Art2.ellipse(self, Vector2(0, 4), 26, 22, Ui.OUTLINE)
		Art2.ellipse(self, Vector2(0, 4), 24, 20, Color(0.75, 0.3, 0.12))
		draw_circle(Vector2(18, -22), 13, Ui.OUTLINE)
		draw_circle(Vector2(18, -22), 11.5, Color(0.85, 0.4, 0.15))
		for i in 4:
			draw_circle(Vector2(10 + i * 5, -36 + absf(i - 1.5) * 2), 5.5, Color(0.95, 0.12, 0.1))
		draw_circle(Vector2(26, -12), 4.5, Color(0.95, 0.12, 0.1))
		var open := maxf(0.0, crow) * 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(28, -24), Vector2(40, -22 - open), Vector2(29, -20)]), Color(1, 0.7, 0.1))
		draw_colored_polygon(PackedVector2Array([Vector2(28, -19), Vector2(39, -16 + open), Vector2(29, -16)]), Color(1, 0.6, 0.1))
		draw_circle(Vector2(21, -25), 3, Color.WHITE)
		draw_circle(Vector2(22, -25), 1.6, Color.BLACK)
		draw_line(Vector2(-4, 22), Vector2(-6, 34), Color(1, 0.6, 0.1), 3)
		draw_line(Vector2(8, 22), Vector2(8, 34), Color(1, 0.6, 0.1), 3)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if tg.state == "fly" and sin(tg.age * 3.0) > 0.2:
		Ui.text(self, p + Vector2(0, -60 * s), "КУ-КА-РЕ-КУ!", 22, Color(1, 0.95, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 5)


## Двустволка снизу справа (вид от первого лица): основание едет за прицелом,
## ствол смотрит на прицел и сужается к концу (перспектива).
func _update_gun(delta: float) -> void:
	var u := clampf((aim.x - 640.0) / 600.0, -1.0, 1.0)
	var target_u := (u + 1.0) * 0.5 * (GUN_FRAMES - 1)
	var target_v := clampf((aim.y - 170.0) / 380.0, 0.0, 1.0)
	gun_u = lerpf(gun_u, target_u, minf(1.0, delta * 14.0))
	gun_v = lerpf(gun_v, target_v, minf(1.0, delta * 10.0))
	gun_x = lerpf(gun_x, lerpf(640.0, aim.x, 0.4), minf(1.0, delta * 12.0))


func _gun_origin() -> Vector2:
	# низ кадра (руки) всегда ниже края экрана: ружьё может только опускаться, но не отрываться вверх
	var bob := maxf(0.0, (aim.y - 360.0) * 0.06)
	return Vector2(gun_x, 728.0 + bob + recoil * 26.0)


func _draw_gun_frame(row: int, idx: int, alpha: float) -> void:
	var fr := Ui.frames("gun", GUN_ROWS[row])
	if idx < 0 or idx >= fr.size() or alpha <= 0.01:
		return
	var tex: Texture2D = fr[idx]
	var o := _gun_origin()
	var size := GUN_CANVAS * GUN_SCALE
	draw_texture_rect(tex, Rect2(o.x - size.x * 0.5, o.y - size.y, size.x, size.y), false, Color(1, 1, 1, alpha))


func _gun_muzzle() -> Vector2:
	var col := clampi(int(round(gun_u)), 0, GUN_FRAMES - 1)
	var m: Vector2 = GUN_MUZZLE[0 if gun_v < 0.5 else 1][col]
	return _gun_origin() + (m - Vector2(GUN_CANVAS.x * 0.5, GUN_CANVAS.y)) * GUN_SCALE


func _draw_gun() -> void:
	if not Ui.frames("gun", "hi").is_empty():
		# только один кадр — ближайший к плавному повороту (без полупрозрачных «призраков»)
		var col := clampi(int(round(gun_u)), 0, GUN_FRAMES - 1)
		var row := 0 if gun_v < 0.5 else 1
		_draw_gun_frame(row, col, 1.0)
		if flash > 0.3:
			var tip := _gun_muzzle()
			var dirv := (aim - tip).normalized()
			var k2 := flash
			draw_circle(tip + dirv * 26.0 * k2, 34 * k2, Color(1, 0.7, 0.2, 0.7))
			draw_circle(tip + dirv * 16.0 * k2, 20 * k2, Color(1, 0.95, 0.65, 0.95))
			for n in 7:
				var a2 := dirv.angle() + (n - 3) * 0.3
				draw_line(tip, tip + Vector2.from_angle(a2) * 70.0 * k2, Color(1, 0.85, 0.3, 0.8), 4)
		return
	var fr := Ui.frames("gun", "idle")
	var base := Vector2(lerpf(820.0, aim.x + 230.0, 0.6), 830.0)
	var to := aim - base
	var ang := to.angle()
	var length := clampf(to.length() - 130.0, 260.0, 560.0)
	var back := recoil * 40.0
	var origin := base - Vector2.from_angle(ang) * back
	if not fr.is_empty():
		# готовый спрайт ружья: ствол вправо, точка вращения — левый нижний угол картинки
		var tex: Texture2D = fr[0]
		var k := (length + 220.0) / tex.get_width()
		draw_set_transform(origin, ang, Vector2(k, k))
		draw_texture(tex, Vector2(-220.0 / k, -tex.get_height() * 0.5))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_set_transform(origin, ang, Vector2.ONE)
		var wood := Color(0.5, 0.28, 0.12)
		var wood_l := Color(0.66, 0.4, 0.18)
		var metal := Color(0.2, 0.21, 0.24)
		var metal_l := Color(0.45, 0.47, 0.52)
		var taper := func(x: float) -> float: return lerpf(1.0, 0.5, clampf(x / length, 0.0, 1.0))
		# приклад
		_quad(Vector2(-240, -70), Vector2(20, -42), Vector2(20, 46), Vector2(-240, 90), wood, 3.0)
		_quad(Vector2(-236, -66), Vector2(18, -39), Vector2(18, -18), Vector2(-236, -30), wood_l, 0.0)
		# колодка
		_quad(Vector2(10, -44), Vector2(140, -38), Vector2(140, 40), Vector2(10, 46), metal, 3.0)
		_quad(Vector2(12, -41), Vector2(138, -35), Vector2(138, -20), Vector2(12, -24), metal_l, 0.0)
		# два ствола
		for side in [-1.0, 1.0]:
			var a: float = taper.call(130.0)
			var b: float = taper.call(length)
			var y0a: float = side * 19.0 * a
			var y0b: float = side * 19.0 * b
			var ha := 17.0 * a
			var hb := 17.0 * b
			_quad(Vector2(130, y0a - ha), Vector2(length, y0b - hb), Vector2(length, y0b + hb), Vector2(130, y0a + ha), metal, 3.0)
			_quad(Vector2(130, y0a - ha), Vector2(length, y0b - hb), Vector2(length, y0b - hb * 0.4), Vector2(130, y0a - ha * 0.4), metal_l, 0.0)
			Art2.ellipse(self, Vector2(length, y0b), 5.0, hb * 0.75, Color(0.03, 0.03, 0.04))
		# цевьё
		var fa: float = taper.call(170.0)
		var fb: float = taper.call(280.0)
		_quad(Vector2(170, -44 * fa), Vector2(280, -44 * fb), Vector2(280, 44 * fb), Vector2(170, 44 * fa), wood, 3.0)
		_quad(Vector2(172, -41 * fa), Vector2(278, -41 * fb), Vector2(278, -18 * fb), Vector2(172, -18 * fa), wood_l, 0.0)
		# мушка
		var tb: float = taper.call(length)
		draw_rect(Rect2(length - 16, -42 * tb - 6, 9, 7), metal_l)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# вспышка выстрела у дульного среза
	if flash > 0.3:
		var k2 := flash
		var tip := origin + Vector2.from_angle(ang) * (length + 8.0)
		var dirv := Vector2.from_angle(ang)
		draw_circle(tip + dirv * 34.0 * k2, 40 * k2, Color(1, 0.7, 0.2, 0.7))
		draw_circle(tip + dirv * 22.0 * k2, 24 * k2, Color(1, 0.95, 0.65, 0.95))
		for n in 7:
			var a2 := ang + (n - 3) * 0.3
			draw_line(tip, tip + Vector2.from_angle(a2) * 80.0 * k2, Color(1, 0.85, 0.3, 0.8), 4)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color, outline: float) -> void:
	var pts := PackedVector2Array([a, b, c, d])
	if outline > 0.0:
		var o := (a + b + c + d) * 0.25
		var big := PackedVector2Array()
		for q in pts:
			big.append(q + (q - o).normalized() * outline)
		draw_colored_polygon(big, Ui.OUTLINE)
	draw_colored_polygon(pts, col)


func _draw_intro() -> void:
	if comic_tex.is_empty():
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.04, 0.04, 0.08))
		return
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.06, 0.05, 0.05))
	var i := clampi(comic_i, 0, comic_tex.size() - 1)
	var tex: Texture2D = comic_tex[i]
	var k: float = ease(clampf(comic_t / 0.35, 0.0, 1.0), 0.4)
	# кадр на весь экран по высоте; медленный «наезд камеры», третий кадр трясётся
	var h := 700.0
	var w := h * tex.get_width() / tex.get_height()
	var zoom := 1.0 + comic_t * 0.015
	var shake := Vector2.ZERO
	if i == 2 and comic_t < 1.2:
		shake = Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)) * (1.2 - comic_t)
	var sz := Vector2(w, h) * zoom * (0.92 + 0.08 * k)
	var c := Vector2(640, 360) + shake
	draw_rect(Rect2(c - sz * 0.5, sz).grow(6), Color(0, 0, 0, k))
	draw_texture_rect(tex, Rect2(c - sz * 0.5, sz), false, Color(1, 1, 1, k))
	if Loc.is_en():
		# подпись по-английски поверх русской
		var cap: String = COMIC_TEXT_EN[i]
		Ui.text(self, c + Vector2(0, sz.y * 0.5 - 30), cap, 34, Color(1, 0.95, 0.6, k), HORIZONTAL_ALIGNMENT_CENTER, 8)
	# точки-страницы и подсказка
	for j in comic_tex.size():
		draw_circle(Vector2(640 + (j - 1.5) * 26, 706), 6, Color(1, 0.85, 0.3) if j == i else Color(1, 1, 1, 0.35))
	var b := 0.5 + 0.4 * sin(t * 3.0)
	Ui.text(self, Vector2(1180, 700), "Далее ›", 22, Color(1, 1, 1, b), HORIZONTAL_ALIGNMENT_CENTER, 4)


func _draw_crosshair(p: Vector2) -> void:
	var r := 22.0 + recoil * 10.0
	var col := Color(1, 0.2, 0.15) if ammo > 0 and reload_t <= 0.0 else Color(0.6, 0.6, 0.6)
	for w in [[5.0, Ui.OUTLINE], [2.5, col]]:
		draw_arc(p, r, 0, TAU, 36, w[1], w[0])
		draw_line(p + Vector2(-r - 12, 0), p + Vector2(-r + 8, 0), w[1], w[0])
		draw_line(p + Vector2(r - 8, 0), p + Vector2(r + 12, 0), w[1], w[0])
		draw_line(p + Vector2(0, -r - 12), p + Vector2(0, -r + 8), w[1], w[0])
		draw_line(p + Vector2(0, r - 8), p + Vector2(0, r + 12), w[1], w[0])
	draw_circle(p, 2.5, col)


func _panel(r: Rect2) -> void:
	draw_rect(r.grow(3), Color(0.08, 0.06, 0.05, 0.85))
	draw_rect(r, Color(0.2, 0.15, 0.1, 0.8))


## Шкала сна: луна слева, открытый глаз справа. Чем больше заполнена, тем меньше хочется спать.
func _draw_sleep_bar() -> void:
	var r := Rect2(470, 80, 340, 22)
	var k := awake / 100.0
	_panel(r.grow(4))
	draw_rect(r, Color(0.12, 0.12, 0.22))
	var col := Color(0.35, 0.5, 0.95).lerp(Color(1.0, 0.3, 0.2), k)
	draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), col)
	if awake_flash > 0.0:
		draw_rect(r, Color(1, 1, 1, awake_flash * 0.35))
	for i in range(1, 4):
		var x := r.position.x + r.size.x * i / 4.0
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0, 0, 0, 0.35), 2)
	# луна
	var m := r.position + Vector2(-22, 11)
	draw_circle(m, 12, Color(1, 0.92, 0.55))
	draw_circle(m + Vector2(6, -4), 10, Color(0.2, 0.15, 0.1))
	Ui.text(self, m + Vector2(-8, -8), "z", 13, Color(0.8, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER, 3)
	# глаз
	var e := Vector2(r.end.x + 24, r.position.y + 11)
	var open := 2.0 + 8.0 * k
	Art2.ellipse(self, e, 15, open + 2, Ui.OUTLINE)
	Art2.ellipse(self, e, 13, open, Color.WHITE)
	draw_circle(e, minf(6.0, open), Color(0.15, 0.1, 0.05))
	Ui.text(self, r.get_center() + Vector2(0, 7), "СОН", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)


## Курица-стрелок за краем экрана — стрелка с «!» у края.
func _draw_gunner_alert() -> void:
	for tg in targets:
		if tg.kind != "hider" or not tg.get("gunner", false):
			continue
		var p := screen_pos(tg)
		if p.x > 0.0 and p.x < 1280.0:
			continue
		var left := p.x <= 0.0
		var x := 34.0 if left else 1246.0
		var y := clampf(p.y, 160.0, 560.0)
		var blink := 0.6 + 0.4 * sin(t * 12.0)
		var d := -1.0 if left else 1.0
		draw_colored_polygon(PackedVector2Array([Vector2(x + d * 22, y), Vector2(x - d * 6, y - 22), Vector2(x - d * 6, y + 22)]), Color(1, 0.15, 0.1, blink))
		Ui.text(self, Vector2(x - d * 22, y + 8), "!", 26, Color(1, 0.9, 0.3, blink), HORIZONTAL_ALIGNMENT_CENTER, 4)


func _draw_hud() -> void:
	# очки и время
	_panel(Rect2(14, 14, 230, 56))
	Ui.text(self, Vector2(26, 52), "ОЧКИ", 18, Color(0.9, 0.85, 0.7), HORIZONTAL_ALIGNMENT_LEFT, 3)
	Ui.text(self, Vector2(100, 54), str(score), 34, Color(1, 0.88, 0.35), HORIZONTAL_ALIGNMENT_LEFT, 5)
	var tr := Rect2(560, 14, 160, 56)
	_panel(tr)
	var tc := Color.WHITE if time_left > 10.0 else Color(1, 0.35 + 0.3 * sin(t * 10.0), 0.3)
	Ui.text(self, tr.get_center() + Vector2(0, 13), "%d:%02d" % [int(time_left) / 60, int(time_left) % 60], 36, tc)
	_draw_sleep_bar()
	_draw_gunner_alert()
	# пауза и звук
	for r in [R_PAUSE, R_SOUND]:
		draw_circle(r.get_center(), 27, Color(0.08, 0.06, 0.05, 0.85))
		draw_circle(r.get_center(), 24, Color(0.35, 0.2, 0.12))
	var c := R_PAUSE.get_center()
	draw_rect(Rect2(c + Vector2(-9, -11), Vector2(6, 22)), Color.WHITE)
	draw_rect(Rect2(c + Vector2(3, -11), Vector2(6, 22)), Color.WHITE)
	_draw_speaker(R_SOUND.get_center())
	# патроны
	var reloading := reload_t > 0.0
	for i in MAG:
		var x := R_AMMO.end.x - 30.0 - i * 38.0
		var y := R_AMMO.position.y + 18.0
		var filled := i < ammo and not reloading
		if reloading:
			filled = i < int((1.0 - reload_t / RELOAD_TIME) * MAG)
		var body := Color(0.85, 0.15, 0.12) if filled else Color(0.25, 0.22, 0.2, 0.7)
		var brass := Color(0.95, 0.75, 0.3) if filled else Color(0.3, 0.27, 0.22, 0.7)
		draw_rect(Rect2(x - 2, y - 2, 26, 60), Ui.OUTLINE)
		draw_rect(Rect2(x, y, 22, 40), body)
		draw_rect(Rect2(x, y + 40, 22, 16), brass)
		draw_rect(Rect2(x + 3, y + 3, 5, 34), Color(1, 1, 1, 0.25 if filled else 0.05))
	if ammo == 0 and not reloading:
		var a := 0.6 + 0.4 * sin(t * 8.0)
		Ui.text(self, Vector2(R_AMMO.get_center().x, R_AMMO.position.y - 14), "ПЕРЕЗАРЯДКА!", 26, Color(1, 0.4, 0.3, a))
	if hint_t > 0.0 and game_state == "play" and not touch_active:
		var a2 := minf(1.0, hint_t)
		var hint := "Нажмите на патроны, чтобы перезарядить" if touch_mode else "ПКМ / пробел — перезарядка"
		if ammo > 0:
			hint = "Ведите прицел пальцем, отпустите — выстрел" if touch_mode else "Ведите мышь к краю экрана, чтобы осмотреться"
		Ui.text(self, Vector2(640, 110), hint, 22, Color(1, 1, 1, a2))
	# стрелки у краёв — куда можно повернуть
	if game_state == "play":
		var pulse := 0.4 + 0.3 * sin(t * 4.0)
		if cam > 2.0:
			draw_colored_polygon(PackedVector2Array([Vector2(14, 360), Vector2(40, 330), Vector2(40, 390)]), Color(1, 1, 1, pulse))
		if cam < pan - 2.0:
			draw_colored_polygon(PackedVector2Array([Vector2(1266, 360), Vector2(1240, 330), Vector2(1240, 390)]), Color(1, 1, 1, pulse))
	if get_tree().paused and game_state == "play":
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.45))
		Ui.text(self, Vector2(640, 380), "ПАУЗА", 56, Color.WHITE)
	elif game_state == "play" and (not touch_mode or touch_active):
		_draw_crosshair(aim)


func _draw_speaker(c: Vector2) -> void:
	var col := Color.WHITE
	draw_rect(Rect2(c + Vector2(-13, -5), Vector2(7, 10)), col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -5), c + Vector2(3, -13), c + Vector2(3, 13), c + Vector2(-7, 5)]), col)
	if Sound.volume > 0.0:
		draw_arc(c + Vector2(4, 0), 7, -0.9, 0.9, 10, col, 2.5)
		draw_arc(c + Vector2(4, 0), 13, -0.9, 0.9, 10, col, 2.5)
	else:
		draw_line(c + Vector2(-16, -16), c + Vector2(16, 16), Color(1, 0.3, 0.25), 4)


func _button(r: Rect2, label: String, col: Color) -> void:
	var hov := r.has_point(aim) and not touch_mode
	var rr := r.grow(4) if hov else r
	draw_rect(rr.grow(4), Ui.OUTLINE)
	draw_rect(rr, col.lightened(0.15) if hov else col)
	draw_rect(Rect2(rr.position, Vector2(rr.size.x, rr.size.y * 0.45)), Color(1, 1, 1, 0.12))
	Ui.text(self, rr.get_center() + Vector2(0, 12), label, 32, Color.WHITE)


func _draw_title() -> void:
	if menu_bg != null:
		draw_texture_rect(menu_bg, Rect2(0, 0, 1280, 720), false)
	else:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.2, 0.3, 0.15))
	if menu_page == "volume":
		_draw_volume_page()
		return
	var items := [["btn_play", R_PLAY], ["btn_volume", R_VOL]]
	if not Platform.on_web:
		items.append(["btn_exit", R_EXIT])
	for i in items.size():
		var r: Rect2 = items[i][1]
		var tex := _ui(items[i][0])
		var hov := r.has_point(aim) and not touch_mode
		var sway := sin(t * 2.0 + i * 1.3) * 0.015
		var sc := 1.07 if hov else 1.0
		var sz := Vector2(r.size.x, r.size.x * tex.get_height() / tex.get_width()) * sc
		draw_set_transform(r.get_center(), sway, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false, Color(1.12, 1.08, 1.0) if hov else Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if best > 0:
		Ui.text(self, Vector2(1180, 700), "Рекорд: %d" % best, 26, Color(1, 0.92, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 5)
	_draw_menu_holes()


func _draw_menu_holes() -> void:
	if hole_tex == null:
		return
	for h in menu_holes:
		var k: float = minf(1.0, h.t / 0.06)
		var sz: float = 120.0 * h.s * (0.6 + 0.4 * k)
		draw_set_transform(h.p, h.rot, Vector2.ONE)
		draw_texture_rect(hole_tex, Rect2(Vector2(-sz, -sz) * 0.5, Vector2(sz, sz)), false)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if h.t < 0.12:
			draw_circle(h.p, 60.0 * (1.0 - h.t / 0.12), Color(1, 0.85, 0.4, 0.6))


## Вкладка «Громкость»: дощечка с двумя бегунками и кнопка «назад» со стрелкой.
func _draw_volume_page() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.45))
	var panel := Rect2(360, 150, 560, 420)
	_wood(panel)
	var title := _ui("btn_volume")
	var tw := 380.0
	draw_texture_rect(title, Rect2(640 - tw * 0.5, 70, tw, tw * title.get_height() / title.get_width()), false)
	Ui.text(self, Vector2(640, R_MBAR.position.y - 18), "МУЗЫКА", 30, Color(1, 0.92, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 6)
	_slider(R_MBAR, Sound.music)
	Ui.text(self, Vector2(640, R_SBAR.position.y - 18), "ВЫСТРЕЛЫ И ЗВУКИ", 30, Color(1, 0.92, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 6)
	_slider(R_SBAR, Sound.sfx)
	# кнопка «назад»
	var b := R_BACK
	var hov := b.has_point(aim) and not touch_mode
	var c := b.get_center()
	var r := b.size.x * 0.5 * (1.08 if hov else 1.0)
	draw_circle(c, r + 4, Color(0.2, 0.09, 0.03))
	draw_circle(c, r, Color(0.68, 0.4, 0.18))
	draw_circle(c, r - 8, Color(0.58, 0.33, 0.14))
	for a in [0.6, 2.2, 3.8, 5.4]:
		draw_circle(c + Vector2.from_angle(a) * (r - 4), 4, Color(0.75, 0.75, 0.78))
	var arrow := PackedVector2Array([c + Vector2(-26, 0), c + Vector2(0, -24), c + Vector2(0, -10), c + Vector2(24, -10),
		c + Vector2(24, 10), c + Vector2(0, 10), c + Vector2(0, 24)])
	var shadow := PackedVector2Array()
	for q in arrow:
		shadow.append(q + Vector2(3, 4))
	draw_colored_polygon(shadow, Color(0.2, 0.09, 0.03))
	draw_colored_polygon(arrow, Color(1, 0.88, 0.45))
	_draw_menu_holes()


func _wood(r: Rect2) -> void:
	draw_rect(r.grow(8), Color(0.2, 0.09, 0.03))
	var cols := [Color(0.66, 0.38, 0.17), Color(0.6, 0.34, 0.15)]
	var n := 5
	var h := r.size.y / n
	for i in n:
		var pr := Rect2(r.position.x, r.position.y + i * h, r.size.x, h - 3)
		draw_rect(pr, cols[i % 2])
		draw_rect(Rect2(pr.position, Vector2(pr.size.x, 6)), Color(0.78, 0.5, 0.25))
		draw_line(pr.position + Vector2(30, h * 0.55), pr.position + Vector2(pr.size.x - 40, h * 0.5), Color(0.5, 0.27, 0.1, 0.5), 2)
	for p in [r.position + Vector2(22, 22), Vector2(r.end.x - 22, r.position.y + 22),
			Vector2(r.position.x + 22, r.end.y - 22), r.end - Vector2(22, 22)]:
		draw_circle(p, 10, Color(0.25, 0.25, 0.27))
		draw_circle(p, 8, Color(0.72, 0.72, 0.75))
		draw_circle(p + Vector2(-2, -2), 3, Color(0.95, 0.95, 0.97))


func _slider(r: Rect2, v: float) -> void:
	draw_rect(r.grow(3), Color(0.2, 0.09, 0.03))
	draw_rect(r, Color(0.35, 0.18, 0.07))
	var x0 := r.position.x + 24.0
	var x1 := r.end.x - 24.0
	var cy := r.get_center().y
	draw_line(Vector2(x0, cy), Vector2(x1, cy), Color(0.15, 0.07, 0.02), 14)
	var kx := lerpf(x0, x1, v)
	draw_line(Vector2(x0, cy), Vector2(kx, cy), Color(1, 0.78, 0.25), 10)
	# ручка-гильза
	draw_rect(Rect2(kx - 12, cy - 24, 24, 48), Color(0.15, 0.07, 0.02))
	draw_rect(Rect2(kx - 10, cy - 22, 20, 30), Color(0.85, 0.15, 0.12))
	draw_rect(Rect2(kx - 10, cy + 8, 20, 14), Color(0.95, 0.75, 0.3))
	Ui.text(self, Vector2(r.end.x + 46, cy + 10), "%d%%" % int(round(v * 100)), 26, Color(1, 0.92, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 5)


func _draw_over() -> void:
	var k := clampf(over_t / 0.4, 0.0, 1.0)
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.55 * k))
	var r := Rect2(360, 150, 560, 470)
	r.position.y += (1.0 - k) * 60.0
	draw_rect(r.grow(5), Color(0.08, 0.06, 0.05, k))
	draw_rect(r, Color(0.25, 0.17, 0.1, 0.95 * k))
	draw_rect(r.grow(-8), Color(0.95, 0.75, 0.3, 0.7 * k), false, 3)
	Ui.text(self, Vector2(640, r.position.y + 80), "СОН ПРОПАЛ!" if sleep_lost else "ВРЕМЯ ВЫШЛО!", 52, Color(1, 0.88, 0.35, k), HORIZONTAL_ALIGNMENT_CENTER, 8)
	Ui.text(self, Vector2(640, r.position.y + 160), "Очки: %d" % score, 44, Color(1, 1, 1, k))
	if new_record:
		Ui.text(self, Vector2(640, r.position.y + 205), "Новый рекорд!", 30, Color(1, 0.6 + 0.3 * sin(t * 6.0), 0.3, k))
	else:
		Ui.text(self, Vector2(640, r.position.y + 205), "Рекорд: %d" % best, 26, Color(0.95, 0.9, 0.8, k))
	var acc := int(round(100.0 * hits / maxf(1.0, shots)))
	Ui.text(self, Vector2(640, r.position.y + 255), "Попаданий: %d из %d" % [hits, shots], 22, Color(0.95, 0.9, 0.8, k))
	Ui.text(self, Vector2(640, r.position.y + 290), "Точность: %d%%" % acc, 22, Color(0.95, 0.9, 0.8, k))
	if over_t > 0.8:
		_button(R_AGAIN, "ЕЩЁ РАЗ", Color(0.25, 0.55, 0.2))
		_button(R_MENU, "МЕНЮ", Color(0.45, 0.3, 0.15))



class Art2:
	static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 24:
			var a := i * TAU / 24.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		ci.draw_colored_polygon(pts, col)


func _ellipse_at(c: Vector2, rx: float, ry: float, col: Color) -> void:
	Art2.ellipse(self, c, rx, ry, col)
