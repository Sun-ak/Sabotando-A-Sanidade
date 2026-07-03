extends Control

# Velocidade e configurações da cascata de homens
@export var velocidade_cascata: float = 100.0 
@onready var homens_fundo: TextureRect = $Homens

# Configurações da animação da Logo
@export var velocidade_onda: float = 2.0  # Quão rápido ela balança
@export var amplitude_onda: float = 15.0  # Quantos pixels ela se move para os lados/cima
@onready var logo: TextureRect = $Logo

# Variável para acumular o tempo decorrido
var tempo: float = 0.0
# Guarda a posição original da logo para ela não sair do lugar definitivo
var posicao_original_logo: Vector2

func _ready() -> void:
	if logo:
		posicao_original_logo = logo.position

func _process(delta: float) -> void:
	# 1. Animação da cascata de homens
	if homens_fundo:
		homens_fundo.position.y += velocidade_cascata * delta
		var altura_da_imagem = 720.0
		if homens_fundo.position.y >= 0:
			homens_fundo.position.y -= altura_da_imagem
			
	# 2. Animação de Onda na Logo
	if logo:
		tempo += delta
		
		# Movimento suave para cima e para baixo (Onda Vertical)
		var deslocamento_y = sin(tempo * velocidade_onda) * amplitude_onda
		
		# Se quiser que ela balance levemente para os lados também, descomente a linha abaixo:
		# var deslocamento_x = cos(tempo * (velocidade_onda * 0.5)) * (amplitude_onda * 0.5)
		
		logo.position.y = posicao_original_logo.y + deslocamento_y
