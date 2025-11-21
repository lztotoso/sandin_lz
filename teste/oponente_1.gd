extends CharacterBody2D

var gravity: float = 900.0
var jump_force: float = -400.0
var speed: float = 100.0
var attack_range: float = 100.0

@onready var anim_sprite: AnimatedSprite2D = $Frames_oponente
@onready var raycast: RayCast2D = $RayCast2D
@onready var player: Node2D = get_parent().get_node("Personagem") # ajuste conforme o nome do seu player

var facing_direction := 1

var is_attacking: bool = false
var is_defending: bool = false
var is_dead: bool = false
var is_hurt: bool = false

var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	raycast.enabled = true
	raycast.exclude_parent = true
	# Inicializa apontando para a direita, 30px à frente
	raycast.target_position.x = 30
	raycast.target_position.y = 0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Patrulha
	velocity.x = facing_direction * speed
	
	# Atualiza RayCast na direção atual (sempre aponta para frente)
	raycast.target_position.x = 30 * facing_direction
	raycast.target_position.y = 0
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit := raycast.get_collider()
		# Se colidir com o player à frente, ataca
		if player and hit == player and global_position.distance_to(player.global_position) < attack_range:
			attack(1)
		# Se colidir com qualquer coisa sólida, vira
		else:
			facing_direction *= -1
	
	move_and_slide()
	update_animation()
	
	# Limbo
	if global_position.y > 1000:
		reset_to_start()

func update_animation() -> void:
	anim_sprite.flip_h = facing_direction == -1
	
	if is_dead:
		anim_sprite.play("morrendo")
		return
	
	if is_hurt:
		anim_sprite.play("dano")
		return
	
	if is_attacking:
		return
	
	if is_defending:
		anim_sprite.play("defendendo")
		return
	
	if not is_on_floor():
		if velocity.y < 0:
			anim_sprite.play("pulando")
		else:
			anim_sprite.play("caindo")
		return
	
	if velocity.x == 0:
		anim_sprite.play("parado")
	else:
		anim_sprite.play("andando")

func reset_to_start() -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_defending = false
	anim_sprite.play("parado")

# --- Ações controladas pela IA ---
func attack(type: int) -> void:
	if is_attacking:
		return
	is_attacking = true
	match type:
		1: anim_sprite.play("ataque1")
		2: anim_sprite.play("ataque2")
		3: anim_sprite.play("ataque3")
	await anim_sprite.animation_finished
	is_attacking = false

func defend() -> void:
	is_defending = true
	anim_sprite.play("defendendo")

func hurt() -> void:
	is_hurt = true
	anim_sprite.play("dano")
	await anim_sprite.animation_finished
	is_hurt = false

func die() -> void:
	is_dead = true
	anim_sprite.play("morrendo")

func jump() -> void:
	if is_on_floor():
		velocity.y = jump_force
		anim_sprite.play("pulando")
