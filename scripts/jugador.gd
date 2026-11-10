class_name Jugador
extends CharacterBody2D
## Espeleólogo HUMANO en vector procedural (sin pixel art, sin palos):
## extremidades con volumen (muslo/pantorrilla, brazo/antebrazo) resueltas
## con IK de dos huesos, torso con chaqueta, cabeza de perfil con casco y
## frontal, mochila con petate, cuerda enrollada y piolet.
## Modos: caminar, correr, arrastrarse, escalar pendiente, nadar/bucear,
## rappel con balanceo. Supervivencia: hambre, energía, batería, aire.

signal estado_cambiado

var modo := "pie"  # pie | arrastre | nado | rappel | escala
var direccion := 1.0
var fase := 0.0  # fase del ciclo de marcha/nado
var hambre := 100.0
var energia := 100.0
var bateria := 100.0
var aire := 100.0
var dinero := 40
var cristales := 0
var fosiles := 0
var capacidad := 8
var botin_seguro := 0  # valor ya guardado en campamentos
var tiene_linterna := false
var tiene_frontal := false
var tiene_piolet := false
var tiene_mochila_grande := false
var baterias_extra := 1
var raciones := 2
var kits := 1
var luz_encendida := true
var linterna_en_mano := true
var en_el_agua := false
var agarrado_cuerda := false
var longitud_cuerda := 60.0
var angulo_balanceo := 0.0
var vel_balanceo := 0.0
var _forma: CollisionShape2D
var _camara: Camera2D
var _luz_cono: PointLight2D
var _luz_punto: PointLight2D
var _tex_cono: Texture2D
var _tiempo := 0.0

const GRAVEDAD := 1400.0
const VEL_CAMINAR := 175.0
const VEL_CORRER := 285.0
const VEL_ARRASTRE := 62.0
const VEL_ESCALA := 74.0

func _ready() -> void:
	z_index = 10
	_forma = CollisionShape2D.new()
	var capsula := CapsuleShape2D.new()
	capsula.radius = 13.0
	capsula.height = 84.0
	_forma.shape = capsula
	_forma.position = Vector2(0, -42)
	add_child(_forma)
	_camara = Camera2D.new()
	_camara.position_smoothing_enabled = true
	_camara.position_smoothing_speed = 6.0
	_camara.zoom = Vector2(1.15, 1.15)
	_camara.limit_bottom = 1400
	add_child(_camara)
	_camara.make_current()
	_tex_cono = _crear_textura_cono()
	_luz_cono = PointLight2D.new()
	_luz_cono.texture = _tex_cono
	_luz_cono.color = Color(1.0, 0.83, 0.52)
	_luz_cono.energy = 2.6
	_luz_cono.texture_scale = 4.6
	_luz_cono.position = Vector2(16, -74)
	_luz_cono.name = "LuzCono"
	add_child(_luz_cono)
	_luz_punto = PointLight2D.new()
	_luz_punto.color = Color(1.0, 0.8, 0.5)
	_luz_punto.energy = 0.8
	_luz_punto.texture_scale = 1.1
	_luz_punto.position = Vector2(0, -50)
	add_child(_luz_punto)

