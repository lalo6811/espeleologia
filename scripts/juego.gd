extends Node2D
## JUEGO PRINCIPAL — Espeleología: cueva real, sin plataformas.
## Construye: la roca (colisión = perfil continuo suelo/techo), el sistema
## de luz (oscuridad azul profunda + conos cálidos + brillos propios),
## al jugador, la cuerda del pozo, el botín, los campamentos y la economía.
## Sin enemigos, como se pidió.

var jugador: Jugador
var hud: HUD
var cuerda: Cuerda
var botines: Array[Botin] = []
var _ya_vendio := false
var _kits_colocados: Array[float] = []
var _tiempo := 0.0

func _ready() -> void:
	# Oscuridad de cueva: azul/púrpura profundo, nunca negro puro.
	var modulador := CanvasModulate.new()
	modulador.color = Color(0.16, 0.17, 0.30)
	add_child(modulador)
	add_child(CuevaDibujo.new())
	_crear_colision_roca()
	_crear_luces_ambiente()
	# Jugador
	jugador = Jugador.new()
	jugador.global_position = Vector2(120, -6)
	add_child(jugador)
	# Cuerda del pozo (flexible, cuelga del anclaje)
	cuerda = Cuerda.new()
	cuerda.ancla = CuevaDatos.ANCLA_POZO
	cuerda.extremo = jugador
	add_child(cuerda)
	_crear_botin()
	# Interfaz
	hud = HUD.new()
	add_child(hud)
	hud.construir(jugador)
	hud.mensaje("Entra a la cueva → • E: interactuar • L: luz • F: comer • T: tienda (en superficie)")
	_crear_ayuda_superficie()

func _crear_colision_roca() -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.name = "Roca"
	var suelo := CollisionPolygon2D.new()
	var pts_s := PackedVector2Array([Vector2(-200, 1500)])
	var techo := CollisionPolygon2D.new()
	var pts_t := PackedVector2Array([Vector2(-200, -1400)])
	var x := -200.0
	while x <= 7300.0:
		pts_s.append(Vector2(x, CuevaDatos.suelo_y(x)))
		pts_t.append(Vector2(x, CuevaDatos.techo_y(x)))
		x += 45.0
	pts_s.append(Vector2(7300, 1500))
	pts_t.append(Vector2(7300, -1400))
	suelo.polygon = pts_s
	techo.polygon = pts_t
	cuerpo.add_child(suelo)
	cuerpo.add_child(techo)
	add_child(cuerpo)

