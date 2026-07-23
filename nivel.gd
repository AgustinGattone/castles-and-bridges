extends Node2D

# Esta variable guardará la primera base que toquemos
var base_seleccionada: Area2D = null
var tiempo_decision_ia: float = 3.0
var tiempo_actual_ia: float = 0.0
var juego_terminado: bool = false

#Referencias a la UI
@onready var slider_tropas: HSlider = $UI/SliderTropas
@onready var label_porcentaje: Label = $UI/LabelPorcentaje
@onready var label_game_over: Label = $UI/LabelGameOver

func _ready() -> void:
	# Recorremos todos los nodos hijos que tenga el Nivel
	for hijo in get_children():
		# Verificamos si el hijo es una Base (comprobando si tiene el método update_label)
		if hijo.has_method("update_label"):
			# Conectamos su señal a nuestra nueva función
			hijo.base_clicked.connect(_on_base_clicked)
		# Conectamos la señal de la barra para que el texto cambie al moverla
	slider_tropas.value_changed.connect(_on_slider_changed)
	_on_slider_changed(slider_tropas.value) # Actualizamos el texto al iniciar

# Nueva función que se ejecuta al mover la barra
func _on_slider_changed(valor: float) -> void:
	label_porcentaje.text = str(valor) + "%"

func _process(delta: float) -> void:
	# Si el juego termina, frena la IA y el nivel.
	if juego_terminado:
		return
	
	tiempo_actual_ia += delta
	
	#Cada 3 segundos, Actua la IA
	if tiempo_actual_ia >= tiempo_decision_ia:
		ejecutar_ia_enemiga()
		tiempo_actual_ia = 0.0 #Reinicio del Reloj
	# Escaneamos el juego en cada frame
		revisar_condiciones()

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
			# Convertimos el valor del slider (10 a 100) en decimal (0.1 a 1.0)
			var porcentaje_elegido = slider_tropas.value / 100.0
			enviar_tropas(base_seleccionada, base_clicada, porcentaje_elegido)
			
			base_seleccionada.set_selected(false)
			base_seleccionada = null

# Lógica matemática de mover tropas 
func enviar_tropas(origen: Area2D, destino: Area2D, porcentaje: float = 0.5) -> void:
	# Calculamos las tropas multiplicando por el porcentaje (ej. 100 * 0.75)
	var tropas_a_enviar = int(origen.current_troops * porcentaje)
	
	# Si intentamos enviar menos de 1 tropa, cancelamos para evitar errores
	if tropas_a_enviar <= 0:
		return
		
	# Restamos las tropas del origen
	origen.current_troops -= tropas_a_enviar
	origen.update_label()
	
	# Instanciamos el escuadrón
	var nuevo_escuadron = escuadron_escena.instantiate()
	nuevo_escuadron.cantidad_tropas = tropas_a_enviar
	nuevo_escuadron.base_destino = destino
	nuevo_escuadron.es_del_jugador = origen.is_player
	nuevo_escuadron.global_position = origen.global_position
	
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

# Final del Juego
func revisar_condiciones() -> void:
	var bases_jugador = 0
	var bases_enemigo = 0
	var escuadrones_jugador = 0
	var escuadrones_enemigo = 0
	
	# Recuento final
	for hijo in get_children():
		if hijo.has_method("update_label"): # Si es una Base
			if hijo.is_player:
				bases_jugador += 1
			elif not hijo.is_neutral:
				bases_enemigo += 1
		elif "es_del_jugador" in hijo: # Si es un escuadron
			if hijo.es_del_jugador:
				escuadrones_jugador += 1
			else:
				escuadrones_enemigo += 1
	#Evaluacion final de los resultados
	if bases_jugador == 0 and escuadrones_jugador == 0:
		finalizar_juego("¡DERROTA!")
	elif bases_enemigo == 0 and escuadrones_enemigo == 0:
		finalizar_juego("¡VICTORIA!")

func finalizar_juego(mensaje: String) -> void:
	juego_terminado = true
	label_game_over.text = mensaje
	get_tree().paused = true
