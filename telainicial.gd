extends Control

# Configurações do fundo e logo
@export var velocidade_cascata: float = 100.0 
@onready var homens_fundo: TextureRect = $Homens
@export var velocidade_onda: float = 2.0  
@export var amplitude_onda: float = 15.0  
@onready var logo: TextureRect = $Logo

# Novos nós para a transição
@onready var start_button: TextureButton = $Start
@onready var fade_tela: ColorRect = $FadeTela

var tempo: float = 0.0
var posicao_original_logo: Vector2
var transicao_iniciada: bool = false

func _ready() -> void:
	if logo:
		posicao_original_logo = logo.position
	
	# Garante que o fade comece invisível
	if fade_tela:
		fade_tela.modulate.a = 0.0
		
	# Conecta o clique do botão via código para garantir que funcione
	if start_button:
		start_button.pressed.connect(_on_start_pressed)

func _process(delta: float) -> void:
	# Movimento dos homens
	if homens_fundo:
		homens_fundo.position.y += velocidade_cascata * delta
		var altura_da_imagem = 720.0
		if homens_fundo.position.y >= 0:
			homens_fundo.position.y -= altura_da_imagem
			
	# Onda na logo
	if logo:
		tempo += delta
		var _deslocamento_y = sin(tempo * velocidade_onda) * amplitude_onda
		logo.position.y = posicao_original_logo.y + _deslocamento_y

# A MÁGICA ACONTECE AQUI
@onready var som_quebra: AudioStreamPlayer2D = $SomQuebra
func _on_start_pressed() -> void:
	if transicao_iniciada:
		return
	transicao_iniciada = true
	
	start_button.disabled = true
	
	# 1. Tremida Longa por 2 segundos (40 repetições de 0.05s = 2 segundos)
	var tween_shake = create_tween()
	var pos_original_botao = start_button.position
	for i in range(40):
		var direcao_aleatoria = Vector2(randf_range(-10, 10), randf_range(-5, 5))
		tween_shake.tween_property(start_button, "position", pos_original_botao + direcao_aleatoria, 0.05)
	
	# Garante que o botão volte ao centro antes de quebrar
	tween_shake.tween_property(start_button, "position", pos_original_botao, 0.05)
	await tween_shake.finished
	
	# 2. Efeito de Quebra (Toca o som e troca o sprite)
	if som_quebra:
		som_quebra.play()
	start_button.texture_normal = load("res://game sprites menu/broken start.png")
	
	# Pequena pausa dramática de 0.3s após o estalo da quebra
	await get_tree().create_timer(0.3).timeout
	
	# 3. O fundo preto aparece LENTAMENTE (Levará 2.0 segundos para cobrir tudo)
	var tween_fade = create_tween()
	tween_fade.tween_property(fade_tela, "modulate:a", 1.0, 2.0)
	await tween_fade.finished
	
	# 4. Transiciona para o quarto enquanto a tela está 100% escura
	# Com base nos seus prints, o caminho provável da cena é este:
	get_tree().change_scene_to_file("res://levels/bedroom/bedroom.tscn")
