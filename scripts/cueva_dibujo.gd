class_name CuevaDibujo
extends Node2D
## Dibuja la cueva como ROCA SÓLIDA con el vacío tallado dentro: suelo y
## techo continuos, estratos, estalactitas/estalagmitas, columnas en la Sala
## Grande, hongos luminosos, agua del río/sifón, tiendas y fogatas.
## Todo vectorial con polígonos suaves — nada de pixel art.

var hongos: Array[Vector2] = []
var tiempo := 0.0

func _ready() -> void:
	z_index = -5
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var x := 500.0
	while x < 7000.0:
		if int(x) % 700 < 300:
			hongos.append(Vector2(x, CuevaDatos.suelo_y(x)))
		x += rng.randf_range(120.0, 260.0)

func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()

func _poligono_roca(es_superior: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x := -200.0
	if es_superior:
		pts.append(Vector2(-200, -1400))
		while x <= 7300.0:
			pts.append(Vector2(x, CuevaDatos.techo_y(x)))
			x += 60.0
		pts.append(Vector2(7300, -1400))
	else:
		pts.append(Vector2(-200, 1500))
		while x <= 7300.0:
			pts.append(Vector2(x, CuevaDatos.suelo_y(x)))
			x += 60.0
		pts.append(Vector2(7300, 1500))
	return pts

func _draw() -> void:
	# Cielo de superficie a la izquierda
	draw_rect(Rect2(-200, -1400, 640, 1420), Color(0.45, 0.62, 0.85))
	draw_circle(Vector2(120, -560), 60, Color(1.0, 0.9, 0.55, 0.8))
	# Roca: techo y suelo con capas de color (profundidad azul/púrpura)
	draw_polygon(_poligono_roca(true), PackedColorArray([Color(0.08, 0.07, 0.14)]))
	draw_polygon(_poligono_roca(false), PackedColorArray([Color(0.1, 0.085, 0.16)]))
	_estratos()
	_formaciones()
	_agua()
	for h in hongos:
		_hongo(h)
	for cx in CuevaDatos.CAMPAMENTOS:
		_tienda(Vector2(cx, CuevaDatos.suelo_y(cx)))
	_tienda(Vector2(150, 0))  # campamento base en superficie

func _estratos() -> void:
	for capa in range(3):
		var pts := PackedVector2Array()
		var x := -200.0
		while x <= 7300.0:
			pts.append(Vector2(x, CuevaDatos.suelo_y(x) + 26.0 + capa * 34.0))
			x += 120.0
		draw_polyline(pts, Color(0.16, 0.13, 0.24, 0.7), 5.0, true)

func _formaciones() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var x := 650.0
	while x < 7050.0:
		var alto := CuevaDatos.altura_libre(x)
		if alto > 120.0:
			var ty := CuevaDatos.techo_y(x)
			var largo := rng.randf_range(28.0, minf(120.0, alto * 0.36))
			var ancho := rng.randf_range(9.0, 20.0)
			draw_polygon(PackedVector2Array([Vector2(x - ancho, ty), Vector2(x + ancho, ty), Vector2(x, ty + largo)]), PackedColorArray([Color(0.14, 0.12, 0.22)]))
			var sy := CuevaDatos.suelo_y(x + 40.0)
			draw_polygon(PackedVector2Array([Vector2(x + 40 - ancho, sy), Vector2(x + 40 + ancho, sy), Vector2(x + 40, sy - largo * 0.55)]), PackedColorArray([Color(0.13, 0.11, 0.2)]))
		x += rng.randf_range(90.0, 210.0)
	# Columnas gigantes de la Sala Grande (como las de Son Doong / Han Son Doong)
	for cx in [3300.0, 3650.0, 3980.0]:
		var ty := CuevaDatos.techo_y(cx)
		var sy := CuevaDatos.suelo_y(cx)
		draw_polygon(PackedVector2Array([Vector2(cx - 20, ty), Vector2(cx + 20, ty), Vector2(cx + 11, sy), Vector2(cx - 11, sy)]), PackedColorArray([Color(0.15, 0.12, 0.24)]))

func _agua() -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(CuevaDatos.AGUA_X0, CuevaDatos.AGUA_Y))
	var x := CuevaDatos.AGUA_X0
	while x <= CuevaDatos.AGUA_X1:
		pts.append(Vector2(x, CuevaDatos.suelo_y(x) + 4.0))
		x += 60.0
	pts.append(Vector2(CuevaDatos.AGUA_X1, CuevaDatos.AGUA_Y))
	var ondula := sin(tiempo * 1.6) * 2.0
	draw_polygon(pts, PackedColorArray([Color(0.1, 0.55, 0.66, 0.42)]))
	draw_line(Vector2(CuevaDatos.AGUA_X0, CuevaDatos.AGUA_Y + ondula), Vector2(CuevaDatos.AGUA_X1, CuevaDatos.AGUA_Y - ondula), Color(0.45, 0.95, 1.0, 0.55), 2.5, true)

func _hongo(p: Vector2) -> void:
	var pulso := 0.75 + 0.25 * sin(tiempo * 2.0 + p.x * 0.05)
	draw_line(p, p + Vector2(0, -9), Color(0.5, 0.8, 0.75), 3.0, true)
	draw_arc(p + Vector2(0, -8), 7.0, PI, TAU, 12, Color(0.35, 0.95, 0.85, pulso), 5.0, true)
	draw_circle(p + Vector2(0, -10), 12.0, Color(0.3, 0.9, 0.8, 0.1 * pulso))

func _tienda(p: Vector2) -> void:
	draw_polygon(PackedVector2Array([p + Vector2(-52, 0), p + Vector2(0, -46), p + Vector2(52, 0)]), PackedColorArray([Color(0.55, 0.32, 0.14)]))
	draw_polygon(PackedVector2Array([p + Vector2(-16, 0), p + Vector2(0, -27), p + Vector2(16, 0)]), PackedColorArray([Color(0.12, 0.07, 0.05)]))
	var llama := 5.0 + sin(tiempo * 11.0) * 1.6
	draw_circle(p + Vector2(74, -4), llama, Color(1.0, 0.55, 0.15, 0.9))
	draw_circle(p + Vector2(74, -6), llama * 0.55, Color(1.0, 0.85, 0.4))
