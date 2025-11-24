extends Node2D

@export var textura_A : Texture2D    # chão normal
@export var textura_B : Texture2D    # chão com árvore
@export var largura_tile := 256       # ajuste pro tamanho da sua imagem
@export var repeticoes := 20          # quantidade de blocos de padrão

func _ready():
	var x = 0.0

	for i in range(repeticoes):

		# --- 3x chão normal (A A A) ---
		for j in range(3):
			var spriteA = Sprite2D.new()
			spriteA.texture = textura_A
			spriteA.position = Vector2(x, 0)
			add_child(spriteA)
			x += largura_tile

		# --- 1x chão com árvore (B) ---
		var spriteB = Sprite2D.new()
		spriteB.texture = textura_B
		spriteB.position = Vector2(x, 0)
		add_child(spriteB)
		x += largura_tile