func _crear_textura_cono() -> Texture2D:
	# Cono suave tipo linterna: brillante en el eje, se desvanece en bordes.
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var centro := Vector2(8, 128)
	for px in range(256):
		for py in range(256):
			var p := Vector2(px, py) - centro
			var dist := clampf(p.length() / 245.0, 0.0, 1.0)
			var ang := absf(p.angle())
			var a_ang := clampf(1.0 - (ang / 0.62), 0.0, 1.0)
			var a := pow(1.0 - dist, 1.6) * pow(a_ang, 1.3)
			img.set_pixel(px, py, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	_tiempo += delta
	en_el_agua = CuevaDatos.en_agua(global_position.x, global_position.y)
	var altura := CuevaDatos.altura_libre(global_position.x)
	# --- Cambio de modo ---
	if agarrado_cuerda:
		modo = "rappel"
	elif en_el_agua and global_position.y > CuevaDatos.AGUA_Y + 6.0:
		modo = "nado"
	elif altura < 72.0 or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		modo = "arrastre"
	elif absf(CuevaDatos.pendiente(global_position.x)) > 0.62 and is_on_floor():
		modo = "escala"
	else:
		modo = "pie"
	_ajustar_forma()
	var entrada := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A): entrada = minf(entrada, -1.0)
	if Input.is_key_pressed(KEY_D): entrada = maxf(entrada, 1.0)
	if entrada != 0.0:
		direccion = signf(entrada)
	match modo:
		"pie", "escala":
			velocity.y += GRAVEDAD * delta
			var vel_max := VEL_CAMINAR
			if modo == "escala":
				vel_max = VEL_ESCALA
				energia = maxf(0.0, energia - 3.2 * delta)
			elif Input.is_key_pressed(KEY_SHIFT):
				vel_max = VEL_CORRER
				energia = maxf(0.0, energia - 1.1 * delta)
			velocity.x = move_toward(velocity.x, entrada * vel_max, 1400.0 * delta)
			if Input.is_action_just_pressed("ui_accept") and is_on_floor() and modo == "pie":
				velocity.y = -430.0
			fase += absf(velocity.x) * delta * 0.052
		"arrastre":
			velocity.y += GRAVEDAD * delta
			velocity.x = move_toward(velocity.x, entrada * VEL_ARRASTRE, 900.0 * delta)
			fase += absf(velocity.x) * delta * 0.075
			energia = maxf(0.0, energia - 0.7 * delta)
		"nado":
			var vertical := 0.0
			if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): vertical = -1.0
			if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): vertical = 1.0
			velocity.x = move_toward(velocity.x, entrada * 150.0, 700.0 * delta)
			velocity.y = move_toward(velocity.y, vertical * 125.0 + 14.0, 700.0 * delta)
			fase += delta * (2.2 + absf(velocity.x) * 0.012)
			if global_position.y > CuevaDatos.AGUA_Y + 46.0:
				aire = maxf(0.0, aire - 9.5 * delta)
				if aire <= 0.0:
					hambre = maxf(0.0, hambre - 4.0 * delta)
			else:
				aire = minf(100.0, aire + 30.0 * delta)
		"rappel":
			# Péndulo físico: el balanceo se empuja con A/D y se amortigua solo.
			var empuje := entrada * 1.9
			vel_balanceo += (-2.6 * sin(angulo_balanceo) - 0.35 * vel_balanceo + empuje) * delta
			angulo_balanceo += vel_balanceo * delta
			if Input.is_key_pressed(KEY_W): longitud_cuerda = maxf(26.0, longitud_cuerda - 55.0 * delta)
			if Input.is_key_pressed(KEY_S): longitud_cuerda = minf(430.0, longitud_cuerda + 55.0 * delta)
			var ancla := CuevaDatos.ANCLA_POZO
			var destino := ancla + Vector2(sin(angulo_balanceo), cos(angulo_balanceo)) * longitud_cuerda
			velocity = (destino - global_position) / maxf(delta, 0.001)
			energia = maxf(0.0, energia - 0.9 * delta)
			fase += delta * 1.4
	move_and_slide()
	if modo != "nado":
		aire = minf(100.0, aire + 40.0 * delta)
	# --- Supervivencia y luz ---
	hambre = maxf(0.0, hambre - 0.55 * delta)
	if luz_encendida and bateria > 0.0:
		bateria = maxf(0.0, bateria - (0.85 if tiene_frontal else 1.25) * delta)
	var parpadeo := 1.0
	if bateria <= 0.0:
		parpadeo = 0.0
	elif bateria < 18.0:
		parpadeo = 0.55 + 0.45 * sin(_tiempo * 31.0) * randf()
	_luz_cono.energy = 2.6 * parpadeo * (1.0 if luz_encendida else 0.0)
	_luz_punto.energy = 0.8 * parpadeo * (1.0 if luz_encendida else 0.0)
	_luz_cono.rotation = (1.0 - direccion) * 1.5708 if direccion < 0.0 else 0.0
	if modo == "arrastre": _luz_cono.position = Vector2(15 * direccion, -22)
	elif modo == "nado": _luz_cono.position = Vector2(15 * direccion, -34)
	else: _luz_cono.position = Vector2(15 * direccion, -74)
	emit_signal("estado_cambiado")
	queue_redraw()

