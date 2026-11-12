extends Control

const USER_SKIN_PATH := "res://assets/skins/user_green_armor.png"
const TARGET_SCORE := 7
const COURT_MARGIN_X := 72.0
const COURT_TOP := 174.0
const COURT_BOTTOM_MARGIN := 72.0
const PADDLE_W := 18.0
const PADDLE_H := 128.0
const BALL_RADIUS := 10.0

const BG := Color("040712")
const PANEL := Color("0a1226")
const COURT := Color("071126")
const INK := Color("e8f7ff")
const MUTED := Color("8399bd")
const CYAN := Color("42f5ff")
const GREEN := Color("9dff6e")
const MAGENTA := Color("ff4fb3")
const GOLD := Color("ffdc70")
const RED := Color("ff6b8e")
const VIOLET := Color("8b6cff")

var player_y := 0.0
var cpu_y := 0.0
var ball := Vector2.ZERO
var ball_velocity := Vector2.ZERO
var player_score := 0
var cpu_score := 0
var started := false
var paused := false
var game_over := false
var selected_skin := "pixel"
var mouse_y := 0.0
var mouse_active := false
var rng := RandomNumberGenerator.new()
var user_skin: Texture2D
var fx_time := 0.0

var title_label: Label
var subtitle_label: Label
var score_label: Label
var status_label: Label
var skin_label: Label
var pixel_button: Button
var armor_button: Button
var start_button: Button
var pause_button: Button
var reset_button: Button
var result_label: Label
var result_detail: Label
var controls_label: Label
var skin_preview: TextureRect

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    rng.randomize()
    var arabic_font := load("res://assets/fonts_Amiri-Regular.ttf") as Font
    if arabic_font != null:
        var game_theme := Theme.new()
        game_theme.default_font = arabic_font
        game_theme.default_font_size = 16
        theme = game_theme
    user_skin = load(USER_SKIN_PATH) as Texture2D if ResourceLoader.exists(USER_SKIN_PATH) else null
    _build_ui()
    _reset_positions()
    _reset_ball(1)
    _layout_ui()
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        _layout_ui()
        queue_redraw()

func _process(delta: float) -> void:
    fx_time += delta
    if started and not paused and not game_over:
        _update_player(delta)
        _update_cpu(delta)
        _update_ball(delta)
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        mouse_y = motion.position.y
        mouse_active = true
    elif event is InputEventKey and event.pressed and not event.echo:
        var key := event as InputEventKey
        if key.keycode == KEY_ESCAPE and started and not game_over:
            _toggle_pause()
        elif key.keycode == KEY_R and game_over:
            _start_game()
        elif key.keycode == KEY_1:
            _set_skin("pixel")
        elif key.keycode == KEY_2:
            _set_skin("armor")

func _build_ui() -> void:
    title_label = _label("Pong 22#$", 42, INK)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(title_label)

    subtitle_label = _label("نبرد دوبعدی پینگ‌پنگ با حریف رایانه‌ای", 16, MUTED)
    subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(subtitle_label)

    score_label = _label("شما  ۰    -    ۰  رایانه", 34, GOLD)
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(score_label)

    status_label = _label("شروع را بزنید؛ سپس توپ را برگردانید.", 15, MUTED)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(status_label)

    skin_label = _label("اسکین پدل شما", 15, INK)
    skin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    add_child(skin_label)

    pixel_button = _button("۱  پیکسل دوبعدی", CYAN)
    pixel_button.pressed.connect(_set_skin.bind("pixel"))
    add_child(pixel_button)

    armor_button = _button("۲  چهره و زره سبز", GREEN)
    armor_button.pressed.connect(_set_skin.bind("armor"))
    add_child(armor_button)

    start_button = _button("شروع بازی", CYAN)
    start_button.pressed.connect(_start_game)
    add_child(start_button)

    pause_button = _button("مکث  Esc", GOLD)
    pause_button.pressed.connect(_toggle_pause)
    pause_button.visible = false
    add_child(pause_button)

    reset_button = _button("بازی دوباره", MAGENTA)
    reset_button.pressed.connect(_start_game)
    reset_button.visible = false
    add_child(reset_button)

    result_label = _label("", 30, GREEN)
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.visible = false
    add_child(result_label)

    result_detail = _label("", 16, MUTED)
    result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_detail.visible = false
    add_child(result_detail)

    controls_label = _label("کنترل‌ها: حرکت موس یا کلیدهای بالا و پایین | مکث: Esc | انتخاب سریع: ۱ / ۲", 14, MUTED)
    controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(controls_label)

    skin_preview = TextureRect.new()
    skin_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    skin_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    skin_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    skin_preview.visible = user_skin != null
    if user_skin != null:
        skin_preview.texture = user_skin
    add_child(skin_preview)

    _set_skin("pixel")

