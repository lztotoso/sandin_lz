extends CharacterBody2D

var speed: float = 200.0
var run_speed: float = 350.0
var jump_force: float = -400.0
var gravity: float = 900.0

@onready var anim_sprite: AnimatedSprite2D = $Frames_personagem

var facing_direction = 1
var is_running: bool = false
var is_attacking: bool = false
var is_defending: bool = false
var is_dead: bool = false
var is_hurt: bool = false
var is_dashing: bool = false
var can_dash: bool = true

var jump_anim_delay: float = 0.1
var jump_buffer_timer: Timer
var attack_release_timer: Timer
var defense_release_timer: Timer
var dash_timer: Timer
var dash_cooldown_timer: Timer

var start_position: Vector2
var selected_attack: int = 1

# Controle de dash
var last_left_press_time: float = -1.0
var last_right_press_time: float = -1.0
var dash_speed: float = 600.0
var dash_duration: float = 0.4
var dash_interval: float = 0.3
var dash_cooldown: float = 0.8

func _ready() -> void:
	jump_buffer_timer = Timer.new()
	jump_buffer_timer.one_shot = true
	add_child(jump_buffer_timer)
	jump_buffer_timer.timeout.connect(_apply_jump_force)

	attack_release_timer = Timer.new()
	attack_release_timer.one_shot = true
	add_child(attack_release_timer)
	attack_release_timer.timeout.connect(_release_attack_failsafe)

	defense_release_timer = Timer.new()
	defense_release_timer.one_shot = true
	add_child(defense_release_timer)
	defense_release_timer.timeout.connect(_release_defense_failsafe)

	dash_timer = Timer.new()
	dash_timer.one_shot = true
	add_child(dash_timer)
	dash_timer.timeout.connect(_end_dash)

	dash_cooldown_timer = Timer.new()
	dash_cooldown_timer.one_shot = true
	add_child(dash_cooldown_timer)
	dash_cooldown_timer.timeout.connect(_reset_dash_cooldown)

	start_position = global_position

	anim_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var direction = Vector2.ZERO

	if not is_dashing and not (is_attacking and is_on_floor()):
		if Input.is_action_pressed("mv_direita"):
			direction.x += 1
			facing_direction = 1
		elif Input.is_action_pressed("mv_esquerda"):
			direction.x -= 1
			facing_direction = -1

	is_running = Input.is_action_pressed("correr") and not is_dashing and not (is_attacking and is_on_floor())
	direction = direction.normalized()

	if is_dashing:
		velocity.x = facing_direction * dash_speed
	elif not (is_attacking and is_on_floor()):
		if is_running:
			velocity.x = direction.x * run_speed
		else:
			velocity.x = direction.x * speed

	# Gravidade
	if is_on_floor():
		if velocity.y > 0:
			velocity.y = 0
	else:
		velocity.y += gravity * delta
		handle_fall_animation()

	if Input.is_action_just_pressed("pulo") and is_on_floor() and not is_dashing and not (is_attacking and is_on_floor()):
		anim_sprite.play("pulando")
		jump_buffer_timer.start(jump_anim_delay)

	if not is_dashing:
		handle_attack_input()

	if Input.is_action_just_pressed("defesa") and not is_defending and not is_dashing and not (is_attacking and is_on_floor()):
		start_defense()

	handle_dash_input()

	move_and_slide()
	update_animation()

	if global_position.y > 1000:
		reset_to_start()

func _apply_jump_force() -> void:
	if is_on_floor():
		velocity.y = jump_force

func handle_attack_input() -> void:
	if Input.is_action_just_pressed("ataque_1"):
		selected_attack = 1
	if Input.is_action_just_pressed("ataque_2"):
		selected_attack = 2

	if Input.is_action_just_pressed("ataque_mouse") and not is_attacking:
		start_attack()

func start_attack() -> void:
	is_attacking = true
	# Só para o personagem no chão
	if is_on_floor():
		velocity.x = 0

	var attack_name = ""
	if selected_attack == 1:
		attack_name = "ataque1"
	elif selected_attack == 2:
		attack_name = "ataque2"

	var frames = anim_sprite.sprite_frames
	if frames and frames.has_animation(attack_name):
		frames.set_animation_loop(attack_name, false)
		anim_sprite.play(attack_name)
		var frame_count = frames.get_frame_count(attack_name)
		var anim_speed = frames.get_animation_speed(attack_name)
		var duration = 0.0
		if anim_speed > 0.0:
			duration = float(frame_count) / anim_speed
		else:
			duration = float(frame_count)
		attack_release_timer.start(duration + 0.01)
	else:
		attack_release_timer.start(0.01)

