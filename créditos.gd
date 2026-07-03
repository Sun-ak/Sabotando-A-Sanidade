extends Control

const MUSIC_PATH := "res://sound_effects/credits_song.mp3"
const CONCEPT_ART_DIR := "res://assets/concept_art/"

@onready var music: AudioStreamPlayer = $Music
@onready var arts_container: HBoxContainer = $ScrollContainer/Conteudo/ArtsContainer

func _ready() -> void:
	_tocar_musica()
	_carregar_concept_arts()

func _tocar_musica() -> void:
	if ResourceLoader.exists(MUSIC_PATH):
		music.stream = load(MUSIC_PATH)
		music.play()
	else:
		push_warning("Música dos créditos não encontrada em: %s" % MUSIC_PATH)

func _carregar_concept_arts() -> void:
	var dir := DirAccess.open(CONCEPT_ART_DIR)
	if dir == null:
		push_warning("Pasta de concept art não encontrada: %s" % CONCEPT_ART_DIR)
		return

	dir.list_dir_begin()
	var nome_arquivo := dir.get_next()
	while nome_arquivo != "":
		var extensao := nome_arquivo.get_extension().to_lower()
		if not dir.current_is_dir() and extensao in ["png", "jpg", "jpeg"]:
			var textura: Texture2D = load(CONCEPT_ART_DIR + nome_arquivo)
			if textura:
				var rect := TextureRect.new()
				rect.texture = textura
				rect.custom_minimum_size = Vector2(320, 180)
				rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
				rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				arts_container.add_child(rect)
		nome_arquivo = dir.get_next()
	dir.list_dir_end()

func _on_voltar_pressed() -> void:
	music.stop()
	get_tree().change_scene_to_file("res://telainicial.tscn")
