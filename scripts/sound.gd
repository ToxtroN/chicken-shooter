class_name Sound
## Громкость: отдельно музыка (шина Music) и звуки/выстрелы (шина SFX).
## Сохраняется в user://settings.cfg. Платформа (реклама, скрытая вкладка) глушит всё через Master.

const SETTINGS := "user://settings.cfg"
static var music := 0.7
static var sfx := 0.9
static var volume := 0.9          # для совместимости: общий «включено/выключено»
static var _loaded := false


static func _bus(name: String) -> int:
	var i := AudioServer.get_bus_index(name)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, name)
		AudioServer.set_bus_send(i, "Master")
	return i


static func load_volume() -> void:
	if _loaded:
		return
	_loaded = true
	_bus("Music")
	_bus("SFX")
	var cf := ConfigFile.new()
	if cf.load(SETTINGS) == OK:
		music = float(cf.get_value("audio", "music", 0.7))
		sfx = float(cf.get_value("audio", "sfx", 0.9))
	apply()


static func set_music(v: float) -> void:
	music = clampf(v, 0.0, 1.0)
	_save()


static func set_sfx(v: float) -> void:
	sfx = clampf(v, 0.0, 1.0)
	_save()


static func set_volume(v: float) -> void:
	set_music(v)
	set_sfx(v)


static func _save() -> void:
	apply()
	var cf := ConfigFile.new()
	cf.load(SETTINGS)
	cf.set_value("audio", "music", music)
	cf.set_value("audio", "sfx", sfx)
	cf.save(SETTINGS)


## Кнопка-динамик в бою: выключить всё / вернуть.
static var _before := Vector2(0.7, 0.9)


static func toggle_mute() -> void:
	if music > 0.0 or sfx > 0.0:
		_before = Vector2(music, sfx)
		music = 0.0
		sfx = 0.0
	else:
		music = maxf(_before.x, 0.3)
		sfx = maxf(_before.y, 0.3)
	_save()


static func apply() -> void:
	volume = maxf(music, sfx)
	var m := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(m, Platform.muted)
	for pair in [["Music", music], ["SFX", sfx]]:
		var b := _bus(pair[0])
		AudioServer.set_bus_mute(b, pair[1] <= 0.0)
		AudioServer.set_bus_volume_db(b, linear_to_db(maxf(pair[1], 0.001)))