func start_defense() -> void:
	is_defending = true
	velocity.x = 0
	var frames = anim_sprite.sprite_frames
	if frames and frames.has_animation("defendendo"):
		frames.set_animation_loop("defendendo", false)
		anim_sprite.play("defendendo")
		var frame_count = frames.get_frame_count("defendendo")
		var anim_speed = frames.get_animation_speed("defendendo")
		var duration = 0.0
		if anim_speed > 0.0:
			duration = float(frame_count) / anim_speed
		else:
			duration = float(frame_count)
		defense_release_timer.start(duration + 0.01)
	else:
		defense_release_timer.start(0.01)

func handle_dash_input() -> void:
	if not can_dash or is_attacking or is_defending:
		return

	var now = Time.get_ticks_msec() / 1000.0

	if Input.is_action_just_pressed("mv_direita"):
		if (now - last_right_press_time < dash_interval) or (now - last_right_press_time == dash_interval):
			start_dash(1)
		last_right_press_time = now

	if Input.is_action_just_pressed("mv_esquerda"):
		if (now - last_left_press_time < dash_interval) or (now - last_left_press_time == dash_interval):
			start_dash(-1)
		last_left_press_time = now

func start_dash(direction: int) -> void:
	if not can_dash:
		return
	is_dashing = true
	can_dash = false
	facing_direction = direction
	dash_timer.start(dash_duration)
	dash_cooldown_timer.start(dash_cooldown)

	# Escolhe animação dependendo se está no chão ou no ar
	if is_on_floor():
		if anim_sprite.sprite_frames.has_animation("dash"):
			anim_sprite.play("dash")
	else:
		if anim_sprite.sprite_frames.has_animation("dash_ar"):
			anim_sprite.play("dash_ar")

func _end_dash() -> void:
	is_dashing = false

func _reset_dash_cooldown() -> void:
	can_dash = true

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "ataque1" or anim_name == "ataque2":
		is_attacking = false
		if attack_release_timer.time_left > 0.0:
			attack_release_timer.stop()
	if anim_name == "defendendo":
		is_defending = false
		if defense_release_timer.time_left > 0.0:
			defense_release_timer.stop()
	if anim_name == "dash" or anim_name == "dash_ar":
		is_dashing = false

func _release_attack_failsafe() -> void:
	is_attacking = false

func _release_defense_failsafe() -> void:
	is_defending = false

func update_animation() -> void:
	anim_sprite.flip_h = facing_direction == -1

	if is_dead:
		if not anim_sprite.animation == "morrendo":
			anim_sprite.play("morrendo")
		return

	if is_hurt:
		if not anim_sprite.animation == "dano":
			anim_sprite.play("dano")
		return

	# Corrigido: ataque não bloqueia pulo/queda
	if is_attacking:
		if not is_on_floor():
			if velocity.y < 0:
				if not anim_sprite.animation == "pulando":
					anim_sprite.play("pulando")
			else:
				if not anim_sprite.animation == "caindo":
					anim_sprite.play("caindo")
		return

	if is_defending:
		return

	if is_dashing:
		return

	if not is_on_floor():
		if velocity.y < 0:
			if not anim_sprite.animation == "pulando":
				anim_sprite.play("pulando")
		else:
			handle_fall_animation()
		return

	if velocity.x == 0:
		if not anim_sprite.animation == "parado":
			anim_sprite.play("parado")
	else:
		if is_running:
			if not anim_sprite.animation == "correndo":
				anim_sprite.play("correndo")
		else:
			if not anim_sprite.animation == "andando":
				anim_sprite.play("andando")

func handle_fall_animation() -> void:
	if not is_on_floor() and velocity.y > 0:
		if not anim_sprite.animation == "caindo":
			anim_sprite.play("caindo")

func reset_to_start() -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_defending = false
	is_dashing = false
	can_dash = true
	anim_sprite.play("parado")