func _luz(pos: Vector2, color: Color, energia: float, escala: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.position = pos
	l.color = color
	l.energy = energia
	l.texture_scale = escala
	l.shadow_enabled = false
	add_child(l)
	return l

func _crear_luces_ambiente() -> void:
	# Sol en superficie y resplandor de la boca
	_luz(Vector2(150, -300), Color(1.0, 0.95, 0.75), 1.5, 6.0)
	_luz(Vector2(560, -40), Color(0.75, 0.8, 1.0), 0.55, 3.0)
	# Resplandor púrpura tenue de la Sala Grande + fogatas de campamentos
	_luz(Vector2(3550, 60), Color(0.5, 0.38, 0.85), 0.5, 7.0)
	for cx in CuevaDatos.CAMPAMENTOS:
		_luz(Vector2(cx + 74, CuevaDatos.suelo_y(cx) - 14), Color(1.0, 0.55, 0.18), 1.5, 2.6)
	_luz(Vector2(224, -14), Color(1.0, 0.55, 0.18), 1.4, 2.4)  # fogata base
	# Hongos luminosos cian repartidos por las galerías
	var x := 560.0
	while x < 7000.0:
		_luz(Vector2(x, CuevaDatos.suelo_y(x) - 12), Color(0.3, 0.95, 0.85), 0.55, 0.8)
		x += randf_range(300.0, 520.0)
	# Brillo propio de la Sala de Cristales
	_luz(Vector2(6750, 560), Color(0.6, 0.45, 1.0), 0.8, 4.5)

func _crear_botin() -> void:
	var lugares: Array = [
		[900.0, "cristal", 25], [1750.0, "fosil", 35], [2450.0, "cristal", 30],
		[3350.0, "fosil", 45], [3800.0, "cristal", 40], [4700.0, "cristal", 35],
		[5300.0, "fosil", 50], [5900.0, "cristal", 55], [6400.0, "fosil", 45],
		[6680.0, "cristal", 60], [6850.0, "cristal", 70], [6980.0, "fosil", 60],
	]
	for l in lugares:
		var b := Botin.new()
		b.tipo = l[1]
		b.valor = l[2]
		b.global_position = Vector2(l[0], CuevaDatos.suelo_y(l[0]) - 2.0)
		add_child(b)
		botines.append(b)

func _crear_ayuda_superficie() -> void:
	var etiqueta := Label.new()
	etiqueta.text = "CAMPAMENTO BASE\nT = tienda   •   La boca de la cueva está a la derecha →"
	etiqueta.position = Vector2(30, -150)
	etiqueta.add_theme_font_size_override("font_size", 20)
	etiqueta.add_theme_color_override("font_color", Color(0.1, 0.12, 0.25))
	add_child(etiqueta)

func _process(delta: float) -> void:
	_tiempo += delta
	# Recoger botín al tocarlo (si cabe en la mochila)
	for b in botines:
		if not b.recogido and jugador.global_position.distance_to(b.global_position) < 42.0:
			if jugador.cristales + jugador.fosiles >= jugador.capacidad:
				hud.mensaje("Mochila llena. Guarda el botín en un campamento (E) o vuelve a vender.")
			else:
				b.recogido = true
				b.visible = false
				if b.tipo == "cristal": jugador.cristales += 1
				else: jugador.fosiles += 1
				hud.mensaje("Recogiste: %s ($%d al vender)" % [b.tipo, b.valor])
	# Venta automática al regresar a la superficie con botín
	var en_superficie := jugador.global_position.x < 430.0
	if en_superficie and (jugador.cristales > 0 or jugador.fosiles > 0):
		var total := 0
		for b in botines:
			if b.recogido: total += b.valor
		jugador.dinero += total + jugador.botin_seguro
		jugador.botin_seguro = 0
		jugador.cristales = 0
		jugador.fosiles = 0
		for b in botines:
			if b.recogido:
				b.recogido = false
				b.visible = true
		if total > 0 and not _ya_vendio:
			hud.mensaje("¡Vendiste tu botín por $%d! Compra equipo con T y vuelve a bajar." % total)
		_ya_vendio = true
	elif not en_superficie:
		_ya_vendio = false
	# Agotamiento: sin energía o sin comida, toca descansar en campamento
	if jugador.energia <= 0.0 or jugador.hambre <= 0.0:
		hud.mensaje("Estás agotado: descansa en un campamento (E) o come una ración (F).")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var x := jugador.global_position.x
	match event.keycode:
		KEY_E:
			# ¿Cerca del anclaje del pozo? Agarrar / soltar la cuerda
			if jugador.global_position.distance_to(CuevaDatos.ANCLA_POZO + Vector2(0, 330)) < 520.0 and x > 4150.0 and x < 4550.0:
				jugador.agarrado_cuerda = not jugador.agarrado_cuerda
				cuerda.activa = jugador.agarrado_cuerda
				if jugador.agarrado_cuerda:
					jugador.longitud_cuerda = clampf(jugador.global_position.distance_to(CuevaDatos.ANCLA_POZO), 30.0, 430.0)
					hud.mensaje("En la cuerda: W/S subir-bajar el rappel, A/D balancearte para impulsarte.")
				else:
					hud.mensaje("Soltaste la cuerda.")
				return
			# ¿Campamento? Descansar, cocinar y guardar el botín
			var destinos: Array = []
			destinos.append_array(CuevaDatos.CAMPAMENTOS)
			destinos.append_array(_kits_colocados)
			for cx in destinos:
				if absf(x - cx) < 95.0:
					jugador.energia = 100.0
					jugador.hambre = minf(100.0, jugador.hambre + 25.0)
					var guardado := 0
					for b in botines:
						if b.recogido: guardado += b.valor
					jugador.botin_seguro += guardado
					jugador.cristales = 0
					jugador.fosiles = 0
					for b in botines:
						if b.recogido:
							b.recogido = false
							b.visible = false
							b.global_position = Vector2(-9999, -9999)
					hud.mensaje("Descansaste. Botín guardado a salvo: $%d. Energía al 100%%." % guardado)
					return
			hud.mensaje("No hay nada que usar aquí. E sirve en: anclaje del pozo y campamentos.")
		KEY_C:
			# Montar campamento propio en suelo plano con un kit
			if jugador.kits > 0 and absf(CuevaDatos.pendiente(x)) < 0.22 and CuevaDatos.altura_libre(x) > 130.0:
				jugador.kits -= 1
				_kits_colocados.append(x)
				var dibujo := get_child(1) as CuevaDibujo
				hud.mensaje("Montaste tu campamento en x=%d. Descansa con E." % int(x))
				_luz(Vector2(x + 40, CuevaDatos.suelo_y(x) - 12), Color(1.0, 0.55, 0.18), 1.3, 2.2)
			else:
				hud.mensaje("Para acampar necesitas un kit y un suelo plano y con techo alto.")