func _label(text: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    var arabic_font := load("res://assets/fonts_Amiri-Regular.ttf") as Font
    if arabic_font != null:
        label.add_theme_font_override("font", arabic_font)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.42))
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _button(text: String, accent: Color) -> Button:
    var button := Button.new()
    button.text = text
    var arabic_font := load("res://assets/fonts_Amiri-Regular.ttf") as Font
    if arabic_font != null:
        button.add_theme_font_override("font", arabic_font)
    button.custom_minimum_size = Vector2(180, 44)
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", INK)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_color_override("font_pressed_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _button_box(Color("10243a"), Color(accent, 0.35)))
    button.add_theme_stylebox_override("hover", _button_box(Color("183853"), accent))
    button.add_theme_stylebox_override("pressed", _button_box(Color("214665"), Color.WHITE))
    button.add_theme_stylebox_override("focus", _button_box(Color("183853"), accent))
    return button

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(1)
    box.set_corner_radius_all(12)
    box.shadow_color = Color(border, 0.18)
    box.shadow_size = 7
    box.content_margin_left = 14
    box.content_margin_right = 14
    box.content_margin_top = 8
    box.content_margin_bottom = 8
    return box

func _layout_ui() -> void:
    if title_label == null:
        return
    var w := size.x
    var h := size.y
    var compact := w < 700.0
    title_label.position = Vector2(0, 20)
    title_label.size = Vector2(w, 44 if compact else 56)
    title_label.add_theme_font_size_override("font_size", 28 if compact else 42)
    subtitle_label.position = Vector2(0, 76)
    subtitle_label.size = Vector2(w, 24)
    subtitle_label.add_theme_font_size_override("font_size", 12 if compact else 16)
    score_label.position = Vector2(0, 98)
    score_label.size = Vector2(w, 44)
    score_label.add_theme_font_size_override("font_size", 25 if compact else 34)
    status_label.position = Vector2(w * 0.25, 138)
    status_label.size = Vector2(w * 0.5, 28)
    status_label.add_theme_font_size_override("font_size", 12 if compact else 15)

    var controls_y := h - 58.0
    controls_label.position = Vector2(0, controls_y)
    controls_label.size = Vector2(w, 30)

    skin_label.position = Vector2(0, 18)
    skin_label.size = Vector2(w - 24, 24)
    if compact:
        pixel_button.custom_minimum_size = Vector2(158, 38)
        armor_button.custom_minimum_size = Vector2(190, 38)
        pixel_button.position = Vector2(8, 48)
        armor_button.position = Vector2(w - 198, 48)
    else:
        pixel_button.custom_minimum_size = Vector2(180, 44)
        armor_button.custom_minimum_size = Vector2(180, 44)
        pixel_button.position = Vector2(w - 410, 50)
        armor_button.position = Vector2(w - 215, 50)
    start_button.position = Vector2(30, h - 108)
    pause_button.position = Vector2(w - 176, h - 108)
    reset_button.position = Vector2((w - 180) * 0.5, h * 0.62)
    result_label.position = Vector2(w * 0.18, h * 0.47)
    result_label.size = Vector2(w * 0.64, 46)
    result_detail.position = Vector2(w * 0.18, h * 0.53)
    result_detail.size = Vector2(w * 0.64, 34)
    if skin_preview != null:
        skin_preview.position = Vector2(w - 82, 43)
        skin_preview.size = Vector2(54, 54)
        skin_preview.visible = not compact and selected_skin == "armor" and user_skin != null

func _court_rect() -> Rect2:
    var margin_x := minf(COURT_MARGIN_X, maxf(18.0, size.x * 0.08))
    var bottom_margin := COURT_BOTTOM_MARGIN if size.x >= 700.0 else 116.0
    return Rect2(margin_x, COURT_TOP, maxf(220.0, size.x - margin_x * 2.0), maxf(260.0, size.y - COURT_TOP - bottom_margin))

func _reset_positions() -> void:
    var court := _court_rect()
    player_y = court.position.y + court.size.y * 0.5
    cpu_y = player_y
    mouse_y = player_y

