extends Node2D

# Esta variable guardará la primera base que toquemos
var base_seleccionada: Area2D = null
var tiempo_decision_ia: float = 3.0
var tiempo_actual_ia: float = 0.0

func _ready() -> void:
	# Recorremos todos los nodos hijos que tenga el Nivel
	for hijo in get_children():
		# Verificamos si el hijo es una Base (comprobando si tiene el método update_label)
		if hijo.has_method("update_label"):
			# Conectamos su señal a nuestra nueva función
			hijo.base_clicked.connect(_on_base_clicked)

func _process(delta: float) -> void:
	tiempo_actual_ia += delta
	
	#Cada 3 segundos, Actua la IA
	if tiempo_actual_ia >= tiempo_decision_ia:
		ejecutar_ia_enemiga()
		tiempo_actual_ia = 0.0 #Reinicio del Reloj

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

func ejecutar_ia_enemiga() -> void:
	# 1. Agrupar las bases según su dueño
	var bases_enemigas = [] # (Las de la IA)
	var posibles_objetivos = [] # (Jugador y Neutrales)
	
	for hijo in get_children():
		if hijo.has_method("update_label"): # Asegurarnos que es una base
			if not hijo.is_player and not hijo.is_neutral:
				bases_enemigas.append(hijo)
			else:
				posibles_objetivos.append(hijo)
				
	# Si la IA no tiene bases, o no hay objetivos, no hace nada
	if bases_enemigas.size() == 0 or posibles_objetivos.size() == 0:
		return
		
	# 2. Elegir de DÓNDE atacar (La base de la IA con más tropas)
	var base_origen_ia = bases_enemigas[0]
	for base in bases_enemigas:
		if base.current_troops > base_origen_ia.current_troops:
			base_origen_ia = base
			
	# Si su mejor base tiene muy pocas tropas (ej. menos de 15), decide no atacar y ahorrar
	if base_origen_ia.current_troops < 15:
		return
		
	# 3. Elegir a DÓNDE atacar (El objetivo con MENOS tropas)
	var base_objetivo_ia = posibles_objetivos[0]
	for objetivo in posibles_objetivos:
		if objetivo.current_troops < base_objetivo_ia.current_troops:
			base_objetivo_ia = objetivo
			
	# 4. ¡Ejecutar el ataque! Reutilizamos tu función de enviar tropas
	enviar_tropas(base_origen_ia, base_objetivo_ia)
