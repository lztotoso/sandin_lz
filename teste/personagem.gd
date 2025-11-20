extends CharacterBody2D

# Velocidade horizontal
var speed: float = 200.0
# Força do pulo
var jump_force: float = -400.0
# Gravidade
var gravity: float = 900.0

# Referência ao AnimatedSprite2D
@onready var anim_sprite: AnimatedSprite2D = $Frames_personagem

# Direção atual do personagem (1 = direita, -1 = esquerda)
var facing_direction := 1

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	# Movimento horizontal
	if Input.is_action_pressed("mv_direita"):
		direction.x += 1
		facing_direction = 1
	elif Input.is_action_pressed("mv_esquerda"):
		direction.x -= 1
		facing_direction = -1

	# Normaliza direção horizontal
	direction = direction.normalized()
	
	# Aplica velocidade horizontal
	velocity.x = direction.x * speed
	
	# Aplica gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Pulo
	if Input.is_action_just_pressed("pulo") and is_on_floor():
		velocity.y = jump_force
	
	# Move personagem
	move_and_slide()

	# Atualiza animação
	update_animation()

func update_animation() -> void:
	# Inverte sprite horizontalmente conforme direção
	anim_sprite.flip_h = facing_direction == -1

	if not is_on_floor():
		if velocity.y < 0:
			anim_sprite.play("jump")
		else:
			anim_sprite.play("fall")
	elif velocity.x != 0:
		anim_sprite.play("run")
	else:
		anim_sprite.play("parado")
