extends Area2D

# --- VARIABLES CONFIGURABLES ---
# @export permite modificar estos valores desde el Inspector de Godot
@export var is_player: bool = false
@export var is_neutral: bool = true
@export var max_troops: int = 50
@export var troops_per_second: int = 1

# --- ESTADO INTERNO ---
var current_troops: int = 10

# Referencia al texto en pantalla
@onready var troop_label: Label = $Label

func _ready() -> void:
	# Actualizamos el texto al iniciar la escena
	update_label()

# Función para actualizar el texto en la pantalla
func update_label() -> void:
	troop_label.text = str(current_troops)

# Esta función la conectaremos al Timer
func _on_generation_timer_timeout() -> void:
	# Las bases neutrales normalmente no generan tropas, solo el jugador y el enemigo
	if not is_neutral and current_troops < max_troops:
		current_troops += troops_per_second
		update_label()
