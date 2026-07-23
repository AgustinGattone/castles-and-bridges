extends Node2D

# Esta variable guardará la primera base que toquemos
var base_seleccionada: Area2D = null

func _ready() -> void:
	# Recorremos todos los nodos hijos que tenga el Nivel
	for hijo in get_children():
		# Verificamos si el hijo es una Base (comprobando si tiene el método update_label)
		if hijo.has_method("update_label"):
			# Conectamos su señal a nuestra nueva función
			hijo.base_clicked.connect(_on_base_clicked)

# Esta función se ejecuta cada vez que CUALQUIER base es clickeada
func _on_base_clicked(base_clicada: Area2D) -> void:
	# CASO 1: No hay ninguna base seleccionada previamente
	if base_seleccionada == null:
		# Solo podemos seleccionar bases que sean del jugador y tengan más de 1 tropa
		if base_clicada.is_player and base_clicada.current_troops > 1:
			base_seleccionada = base_clicada
			base_seleccionada.set_selected(true)
			
	# CASO 2: Ya teníamos una base seleccionada
	else:
		# Si hacemos clic en la MISMA base, la deseleccionamos
		if base_seleccionada == base_clicada:
			base_seleccionada.set_selected(false)
			base_seleccionada = null
		# Si hacemos clic en OTRA base, ¡Enviamos las tropas!
		else:
			enviar_tropas(base_seleccionada, base_clicada)
			# Limpiamos la selección
			base_seleccionada.set_selected(false)
			base_seleccionada = null

# Lógica matemática de mover tropas (Teletransporte temporal)
func enviar_tropas(origen: Area2D, destino: Area2D) -> void:
	var tropas_a_enviar = origen.current_troops / 2
	
	# Restamos las tropas del origen
	origen.current_troops -= tropas_a_enviar
	origen.update_label()
	
	# -----------------------------------------------------
	# NUEVO: En lugar de sumar al destino, creamos un escuadrón
	# -----------------------------------------------------
	
	# 1. Clonamos la escena del escuadrón
	var nuevo_escuadron = escuadron_escena.instantiate()
	
	# 2. Le pasamos los datos que necesita
	nuevo_escuadron.cantidad_tropas = tropas_a_enviar
	nuevo_escuadron.base_destino = destino
	nuevo_escuadron.es_del_jugador = origen.is_player
	
	# 3. Lo posicionamos exactamente donde está la base de origen
	nuevo_escuadron.global_position = origen.global_position
	
	# 4. Lo añadimos como "hijo" del Nivel para que aparezca en el juego
	add_child(nuevo_escuadron)

# Cargamos el "molde" del escuadrón
var escuadron_escena = preload("res://scenes/escuadron.tscn")
