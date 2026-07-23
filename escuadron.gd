extends Area2D

# --- VARIABLES DEL ESCUADRÓN ---
var cantidad_tropas: int = 0
var base_destino: Area2D = null
var es_del_jugador: bool = false
var velocidad: float = 100.0 # Píxeles por segundo
var destruido: bool = false

# --- ESTADOS DE COMBATE ---
var en_combate: bool = false
var enemigo_actual: Area2D = null
var tropas_float: float = 0.0
var velocidad_combate: float = 15.0 # Tropas que mueren por segundo

@onready var label_tropas: Label = $Label

func _ready() -> void:
	# Sincronizamos la variable de daño con la cantidad real
	tropas_float = float(cantidad_tropas)
	# Al nacer, actualiza el número visual
	actualizar_texto()

func actualizar_texto() -> void:
	label_tropas.text = str(cantidad_tropas)

func eliminar_escuadron() -> void:
	destruido = true
	queue_free() #Borrar escuadron de la pantalla

# _process se ejecuta en cada frame (ej. 60 veces por segundo)
func _process(delta: float) -> void:
	# --- ESTADO 1: PELEANDO ---
	if en_combate:
		# 1. Si el enemigo murió, terminamos el combate.
		if not is_instance_valid(enemigo_actual) or enemigo_actual.destruido:
			en_combate = false
			enemigo_actual = null
			return
		# 2. Calculo daño recibido
		tropas_float -= velocidad_combate * delta
		cantidad_tropas = int(tropas_float)
		actualizar_texto()
		
		# 3. Si llegamos a 0, muere el jugador.
		if cantidad_tropas <= 0:
			eliminar_escuadron()
		return
	# --- ESTADO 2: EN MOVIMIENTO ---
	if base_destino == null:
		return
	
	var direccion = global_position.direction_to(base_destino.global_position)
	global_position += direccion * velocidad * delta
	
	if global_position.distance_to(base_destino.global_position) < 10.0:
		entregar_tropas()

func entregar_tropas() -> void:
	# Si el escuadron y la base son del mismo equipo (Refuerzo)
	if base_destino.is_player == self.es_del_jugador and not base_destino.is_neutral:
		base_destino.current_troops += cantidad_tropas
	# Si son de equipos distintos (Ataque)
	else:
		base_destino.current_troops -= cantidad_tropas
	# Ganamos el combate
		if base_destino.current_troops < 0:
			#Capturamos la base.
			base_destino.current_troops = abs(base_destino.current_troops)
			base_destino.is_player = self.es_del_jugador
			base_destino.is_neutral = false
			
			#Actualizamos la base segun el color de su nuevo dueño
			base_destino.actualizar_color_dueno()
	base_destino.update_label()
	
	# Destruimos este escuadrón (lo borramos de la memoria)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if self.destruido or area.get("destruido") == true:
		return
		
	if "es_del_jugador" in area and area.es_del_jugador != self.es_del_jugador:
		# Peleamos la batalla
		en_combate = true
		enemigo_actual = area 