func _reset_ball(direction: int) -> void:
    var court := _court_rect()
    ball = court.position + court.size * 0.5
    var vertical := rng.randf_range(-0.42, 0.42)
    ball_velocity = Vector2(float(direction) * 390.0, vertical * 390.0)

func _start_game() -> void:
    started = true
    paused = false
    game_over = false
    player_score = 0
    cpu_score = 0
    _reset_positions()
    _reset_ball(1 if rng.randi_range(0, 1) == 0 else -1)
    start_button.visible = false
    reset_button.visible = false
    pause_button.visible = true
    result_label.visible = false
    result_detail.visible = false
    status_label.text = "رالی شروع شد؛ توپ را برگردانید."
    _update_score_label()

func _toggle_pause() -> void:
    if not started or game_over:
        return
    paused = not paused
    pause_button.text = "ادامه  Esc" if paused else "مکث  Esc"
    status_label.text = "بازی متوقف است؛ برای ادامه روی دکمه یا Esc بزنید." if paused else "رالی ادامه دارد؛ توپ را برگردانید."

func _update_player(delta: float) -> void:
    var court := _court_rect()
    var half := PADDLE_H * 0.5
    if Input.is_key_pressed(KEY_UP):
        player_y -= 520.0 * delta
        mouse_active = false
    if Input.is_key_pressed(KEY_DOWN):
        player_y += 520.0 * delta
        mouse_active = false
    if mouse_active and mouse_y >= court.position.y - 40.0 and mouse_y <= court.end.y + 40.0:
        player_y = lerpf(player_y, mouse_y, minf(1.0, delta * 18.0))
    player_y = clampf(player_y, court.position.y + half, court.end.y - half)

func _update_cpu(delta: float) -> void:
    var court := _court_rect()
    var target := ball.y
    var reaction := 0.82 if ball_velocity.x > 0.0 else 0.4
    var desired := lerpf(cpu_y, target, reaction * delta * 5.2)
    cpu_y = move_toward(cpu_y, desired, 330.0 * delta)
    cpu_y = clampf(cpu_y, court.position.y + PADDLE_H * 0.5, court.end.y - PADDLE_H * 0.5)

func _update_ball(delta: float) -> void:
    var court := _court_rect()
    ball += ball_velocity * delta
    if ball.y - BALL_RADIUS <= court.position.y:
        ball.y = court.position.y + BALL_RADIUS
        ball_velocity.y = absf(ball_velocity.y)
    elif ball.y + BALL_RADIUS >= court.end.y:
        ball.y = court.end.y - BALL_RADIUS
        ball_velocity.y = -absf(ball_velocity.y)

    var player_rect := Rect2(Vector2(court.position.x + 38.0, player_y - PADDLE_H * 0.5), Vector2(PADDLE_W, PADDLE_H))
    var cpu_rect := Rect2(Vector2(court.end.x - 56.0, cpu_y - PADDLE_H * 0.5), Vector2(PADDLE_W, PADDLE_H))
    if ball_velocity.x < 0.0 and _ball_hits(player_rect):
        ball.x = player_rect.end.x + BALL_RADIUS + 1.0
        _reflect_from_paddle(player_y, 1.0)
    elif ball_velocity.x > 0.0 and _ball_hits(cpu_rect):
        ball.x = cpu_rect.position.x - BALL_RADIUS - 1.0
        _reflect_from_paddle(cpu_y, -1.0)

    if ball.x < court.position.x - 42.0:
        cpu_score += 1
        _after_point(-1)
    elif ball.x > court.end.x + 42.0:
        player_score += 1
        _after_point(1)

func _ball_hits(rect: Rect2) -> bool:
    return ball.x + BALL_RADIUS >= rect.position.x and ball.x - BALL_RADIUS <= rect.end.x and ball.y + BALL_RADIUS >= rect.position.y and ball.y - BALL_RADIUS <= rect.end.y

func _reflect_from_paddle(paddle_y: float, direction: float) -> void:
    var offset := clampf((ball.y - paddle_y) / (PADDLE_H * 0.5), -1.0, 1.0)
    var speed := minf(760.0, ball_velocity.length() * 1.045 + 8.0)
    ball_velocity = Vector2(direction * speed, offset * 430.0)
    ball_velocity = ball_velocity.normalized() * speed

