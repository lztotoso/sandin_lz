extends CharacterBody2D

var speed: float = 200.0
var run_speed: float = 350.0
var jump_force: float = -400.0
var gravity: float = 900.0

@onready var anim_sprite: AnimatedSprite2D = $Frames_personagem

var facing_direction := 1

var is_running: bool = false
var is_attacking: bool = false
var is_defending: bool = false
var is_dead: bool = false
var is_hurt: bool = false

var jump_anim_delay: float = 0.1
var jump_buffer_timer: Timer

var start_position: Vector2   # posição inicial para respawn

func _ready() -> void:
	jump_buffer_timer = Timer.new()
	jump_buffer_timer.one_shot = true
	add_child(jump_buffer_timer)
	jump_buffer_timer.timeout.connect(_apply_jump_force)
	
	# Guardar posição inicial
	start_position = global_position

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("mv_direita"):
		direction.x += 1
		facing_direction = 1
	elif Input.is_action_pressed("mv_esquerda"):
		direction.x -= 1
		facing_direction = -1

	is_running = Input.is_action_pressed("correr")
	direction = direction.normalized()
	
	if is_running:
		velocity.x = direction.x * run_speed
	else:
		velocity.x = direction.x * speed
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Pulo
	if Input.is_action_just_pressed("pulo") and is_on_floor():
		anim_sprite.play("pulando")
		jump_buffer_timer.start(jump_anim_delay)
	
	# Ataques
	if Input.is_action_just_pressed("ataque1"):
		is_attacking = true
		anim_sprite.play("ataque1")
	elif Input.is_action_just_pressed("ataque2"):
		is_attacking = true
		anim_sprite.play("ataque2")
	elif Input.is_action_just_pressed("ataque3"):
		is_attacking = true
		anim_sprite.play("ataque3")
	
	is_defending = Input.is_action_pressed("defender")
	
	move_and_slide()
	update_animation()
	
	# --- Verificação do limbo ---
	if global_position.y > 1000: # ajuste o valor conforme seu cenário
		reset_to_start()

func _apply_jump_force() -> void:
	if is_on_floor():
		velocity.y = jump_force

func update_animation() -> void:
	anim_sprite.flip_h = facing_direction == -1
	
	if is_dead:
		if anim_sprite.animation == "morrendo":
			pass
		else:
			anim_sprite.play("morrendo")
		return
	
	if is_hurt:
		if anim_sprite.animation == "dano":
			pass
		else:
			anim_sprite.play("dano")
		return
	
	if is_attacking:
		return
	
	if is_defending:
		if anim_sprite.animation == "defendendo":
			pass
		else:
			anim_sprite.play("defendendo")
		return
	
	if not is_on_floor():
		if velocity.y < 0:
			if anim_sprite.animation == "pulando":
				pass
			else:
				anim_sprite.play("pulando")
		else:
			if anim_sprite.animation == "caindo":
				pass
			else:
				anim_sprite.play("caindo")
		return
	
	if velocity.x == 0:
		if anim_sprite.animation == "parado":
			pass
		else:
			anim_sprite.play("parado")
	else:
		if is_running:
			if anim_sprite.animation == "correndo":
				pass
			else:
				anim_sprite.play("correndo")
		else:
			if anim_sprite.animation == "andando":
				pass
			else:
				anim_sprite.play("andando")

# Função para resetar posição ao cair no limbo
func reset_to_start() -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_defending = false
	anim_sprite.play("parado")
