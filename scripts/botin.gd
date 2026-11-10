class_name Botin
extends Node2D
## Cristal o fósil recogible: brilla con su propia luz (como en la imagen,
## los cristales alumbran solos en la oscuridad). Ocupa espacio de mochila.

var tipo := "cristal"
var valor := 25
var recogido := false
var tiempo := 0.0
var luz: PointLight2D

func _ready() -> void:
	z_index = 3
	luz = PointLight2D.new()
	luz.energy = 0.9
	luz.texture_scale = 0.55
	luz.color = Color(0.62, 0.45, 1.0) if tipo == "cristal" else Color(1.0, 0.8, 0.45)
	add_child(luz)

func _process(delta: float) -> void:
	tiempo += delta
	if luz != null:
		luz.energy = 0.75 + 0.3 * sin(tiempo * 2.6 + global_position.x)
	queue_redraw()

func _draw() -> void:
	if recogido:
		return
	if tipo == "cristal":
		var c := Color(0.66, 0.5, 1.0)
		draw_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(-3, -20), Vector2(3, -24), Vector2(7, 0)]), PackedColorArray([c]))
		draw_polygon(PackedVector2Array([Vector2(5, 0), Vector2(10, -13), Vector2(14, 0)]), PackedColorArray([c.darkened(0.25)]))
		draw_line(Vector2(0, -20), Vector2(1, -3), Color(1, 1, 1, 0.65), 1.6, true)
	else:
		draw_arc(Vector2(0, -6), 9.0, 0.3, TAU - 0.6, 20, Color(0.9, 0.75, 0.45), 4.0, true)
		draw_arc(Vector2(0, -6), 5.0, 0.6, TAU - 0.9, 16, Color(0.9, 0.75, 0.45), 3.0, true)
		draw_circle(Vector2(0, -6), 1.8, Color(0.9, 0.75, 0.45))