func _after_point(last_direction: int) -> void:
    _update_score_label()
    if player_score >= TARGET_SCORE or cpu_score >= TARGET_SCORE:
        game_over = true
        paused = false
        pause_button.visible = false
        reset_button.visible = true
        result_label.visible = true
        result_detail.visible = true
        if player_score > cpu_score:
            result_label.text = "بردید!"
            result_label.add_theme_color_override("font_color", GREEN)
        else:
            result_label.text = "رایانه این رالی را برد."
            result_label.add_theme_color_override("font_color", RED)
        result_detail.text = "نتیجه نهایی: شما %d  -  %d رایانه" % [player_score, cpu_score]
        status_label.text = "برای بازی دوباره روی دکمه بزنید یا کلید R را فشار دهید."
    else:
        _reset_ball(-last_direction)
        status_label.text = "امتیاز ثبت شد؛ رالی بعدی شروع شد."

func _update_score_label() -> void:
    score_label.text = "شما  %s    -    %s  رایانه" % [_fa_number(player_score), _fa_number(cpu_score)]

func _fa_number(value: int) -> String:
    var latin := str(value)
    var fa := ""
    for ch in latin:
        var index := ch.unicode_at(0) - 48
        fa += "۰۱۲۳۴۵۶۷۸۹"[index] if index >= 0 and index <= 9 else ch
    return fa

func _set_skin(skin: String) -> void:
    selected_skin = skin
    var pixel_selected := skin == "pixel"
    pixel_button.add_theme_stylebox_override("normal", _button_box(Color("17344d") if pixel_selected else Color("10243a"), CYAN if pixel_selected else Color(CYAN, 0.35)))
    armor_button.add_theme_stylebox_override("normal", _button_box(Color("163a2c") if not pixel_selected else Color("10243a"), GREEN if not pixel_selected else Color(GREEN, 0.35)))
    if skin_preview != null:
        skin_preview.visible = size.x >= 700.0 and skin == "armor" and user_skin != null

func _draw() -> void:
    var court := _court_rect()
    draw_rect(Rect2(Vector2.ZERO, size), BG)
    var pulse := 0.5 + sin(fx_time * 2.2) * 0.5
    draw_circle(Vector2(size.x * 0.86, size.y * 0.16), 290.0, Color(CYAN, 0.035 + pulse * 0.018))
    draw_circle(Vector2(size.x * 0.10, size.y * 0.84), 260.0, Color(VIOLET, 0.045 + pulse * 0.018))
    draw_circle(Vector2(size.x * 0.52, size.y * 0.52), 390.0, Color(MAGENTA, 0.012))
    for y in range(0, int(size.y), 6):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color(INK, 0.012), 1.0)
    var scan_y := fmod(fx_time * 42.0, maxf(1.0, size.y))
    draw_line(Vector2(0, scan_y), Vector2(size.x, scan_y), Color(CYAN, 0.045), 1.0)

    var header := Rect2(Vector2(24, 16), Vector2(size.x - 48, 146))
    draw_rect(header.grow(5), Color(CYAN, 0.025), true)
    draw_rect(header, Color(PANEL, 0.94), true)
    draw_rect(header, Color(CYAN, 0.22), false, 1.0)
    draw_line(Vector2(24, 162), Vector2(size.x - 24, 162), Color(CYAN, 0.48), 1.0)
    draw_line(Vector2(24, 164), Vector2(size.x - 24, 164), Color(MAGENTA, 0.12), 1.0)
    draw_line(Vector2(40, 28), Vector2(160, 28), Color(MAGENTA, 0.7), 2.0)
    draw_line(Vector2(size.x - 160, 28), Vector2(size.x - 40, 28), Color(GREEN, 0.7), 2.0)

    draw_rect(court, COURT, true)
    draw_rect(court.grow(8), Color(CYAN, 0.025), false, 8.0)
    draw_rect(court.grow(3), Color(MAGENTA, 0.12), false, 2.0)
    draw_rect(court, Color(CYAN, 0.62), false, 2.0)
    for x in range(int(court.position.x + 20.0), int(court.end.x - 20.0), 64):
        draw_line(Vector2(x, court.position.y), Vector2(x, court.end.y), Color(CYAN, 0.035), 1.0)
    for y in range(int(court.position.y + 20.0), int(court.end.y - 20.0), 42):
        draw_line(Vector2(court.position.x, y), Vector2(court.end.x, y), Color(CYAN, 0.03), 1.0)
    draw_line(Vector2(court.get_center().x, court.position.y + 18), Vector2(court.get_center().x, court.end.y - 18), Color(CYAN, 0.26), 2.0)
    for y in range(int(court.position.y + 16.0), int(court.end.y - 16.0), 34):
        draw_rect(Rect2(court.get_center().x - 2, y, 4, 17), Color(INK, 0.48), true)
    _draw_corner_brackets(court)

    var player_rect := Rect2(Vector2(court.position.x + 38.0, player_y - PADDLE_H * 0.5), Vector2(PADDLE_W, PADDLE_H))
    var cpu_rect := Rect2(Vector2(court.end.x - 56.0, cpu_y - PADDLE_H * 0.5), Vector2(PADDLE_W, PADDLE_H))
    _draw_player_paddle(player_rect)
    _draw_cpu_paddle(cpu_rect)
    draw_circle(ball, BALL_RADIUS + 18.0, Color(CYAN, 0.045))
    draw_circle(ball, BALL_RADIUS + 9.0, Color(CYAN, 0.18))
    draw_circle(ball, BALL_RADIUS, INK)
    draw_circle(ball, BALL_RADIUS * 0.42, CYAN)
    if not started:
        draw_rect(Rect2(court.position + Vector2(2, 2), court.size - Vector2(4, 4)), Color(2.0 / 255.0, 8.0 / 255.0, 18.0 / 255.0, 0.38), true)
        draw_line(court.get_center() + Vector2(-80, 0), court.get_center() + Vector2(80, 0), Color(GOLD, 0.35), 2.0)
    if paused and not game_over:
        draw_rect(Rect2(court.position, court.size), Color(0.01, 0.03, 0.07, 0.72), true)
        draw_circle(court.get_center(), 46.0, Color(GOLD, 0.12))