func _ajustar_forma() -> void:
	var capsula := _forma.shape as CapsuleShape2D
	if modo == "arrastre":
		capsula.height = 34.0
		_forma.position = Vector2(0, -17)
		_forma.rotation = 0.0
	elif modo == "nado":
		capsula.height = 40.0
		_forma.position = Vector2(0, -22)
	else:
		capsula.height = 84.0
		_forma.position = Vector2(0, -42)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_L: luz_encendida = not luz_encendida
			KEY_F:
				if raciones > 0 and hambre < 96.0:
					raciones -= 1
					hambre = minf(100.0, hambre + 42.0)
			KEY_R:
				if baterias_extra > 0 and bateria < 40.0:
					baterias_extra -= 1
					bateria = 100.0

# ---------- Dibujo del humano (vector, con volumen e IK de dos huesos) ----------
const PIEL := Color(0.09, 0.085, 0.11)
const ROPA := Color(0.07, 0.075, 0.12)
const ROPA2 := Color(0.11, 0.11, 0.17)
const BORDE_LUZ := Color(1.0, 0.78, 0.45)
const MOCHILA := Color(0.13, 0.1, 0.16)

func _ik(origen: Vector2, destino: Vector2, l1: float, l2: float, dobla: float) -> Vector2:
	var d := clampf(origen.distance_to(destino), 4.0, l1 + l2 - 0.5)
	var dir := (destino - origen).normalized()
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(0.0, l1 * l1 - a * a))
	var perp := Vector2(-dir.y, dir.x) * dobla
	return origen + dir * a + perp * h

func _miembro(a: Vector2, b: Vector2, c: Vector2, ancho: float, color: Color) -> void:
	draw_line(a, b, color, ancho, true)
	draw_line(b, c, color, ancho * 0.82, true)
	draw_circle(a, ancho * 0.5, color)
	draw_circle(b, ancho * 0.44, color)  # rodilla / codo con volumen
	draw_circle(c, ancho * 0.36, color)

func _bota(pie: Vector2, dir: float) -> void:
	draw_polygon(PackedVector2Array([pie + Vector2(-5, -3), pie + Vector2(9 * dir, -2), pie + Vector2(10 * dir, 2), pie + Vector2(-6, 3)]), PackedColorArray([ROPA]))

func _cabeza(centro: Vector2, dir: float) -> void:
	# Cuello, cara de perfil (frente, nariz, mentón), casco con correa y frontal.
	draw_line(centro + Vector2(0, 6), centro + Vector2(1 * dir, 13), PIEL, 7.0, true)
	draw_circle(centro, 10.5, PIEL)
	draw_polygon(PackedVector2Array([centro + Vector2(8 * dir, -2), centro + Vector2(13.5 * dir, 1.5), centro + Vector2(8 * dir, 3.5)]), PackedColorArray([PIEL]))
	draw_arc(centro + Vector2(0, -2), 11.5, PI + 0.15, TAU - 0.4, 18, Color(0.16, 0.15, 0.2), 6.0, true)
	draw_line(centro + Vector2(2 * dir, 8), centro + Vector2(3 * dir, 13), Color(0.2, 0.18, 0.22), 2.0)
	draw_circle(centro + Vector2(10 * dir, -3), 3.0, Color(1.0, 0.9, 0.6))  # frontal encendida
	draw_line(centro + Vector2(-9 * dir, -6), centro + Vector2(11 * dir, -5), BORDE_LUZ, 1.6, true)

func _mochila(espalda: Vector2, dir: float) -> void:
	var base := espalda + Vector2(-13 * dir, 0)
	draw_polygon(PackedVector2Array([base + Vector2(-8, -17), base + Vector2(7, -19), base + Vector2(9, 8), base + Vector2(-7, 12)]), PackedColorArray([MOCHILA]))
	draw_arc(base + Vector2(0, -19), 8.0, PI, TAU, 12, Color(0.32, 0.2, 0.16), 6.0, true)  # petate enrollado
	draw_arc(base + Vector2(-9 * dir, 2), 6.5, 0, TAU, 16, Color(0.55, 0.42, 0.25), 2.4)  # cuerda enrollada
	if tiene_piolet:
		draw_line(base + Vector2(6 * dir, -14), base + Vector2(10 * dir, 10), Color(0.4, 0.32, 0.2), 3.0, true)
		draw_line(base + Vector2(3 * dir, -15), base + Vector2(11 * dir, -13), Color(0.6, 0.62, 0.68), 3.0, true)

