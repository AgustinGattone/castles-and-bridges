extends Area2D

# --- VARIABLES DEL ESCUADRÓN ---
var cantidad_tropas: int = 0
var base_destino: Area2D = null
var velocidad: float = 100.0 # Píxeles por segundo

@onready var label_tropas: Label = $Label

func _ready() -> void:
	# Al nacer, actualiza el número visual
	label_tropas.text = str(cantidad_tropas)

# _process se ejecuta en cada frame (ej. 60 veces por segundo)
func _process(delta: float) -> void:
	# Si no tenemos destino, no hacemos nada
	if base_destino == null:
		return
		
	# 1. Calculamos la dirección hacia la base destino
	var direccion = global_position.direction_to(base_destino.global_position)
	
	# 2. Nos movemos en esa dirección usando la velocidad y el delta (tiempo entre frames)
	global_position += direccion * velocidad * delta
	
	# 3. Comprobamos si ya llegamos (si estamos muy cerca)
	if global_position.distance_to(base_destino.global_position) < 10.0:
		entregar_tropas()

func entregar_tropas() -> void:
	# Le sumamos temporalmente las tropas al destino
	base_destino.current_troops += cantidad_tropas
	base_destino.update_label()
	
	# Destruimos este escuadrón (lo borramos de la memoria)
	queue_free()