func _draw_player_paddle(rect: Rect2) -> void:
    if selected_skin == "armor" and user_skin != null:
        draw_rect(rect.grow(12), Color(GREEN, 0.045), true)
        draw_rect(rect.grow(6), Color(GREEN, 0.18), true)
        draw_texture_rect(user_skin, Rect2(rect.position.x - 30.0, rect.position.y + 4.0, 78.0, 118.0), false)
        draw_rect(rect, Color("2d8d62"), true)
        draw_line(rect.position + Vector2(2, 8), rect.end - Vector2(2, 8), Color("d7ffb4"), 2.0)
    else:
        var pixel := Color("5fe4ff")
        draw_rect(rect.grow(12), Color(pixel, 0.045), true)
        draw_rect(rect.grow(5), Color(pixel, 0.18), true)
        draw_rect(Rect2(rect.position + Vector2(-6, 0), Vector2(rect.size.x + 12, 20)), pixel, true)
        draw_rect(Rect2(rect.position + Vector2(-3, 20), Vector2(rect.size.x + 6, rect.size.y - 40)), Color("17708d"), true)
        draw_rect(Rect2(rect.position + Vector2(-6, rect.size.y - 20), Vector2(rect.size.x + 12, 20)), pixel, true)
        draw_rect(Rect2(rect.position + Vector2(4, 7), Vector2(5, 8)), Color.WHITE, true)
        draw_rect(Rect2(rect.position + Vector2(4, rect.size.y - 15), Vector2(5, 8)), Color.WHITE, true)

func _draw_cpu_paddle(rect: Rect2) -> void:
    draw_rect(rect.grow(12), Color(MAGENTA, 0.045), true)
    draw_rect(rect.grow(5), Color(MAGENTA, 0.18), true)
    draw_rect(rect, Color("d94a78"), true)
    draw_rect(Rect2(rect.position + Vector2(-5, 8), Vector2(rect.size.x + 10, 22)), MAGENTA, true)
    draw_rect(Rect2(rect.position + Vector2(-5, rect.size.y - 30), Vector2(rect.size.x + 10, 22)), MAGENTA, true)
    draw_line(rect.position + Vector2(4, 30), rect.end - Vector2(4, 30), Color("ffb1c8"), 2.0)

func _draw_corner_brackets(rect: Rect2) -> void:
    var c := Color(CYAN, 0.65)
    var length := 18.0
    draw_line(rect.position, rect.position + Vector2(length, 0), c, 2.0)
    draw_line(rect.position, rect.position + Vector2(0, length), c, 2.0)
    draw_line(Vector2(rect.end.x, rect.position.y), rect.end - Vector2(length, rect.size.y), c, 2.0)
    draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y + length), c, 2.0)
    draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + length, rect.end.y), c, 2.0)
    draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x, rect.end.y - length), c, 2.0)
    draw_line(rect.end, rect.end - Vector2(length, 0), c, 2.0)
    draw_line(rect.end, rect.end - Vector2(0, length), c, 2.0)
