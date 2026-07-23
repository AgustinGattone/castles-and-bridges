extends Area2D

# --- VARIABLES DEL ESCUADRÓN ---
var cantidad_tropas: int = 0
var base_destino: Area2D = null
var es_del_jugador: bool = false
var velocidad: float = 100.0 # Píxeles por segundo
var destruido: bool = false

@onready var label_tropas: Label = $Label

func _ready() -> void:
	# Al nacer, actualiza el número visual
	actualizar_texto()

func actualizar_texto() -> void:
	label_tropas.text = str(cantidad_tropas)

func eliminar_escuadron() -> void:
	destruido = true
	queue_free() #Borrar escuadron de la pantalla

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
	# 1. Evitar el "doble cálculo" si uno de los dos ya fue destruido en este frame
	if self.destruido or area.get("destruido") == true:
		return
	if "es_del_jugador" in area:
		# 3. Comprobar si es de un equipo distinto
		if area.es_del_jugador != self.es_del_jugador:
			
			# --- RESOLUCIÓN DE COMBATE ---
			
			# Si nosotros tenemos más tropas
			if self.cantidad_tropas > area.cantidad_tropas:
				self.cantidad_tropas -= area.cantidad_tropas
				self.actualizar_texto()
				area.eliminar_escuadron() # El enemigo muere
				
			# Si el enemigo tiene más tropas
			elif self.cantidad_tropas < area.cantidad_tropas:
				area.cantidad_tropas -= self.cantidad_tropas
				area.actualizar_texto()
				self.eliminar_escuadron() # Nosotros morimos

			# Si es un empate exacto
			else:
				self.eliminar_escuadron()
				area.eliminar_escuadron()
