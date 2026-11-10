class_name HUD
extends CanvasLayer
## Interfaz como en la imagen de referencia: iconos circulares arriba a la
## izquierda (hambre, energía, batería, aire), minimapa circular abajo a la
## derecha con profundidad, y panel de tienda en el campamento base.

var jugador: Jugador
var barra_hambre: ProgressBar
var barra_energia: ProgressBar
var barra_bateria: ProgressBar
var barra_aire: ProgressBar
var etiqueta_zona: Label
var etiqueta_info: Label
var etiqueta_mensaje: Label
var etiqueta_profundidad: Label
var panel_tienda: PanelContainer
var minimapa: Minimapa

func _barra(texto: String, y: float, color: Color) -> ProgressBar:
	var icono := Label.new()
	icono.text = texto
	icono.position = Vector2(16, y)
	icono.add_theme_font_size_override("font_size", 22)
	add_child(icono)
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = 100
	b.value = 100
	b.position = Vector2(52, y + 4)
	b.size = Vector2(150, 16)
	b.show_percentage = false
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.corner_radius_top_left = 8
	estilo.corner_radius_top_right = 8
	estilo.corner_radius_bottom_left = 8
	estilo.corner_radius_bottom_right = 8
	b.add_theme_stylebox_override("fill", estilo)
	add_child(b)
	return b

func construir(j: Jugador) -> void:
	jugador = j
	barra_hambre = _barra("🍖", 14, Color(0.95, 0.5, 0.2))
	barra_energia = _barra("⚡", 46, Color(0.95, 0.85, 0.25))
	barra_bateria = _barra("🔦", 78, Color(0.5, 0.85, 1.0))
	barra_aire = _barra("🫧", 110, Color(0.45, 0.9, 1.0))
	etiqueta_zona = Label.new()
	etiqueta_zona.position = Vector2(16, 140)
	etiqueta_zona.add_theme_font_size_override("font_size", 19)
	add_child(etiqueta_zona)
	etiqueta_info = Label.new()
	etiqueta_info.position = Vector2(16, 168)
	etiqueta_info.add_theme_font_size_override("font_size", 15)
	add_child(etiqueta_info)
	etiqueta_mensaje = Label.new()
	etiqueta_mensaje.position = Vector2(330, 22)
	etiqueta_mensaje.size = Vector2(640, 30)
	etiqueta_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_mensaje.add_theme_font_size_override("font_size", 19)
	add_child(etiqueta_mensaje)
	minimapa = Minimapa.new()
	minimapa.jugador = j
	minimapa.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	minimapa.position = Vector2(-186, -196)
	add_child(minimapa)
	etiqueta_profundidad = Label.new()
	etiqueta_profundidad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	etiqueta_profundidad.position = Vector2(-186, -28)
	etiqueta_profundidad.size = Vector2(168, 22)
	etiqueta_profundidad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_profundidad.add_theme_font_size_override("font_size", 14)
	add_child(etiqueta_profundidad)
	_construir_tienda()

func _construir_tienda() -> void:
	panel_tienda = PanelContainer.new()
	panel_tienda.position = Vector2(430, 110)
	panel_tienda.size = Vector2(420, 430)
	panel_tienda.visible = false
	var caja := VBoxContainer.new()
	panel_tienda.add_child(caja)
	var titulo := Label.new()
	titulo.text = "TIENDA — Campamento base (T para cerrar)"
	caja.add_child(titulo)
	var items: Array = [
		["Linterna de mano potente — $150", "linterna", 150],
		["Lámpara frontal de casco — $300", "frontal", 300],
		["Mochila grande (+8 espacio) — $200", "mochila", 200],
		["Piolet — $120", "piolet", 120],
		["Batería — $30", "bateria", 30],
		["Ración de comida — $25", "racion", 25],
		["Kit de campamento — $80", "kit", 80],
	]
	for it in items:
		var boton := Button.new()
		boton.text = it[0]
		boton.pressed.connect(_comprar.bind(it[1], it[2]))
		caja.add_child(boton)
	var nota := Label.new()
	nota.text = "Vende tu botín automáticamente al volver\na la tienda del campamento base."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(nota)
	add_child(panel_tienda)

func _comprar(clave: String, precio: int) -> void:
	if jugador.dinero < precio:
		mensaje("No te alcanza el dinero.")
		return
	match clave:
		"linterna":
			if jugador.tiene_linterna: mensaje("Ya tienes linterna."); return
			jugador.tiene_linterna = true
		"frontal":
			if jugador.tiene_frontal: mensaje("Ya tienes frontal."); return
			jugador.tiene_frontal = true
			jugador.linterna_en_mano = false
		"mochila":
			if jugador.tiene_mochila_grande: mensaje("Ya tienes mochila grande."); return
			jugador.tiene_mochila_grande = true
			jugador.capacidad += 8
		"piolet":
			if jugador.tiene_piolet: mensaje("Ya tienes piolet."); return
			jugador.tiene_piolet = true
		"bateria": jugador.baterias_extra += 1
		"racion": jugador.raciones += 1
		"kit": jugador.kits += 1
	jugador.dinero -= precio
	mensaje("Comprado. ¡Buena exploración!")

func mensaje(texto: String) -> void:
	etiqueta_mensaje.text = texto

func _process(_delta: float) -> void:
	if jugador == null:
		return
	barra_hambre.value = jugador.hambre
	barra_energia.value = jugador.energia
	barra_bateria.value = jugador.bateria
	barra_aire.value = jugador.aire
	barra_aire.visible = jugador.modo == "nado"
	etiqueta_zona.text = CuevaDatos.zona(jugador.global_position.x)
	etiqueta_info.text = "💰 $%d   🎒 %d/%d   💎 %d   🦴 %d   🔋x%d  🍖x%d  ⛺x%d" % [
		jugador.dinero, jugador.cristales + jugador.fosiles, jugador.capacidad,
		jugador.cristales, jugador.fosiles, jugador.baterias_extra, jugador.raciones, jugador.kits]
	var prof := maxi(0, int(jugador.global_position.y / 9.0))
	etiqueta_profundidad.text = "Profundidad: %dm" % prof
	if Input.is_key_pressed(KEY_T) and jugador.global_position.x < 430.0:
		panel_tienda.visible = true
	elif Input.is_key_pressed(KEY_ESCAPE):
		panel_tienda.visible = false
