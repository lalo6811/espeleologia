class_name Minimapa
extends Control
## Minimapa circular abajo a la derecha, como en la imagen de referencia:
## círculo oscuro con el perfil de la cueva, el punto del jugador, los
## campamentos y la etiqueta de profundidad.

var jugador: Node2D = null

func _ready() -> void:
	custom_minimum_size = Vector2(168, 168)
	mouse_filter = MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var centro := size * 0.5
	var radio := 80.0
	draw_circle(centro, radio, Color(0.04, 0.05, 0.1, 0.88))
	draw_arc(centro, radio, 0, TAU, 48, Color(0.75, 0.78, 0.85, 0.8), 2.0, true)
	# Perfil de la cueva reducido
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= 7100.0:
		var mx: float = centro.x - radio + 12.0 + (x / 7100.0) * (radio * 2.0 - 24.0)
		var my: float = centro.y + (CuevaDatos.suelo_y(x) / 800.0) * 52.0 - 16.0
		pts.append(Vector2(mx, my))
		x += 200.0
	draw_polyline(pts, Color(0.55, 0.6, 0.8, 0.9), 2.0, true)
	# Agua
	draw_line(Vector2(centro.x + 22, centro.y + 22), Vector2(centro.x + 48, centro.y + 26), Color(0.4, 0.9, 1.0), 3.0, true)
	for cx in CuevaDatos.CAMPAMENTOS:
		var mx2: float = centro.x - radio + 12.0 + (float(cx) / 7100.0) * (radio * 2.0 - 24.0)
		draw_circle(Vector2(mx2, centro.y + (CuevaDatos.suelo_y(cx) / 800.0) * 52.0 - 16.0), 3.0, Color(1.0, 0.6, 0.2))
	if jugador != null:
		var px: float = centro.x - radio + 12.0 + (jugador.global_position.x / 7100.0) * (radio * 2.0 - 24.0)
		var py: float = centro.y + (jugador.global_position.y / 800.0) * 52.0 - 16.0
		draw_circle(Vector2(px, py), 4.5, Color(1.0, 0.9, 0.5))
		draw_arc(Vector2(px, py), 8.0, 0, TAU, 20, Color(1, 1, 1, 0.7), 1.4, true)
