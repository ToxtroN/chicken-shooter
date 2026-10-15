class_name Platform
## Общее состояние платформы (Яндекс Игры / обычный браузер / ПК).
## Сам мост к SDK — в platform_node.gd (автозагрузка «Yandex»).

static var muted := false        # звук выключен платформой (вкладка скрыта, нет фокуса, реклама)
static var ad_open := false
static var on_web := false


static func is_web() -> bool:
	return OS.has_feature("web")