func _torso(cadera: Vector2, hombro: Vector2, dir: float) -> void:
	var ancho_c := 8.5
	var ancho_h := 10.5
	var perp := (hombro - cadera).normalized().rotated(PI / 2.0)
	draw_polygon(PackedVector2Array([
		cadera + perp * ancho_c, hombro + perp * ancho_h,
		hombro - perp * ancho_h, cadera - perp * ancho_c]), PackedColorArray([ROPA]))
	draw_line(cadera, hombro, ROPA2, 2.0)  # cierre de la chaqueta
	draw_line(cadera + perp * 6.0, cadera - perp * 6.0, Color(0.3, 0.2, 0.1), 3.4)  # cinturón
	draw_line(hombro, hombro + Vector2(4 * dir, 2), BORDE_LUZ, 1.6, true)

func _draw() -> void:
	var dir := direccion
	var moviendo := absf(velocity.x) > 12.0
	if modo == "arrastre":
		_dibujar_arrastre(dir)
	elif modo == "nado":
		_dibujar_nado(dir)
	elif modo == "rappel":
		_dibujar_rappel(dir)
	elif modo == "escala":
		_dibujar_escala(dir)
	else:
		_dibujar_pie(dir, moviendo)

func _dibujar_pie(dir: float, moviendo: bool) -> void:
	var rebote := sin(fase * 2.0) * 1.6 if moviendo else sin(_tiempo * 1.7) * 0.7
	var cadera := Vector2(0, -46 + rebote)
	var hombro := cadera + Vector2(3.2 * dir * (1.0 if moviendo else 0.3), -27)
	var paso := 17.0 if moviendo else 4.0
	var pie_a := Vector2(sin(fase) * paso, 0.0 if sin(fase) > -0.4 else -7.0)
	var pie_b := Vector2(sin(fase + PI) * paso, 0.0 if sin(fase + PI) > -0.4 else -7.0)
	if not moviendo:
		pie_a = Vector2(6 * dir, 0)
		pie_b = Vector2(-6 * dir, 0)
	var rod_a := _ik(cadera, pie_a, 24.0, 23.0, dir)
	var rod_b := _ik(cadera, pie_b, 24.0, 23.0, dir)
	_miembro(cadera, rod_b, pie_b, 10.5, ROPA.darkened(0.25))  # pierna lejana
	var mano_b := hombro + Vector2(sin(fase) * 11.0 * dir, 24)
	var codo_b := _ik(hombro, mano_b, 15.0, 14.0, -dir)
	_miembro(hombro, codo_b, mano_b, 8.0, ROPA.darkened(0.25))
	_mochila(hombro + Vector2(0, 12), dir)
	_torso(cadera, hombro, dir)
	_miembro(cadera, rod_a, pie_a, 11.5, ROPA)  # pierna cercana
	_bota(pie_a, dir)
	_bota(pie_b, dir)
	var mano_a := hombro + Vector2(sin(fase + PI) * 11.0 * dir, 24)
	if linterna_en_mano and not tiene_frontal:
		mano_a = hombro + Vector2(17 * dir, 10)  # linterna al frente
	var codo_a := _ik(hombro, mano_a, 15.0, 14.0, -dir)
	_miembro(hombro, codo_a, mano_a, 8.6, ROPA2)
	if linterna_en_mano and not tiene_frontal:
		draw_circle(mano_a, 3.4, Color(0.85, 0.85, 0.9))
	_cabeza(hombro + Vector2(2.5 * dir, -12), dir)

func _dibujar_arrastre(dir: float) -> void:
	var cadera := Vector2(-16 * dir, -15)
	var hombro := Vector2(13 * dir, -19)
	var mano_a := hombro + Vector2((10.0 + sin(fase) * 9.0) * dir, 15)
	var mano_b := hombro + Vector2((10.0 + sin(fase + PI) * 9.0) * dir, 16)
	_miembro(hombro, _ik(hombro, mano_b, 14, 13, 1), mano_b, 8.0, ROPA.darkened(0.25))
	var pie_a := cadera + Vector2((-24.0 + sin(fase) * 6.0) * dir, 13)
	var pie_b := cadera + Vector2((-24.0 + sin(fase + PI) * 6.0) * dir, 14)
	_miembro(cadera, _ik(cadera, pie_b, 20, 19, -1), pie_b, 10.0, ROPA.darkened(0.25))
	_mochila(Vector2(-4 * dir, -18), dir)
	_torso(cadera, hombro, dir)
	_miembro(cadera, _ik(cadera, pie_a, 20, 19, -1), pie_a, 11.0, ROPA)
	_miembro(hombro, _ik(hombro, mano_a, 14, 13, 1), mano_a, 8.6, ROPA2)
	_cabeza(hombro + Vector2(9 * dir, -5), dir)

