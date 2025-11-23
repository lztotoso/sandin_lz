extends CharacterBody2D

# ==========================================================
# ---------------------- CONFIGURAÇÕES ----------------------
# ==========================================================

@export var gravity := 900.0

@export var walk_speed := 40.0          # velocidade padrão
@export var chase_speed := 90.0         # velocidade correndo
@export var attack_distance := 35.0

@export var max_health := 60
var health := max_health

# Dano dos ataques
@export var attack1_damage := 10
@export var attack2_damage := 18
@export var attack3_damage := 25

# Chance de cada ataque acontecer (weights)
@export var attack1_weight := 60
@export var attack2_weight := 30
@export var attack3_weight := 10

# Patrulha automática
@export var patrol_left : Vector2
@export var patrol_right : Vector2
var patrol_dir := 1  # 1 = direita | -1 = esquerda

# Estados
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DIE }
var state: State = State.PATROL

# Controle interno
var player = null
var is_attacking := false
var current_damage := 0
var attack_mode := 1


# ==========================================================
# -------------------------- READY --------------------------
# ==========================================================

func _ready():
	$VisionArea.body_entered.connect(_on_vision_enter)
	$AttackArea.body_entered.connect(_on_attack_area_enter)
	$AttackCooldown.timeout.connect(_on_attack_cooldown)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)


# ==========================================================
# -------------------- PHYSICS PROCESS ----------------------
# ==========================================================

func _physics_process(delta):

	# ----- Gravidade -----
	if not is_on_floor():
		velocity.y += gravity * delta

	# ----- Máquina de Estados -----
	match state:
		State.IDLE:    _state_idle()
		State.PATROL:  _state_patrol()
		State.CHASE:   _state_chase()
		State.ATTACK:  _state_attack()
		State.HURT:    _state_hurt()
		State.DIE:     return

	move_and_slide()

	# ----- Ajuste de direção visual (sprite vira junto com movimento) -----
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false   # Direita
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true    # Esquerda


# ==========================================================
# ------------------------- ESTADOS -------------------------
# ==========================================================

func _state_idle():
	$AnimatedSprite2D.play("idle")
	velocity.x = 0

	if player:
		state = State.CHASE


func _state_patrol():
	$AnimatedSprite2D.play("walk")

	# Movimento entre dois pontos
	velocity.x = walk_speed * patrol_dir

	# Mudança de direção
	if patrol_dir == 1 and global_position.x >= patrol_right.x:
		patrol_dir = -1
	elif patrol_dir == -1 and global_position.x <= patrol_left.x:
		patrol_dir = 1

	if player:
		state = State.CHASE


func _state_chase():
	if not player:
		state = State.PATROL
		return

	# Distância até o jogador
	var dist := global_position.distance_to(player.global_position)
	if dist <= attack_distance:
		state = State.ATTACK
		return

	# Corre em direção ao player
	var dir = (player.global_position - global_position).normalized()
	velocity.x = dir.x * chase_speed

	$AnimatedSprite2D.play("run")


func _state_attack():
	velocity.x = 0

	if not is_attacking:
		_start_attack()


func _state_hurt():
	velocity.x = 0
	$AnimatedSprite2D.play("hurt")


# ==========================================================
# ------------------------- ATAQUE --------------------------
# ==========================================================

func _start_attack():
	if not $AttackCooldown.is_stopped():
		state = State.CHASE
		return

	is_attacking = true
	velocity.x = 0

	# Escolher ataque
	attack_mode = _choose_attack()

	match attack_mode:
		1:
			$AnimatedSprite2D.play("attack1")
			current_damage = attack1_damage
		2:
			$AnimatedSprite2D.play("attack2")
			current_damage = attack2_damage
		3:
			$AnimatedSprite2D.play("attack3")
			current_damage = attack3_damage

	$AttackCooldown.start()


func _choose_attack() -> int:
	var total = attack1_weight + attack2_weight + attack3_weight
	var r = randi() % total

	if r < attack1_weight:
		return 1
	elif r < attack1_weight + attack2_weight:
		return 2
	return 3


func _on_attack_area_enter(body):
	if is_attacking and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(current_damage)


# ==========================================================
# -------------------- DANO E MORTE -------------------------
# ==========================================================

func take_damage(amount: int):
	if state == State.DIE:
		return

	health -= amount

	if health <= 0:
		_die()
		return

	state = State.HURT
	await get_tree().create_timer(0.25).timeout
	state = State.CHASE


func _die():
	state = State.DIE
	velocity = Vector2.ZERO

	$AnimatedSprite2D.play("die")
	$CollisionShape2D.disabled = true
	$VisionArea.queue_free()
	$AttackArea.queue_free()


# ==========================================================
# ------------------------- SINAIS --------------------------
# ==========================================================

func _on_vision_enter(body):
	if body.is_in_group("player"):
		player = body


func _on_attack_cooldown():
	is_attacking = false
	if player:
		state = State.CHASE
	else:
		state = State.PATROL


func _on_animation_finished():
	if $AnimatedSprite2D.animation.begins_with("attack"):
		is_attacking = false
		state = State.CHASE
