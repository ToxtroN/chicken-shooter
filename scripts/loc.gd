class_name Loc
## Локализация RU/EN. Язык определяется через SDK Яндекс Игр (Platform.lang),
## в остальных случаях — по языку системы. Все надписи проходят через Ui.text → Loc.t,
## поэтому в коде строки остаются русскими, а перевод берётся из словаря.
## Числа в строке заменяются на «#» при поиске шаблона и подставляются обратно.

static var lang := "ru"
static var _re_num: RegEx
static var _cache := {}


static func set_lang(code: String) -> void:
	code = code.to_lower().substr(0, 2)
	# русский для ru и стран СНГ, где игроки обычно понимают русский; иначе — английский
	lang = "ru" if code in ["ru", "be", "kk", "uk", "uz", "ky", "tg", "hy", "az"] else "en"
	_cache.clear()


static func is_en() -> bool:
	return lang == "en"


static func _has_cyr(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 0x400 and c <= 0x4FF:
			return true
	return false


## Перевести строку (готовую, уже с подставленными числами).
static func t(s: String) -> String:
	if lang == "ru" or not _has_cyr(s):
		return s
	if _cache.has(s):
		return _cache[s]
	var res := _translate(s)
	if _cache.size() > 2000:
		_cache.clear()
	_cache[s] = res
	return res


static func _translate(s: String) -> String:
	if EN.has(s):
		return EN[s]
	# шаблон с числами
	if _re_num == null:
		_re_num = RegEx.new()
		_re_num.compile("\\d+(?:\\.\\d+)?")
	var nums: Array = []
	for m in _re_num.search_all(s):
		nums.append(m.get_string())
	if not nums.is_empty():
		var tpl := _re_num.sub(s, "#", true)
		if EN.has(tpl):
			var out: String = EN[tpl]
			for n in nums:
				var i := out.find("#")
				if i >= 0:
					out = out.substr(0, i) + str(n) + out.substr(i + 1)
			return out
	# составные строки: «Имя — куплено!», «Снайпер!», «Всадник уходит»
	if s.contains(" — "):
		var parts := s.split(" — ")
		var outp: Array = []
		for p in parts:
			outp.append(t(p))
		return " — ".join(outp)
	if s.ends_with("!") and EN.has(s.trim_suffix("!")):
		return EN[s.trim_suffix("!")] + "!"
	for suf in SUFFIX:
		if s.ends_with(suf):
			return t(s.trim_suffix(suf)) + SUFFIX[suf]
	return s


const SUFFIX := {" пал!": " has fallen!", " уходит": " leaves", "куплено!": "purchased!"}

const EN := {
	"Нажмите, чтобы начать": "Click to start", "ИГРАТЬ": "PLAY", "Рекорд: #": "Best: #",
	"ОЧКИ": "SCORE", "ВРЕМЯ": "TIME", "ПЕРЕЗАРЯДКА!": "RELOAD!", "ПКМ / пробел — перезарядка": "Right click / Space — reload",
	"Нажмите на патроны, чтобы перезарядить": "Tap the shells to reload",
	"ВРЕМЯ ВЫШЛО!": "TIME'S UP!", "Очки: #": "Score: #", "Новый рекорд!": "New record!",
	"ЕЩЁ РАЗ": "PLAY AGAIN", "МЕНЮ": "MENU", "ПАУЗА": "PAUSED", "Попаданий: # из #": "Hits: # of #",
	"Точность: #%": "Accuracy: #%", "Ведите мышь к краю экрана, чтобы осмотреться": "Move the mouse to the screen edge to look around",
	"Проведите пальцем, чтобы осмотреться": "Swipe to look around",
	"Ведите прицел пальцем, отпустите — выстрел": "Drag to aim, release to shoot",
	"УТРО ДОБРЫМ": "THERE'S NO", "НЕ БЫВАЕТ": "GOOD MORNING", "КУ-КА-РЕ-КУ!": "COCK-A-DOODLE-DOO!",
	"КУ-КА-РЕ-КУ!!!": "COCK-A-DOODLE-DOO!!!", "Нажмите, чтобы продолжить": "Click to continue",
	"6:00 утра. Ты только что вернулся с ночной смены...": "6 AM. You just got home from the night shift...",
	"Лёг, закрыл глаза — и тут: «КУ-КА-РЕ-КУ!!!»": "You close your eyes... and then: \"COCK-A-DOODLE-DOO!!!\"",
	"Всё. Где моё ружьё?": "That's it. Where's my shotgun?", "ДЗЫНЬ!": "CLANG!", "ОЙ! −30": "OUCH! −30", "СОН": "SLEEP", "МУЗЫКА": "MUSIC", "ВЫСТРЕЛЫ И ЗВУКИ": "SHOTS & SOUNDS", "Далее ›": "Next ›", "СОН ПРОПАЛ!": "WIDE AWAKE!",
}