func _dibujar_nado(dir: float) -> void:
	var cadera := Vector2(-13 * dir, -26 + sin(_tiempo * 2.4) * 2.0)
	var hombro := Vector2(11 * dir, -30 + sin(_tiempo * 2.4) * 2.0)
	var mano_a := hombro + Vector2(cos(fase) * 17.0 * dir, sin(fase) * 10.0 + 4)
	var mano_b := hombro + Vector2(cos(fase + PI) * 17.0 * dir, sin(fase + PI) * 10.0 + 4)
	_miembro(hombro, _ik(hombro, mano_b, 15, 14, 1), mano_b, 8.0, ROPA.darkened(0.25))
	var pie_a := cadera + Vector2((-26.0) * dir, sin(fase * 2.0) * 7.0)
	var pie_b := cadera + Vector2((-26.0) * dir, sin(fase * 2.0 + PI) * 7.0)
	_miembro(cadera, _ik(cadera, pie_a, 21, 20, -1), pie_a, 10.5, ROPA)
	_miembro(cadera, _ik(cadera, pie_b, 21, 20, -1), pie_b, 10.0, ROPA.darkened(0.2))
	_mochila(Vector2(0, -30), dir)
	_torso(cadera, hombro, dir)
	_miembro(hombro, _ik(hombro, mano_a, 15, 14, 1), mano_a, 8.6, ROPA2)
	_cabeza(hombro + Vector2(9 * dir, -6), dir)
	if global_position.y > CuevaDatos.AGUA_Y + 40.0 and int(_tiempo * 2.0) % 2 == 0:
		draw_circle(hombro + Vector2(14 * dir, -10), 2.2, Color(0.8, 0.95, 1, 0.7))  # burbujas

func _dibujar_escala(dir: float) -> void:
	var cadera := Vector2(0, -42)
	var hombro := cadera + Vector2(10 * dir, -25)
	var agarre := hombro + Vector2(20 * dir, -16 - sin(fase) * 5.0)
	_miembro(hombro, _ik(hombro, agarre, 15, 14, -dir), agarre, 8.6, ROPA2)
	var pie_a := Vector2(9 * dir, -6 - maxf(0.0, sin(fase)) * 9.0)
	var pie_b := Vector2(-3 * dir, -2 - maxf(0.0, sin(fase + PI)) * 9.0)
	_miembro(cadera, _ik(cadera, pie_b, 23, 22, dir), pie_b, 10.5, ROPA.darkened(0.2))
	_mochila(hombro + Vector2(-2, 10), dir)
	_torso(cadera, hombro, dir)
	_miembro(cadera, _ik(cadera, pie_a, 23, 22, dir), pie_a, 11.5, ROPA)
	_bota(pie_a, dir)
	_bota(pie_b, dir)
	_cabeza(hombro + Vector2(3 * dir, -12), dir)

func _dibujar_rappel(dir: float) -> void:
	var cadera := Vector2(0, -34)
	var hombro := cadera + Vector2(-5 * dir, -26)
	var mano_cuerda := hombro + Vector2(4 * dir, 16)
	_miembro(hombro, _ik(hombro, mano_cuerda, 15, 14, dir), mano_cuerda, 8.6, ROPA2)
	var pie_a := Vector2(17 * dir, 2)
	var pie_b := Vector2(6 * dir, 12)
	_miembro(cadera, _ik(cadera, pie_b, 22, 21, dir), pie_b, 10.5, ROPA.darkened(0.2))
	_mochila(hombro + Vector2(0, 10), dir)
	_torso(cadera, hombro, dir)
	_miembro(cadera, _ik(cadera, pie_a, 22, 21, dir), pie_a, 11.5, ROPA)
	_bota(pie_a, dir)
	_bota(pie_b, dir)
	_cabeza(hombro + Vector2(1 * dir, -12), dir)
