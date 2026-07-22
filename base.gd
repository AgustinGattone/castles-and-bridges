extends Area2D

# --- VARIABLES CONFIGURABLES ---
# @export permite modificar estos valores desde el Inspector de Godot
@export var is_player: bool = false
@export var is_neutral: bool = true
@export var max_troops: int = 50
@export var troops_per_second: int = 1

# --- ESTADO INTERNO ---
@export var current_troops: int = 15
var is_selected: bool = false # 

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

# Función para activar o desactivar la selección
func set_selected(selected: bool) -> void:
	is_selected = selected
	if is_selected:
		# Cambiamos el color de la base a un tono más brillante o diferente (ej. verde/azulado)
		modulate = Color(0.5, 1.5, 2.0) 
	else:
		# Restauramos el color original
		modulate = Color(1.0, 1.0, 1.0)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# Verificamos si el evento es un clic del mouse, si es el botón izquierdo, y si acaba de ser presionado
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Solo deberíamos poder seleccionar bases que nos pertenecen
		if is_player:
			# Alternamos el estado de selección
			set_selected(!is_selected)
