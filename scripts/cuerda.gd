class_name Cuerda
extends Node2D
## Cuerda FLEXIBLE tipo Limbo: cadena Verlet de puntos con gravedad.
## Se curva y se tensa sola; nada de palos rígidos. Une el anclaje del pozo
## con el jugador cuando hace rappel, y cuelga floja cuando nadie la usa.

var ancla := Vector2.ZERO
var extremo: Node2D = null
var activa := false
var puntos: Array[Vector2] = []
var previos: Array[Vector2] = []
const SEGMENTOS := 22
const LARGO_SEG := 15.0

func _ready() -> void:
	z_index = 5
	for i in range(SEGMENTOS + 1):
		puntos.append(ancla + Vector2(0, i * LARGO_SEG))
		previos.append(puntos[i])

func _physics_process(delta: float) -> void:
	if not visible:
		return
	var destino := ancla + Vector2(0, SEGMENTOS * LARGO_SEG)
	if activa and extremo != null:
		destino = extremo.global_position + Vector2(0, -30)
	for i in range(1, puntos.size()):
		var p := puntos[i]
		var v := (p - previos[i]) * 0.985
		previos[i] = p
		puntos[i] = p + v + Vector2(0, 620.0) * delta * delta * 60.0
	for _paso in range(8):
		puntos[0] = ancla
		if activa:
			puntos[puntos.size() - 1] = destino
		for i in range(puntos.size() - 1):
			var a := puntos[i]
			var b := puntos[i + 1]
			var d := b - a
			var dist := maxf(d.length(), 0.001)
			var dif := (dist - LARGO_SEG) / dist
			if i == 0:
				puntos[i + 1] = b - d * dif
			elif activa and i == puntos.size() - 2:
				puntos[i] = a + d * dif
			else:
				puntos[i] = a + d * dif * 0.5
				puntos[i + 1] = b - d * dif * 0.5
	queue_redraw()

func _draw() -> void:
	# Doble trazo: sombra de la cuerda + fibra principal trenzada.
	for pasada in range(2):
		var color := Color(0.16, 0.11, 0.07) if pasada == 0 else Color(0.5, 0.38, 0.22)
		var ancho := 5.0 if pasada == 0 else 3.0
		var desfase := Vector2(1.5, 2.0) if pasada == 0 else Vector2.ZERO
		for i in range(puntos.size() - 1):
			draw_line(puntos[i] + desfase, puntos[i + 1] + desfase, color, ancho, true)
	draw_circle(ancla, 5.0, Color(0.65, 0.66, 0.7))  # mosquetón / anclaje
