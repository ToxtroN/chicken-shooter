extends Node
## Мост к SDK Яндекс Игр (window.yg из web/yandex_shell.html).
## - определяет язык через SDK (environment.i18n.lang), иначе — по языку браузера/системы;
## - LoadingAPI.ready() — когда показан экран игры;
## - GameplayAPI.start()/stop() — когда идёт / не идёт бой;
## - полноэкранная реклама только в логических паузах (между боями), на это время
##   игра ставится на паузу, а звук выключается;
## - при потере фокуса или скрытии вкладки звук выключается, бой ставится на паузу.
## Вне браузера все вызовы просто ничего не делают.

signal focus_lost

var _poll := 0.0
var _gameplay := false
var _ad_cb: Callable
var _ad_done_before := -1
var _ad_t := 0.0
var _was_paused := false
var _hidden := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Platform.on_web = Platform.is_web()
	var lang := ""
	if Platform.on_web:
		lang = str(_js("window.yg ? window.yg.lang : ''"))
	if lang == "" or lang == "<null>":
		lang = OS.get_locale_language()
	Loc.set_lang(lang)


func _js(code: String) -> Variant:
	if not Platform.on_web:
		return null
	return JavaScriptBridge.eval(code, true)


## Игру можно начинать — вызывается, когда показан главный экран.
func game_ready() -> void:
	_js("window.yg && window.yg.ready()")


## Полноэкранная реклама. cb вызывается, когда реклама закрыта (или не показана).
func show_fullscreen_ad(cb: Callable) -> void:
	if not Platform.on_web or ad_busy():
		cb.call()
		return
	_ad_cb = cb
	_ad_done_before = int(_js("window.yg ? window.yg.adDone : -1"))
	if _ad_done_before < 0:
		_ad_done_before = -1
		cb.call()
		return
	_was_paused = get_tree().paused
	get_tree().paused = true
	Platform.ad_open = true
	_set_gameplay(false)
	_apply_mute()
	_ad_t = 0.0
	_js("window.yg.showAd()")


func ad_busy() -> bool:
	return Platform.ad_open


func _finish_ad() -> void:
	Platform.ad_open = false
	get_tree().paused = _was_paused
	_apply_mute()
	var cb := _ad_cb
	_ad_cb = Callable()
	if cb.is_valid():
		cb.call()


func _apply_mute() -> void:
	var m := Platform.ad_open or _hidden
	if m != Platform.muted:
		Platform.muted = m
		Sound.apply()


func _set_gameplay(on: bool) -> void:
	if on == _gameplay:
		return
	_gameplay = on
	_js("window.yg && window.yg.gameplay(%s)" % ("true" if on else "false"))


func _process(delta: float) -> void:
	if not Platform.on_web:
		return
	_poll -= delta
	if Platform.ad_open:
		_ad_t += delta
		var done := int(_js("window.yg ? window.yg.adDone : 0"))
		if done != _ad_done_before or _ad_t > 60.0:
			_finish_ad()
		return
	if _poll > 0.0:
		return
	_poll = 0.15
	# фокус и видимость вкладки
	var hidden := bool(_js("window.yg ? window.yg.audioOff : false"))
	if hidden != _hidden:
		_hidden = hidden
		_apply_mute()
		if hidden:
			focus_lost.emit()
			_pause_battle()
	# разметка геймплея: идёт бой, не пауза, не экран итогов
	var sc := get_tree().current_scene
	var playing := false
	if sc != null and "game_state" in sc:
		playing = sc.game_state == "play" and not get_tree().paused and sc.overlay == null and not hidden
	_set_gameplay(playing)


func _pause_battle() -> void:
	var sc := get_tree().current_scene
	if sc != null and sc.has_method("toggle_pause") and "game_state" in sc:
		if sc.game_state == "play" and not get_tree().paused:
			sc.toggle_pause()

