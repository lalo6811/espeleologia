class_name CuevaDatos
extends RefCounted
## Datos de la cueva REAL: el suelo es una línea CONTINUA (perfil) y el techo
## otra. No hay plataformas flotantes: todo el nivel es roca sólida con un
## vacío tallado dentro (galerías, pasos bajos, salas, pozo, sifón).

# Perfil del suelo: puntos (x, y) de izquierda a derecha. y crece hacia abajo.
const SUELO: Array = [
	Vector2(0, 0), Vector2(420, 0), Vector2(700, 60), Vector2(1100, 90),
	Vector2(1500, 110), Vector2(1950, 130), Vector2(2300, 185),
	Vector2(2700, 330), Vector2(3100, 345), Vector2(3950, 365),
	Vector2(4250, 380), Vector2(4380, 690), Vector2(4520, 700),
	Vector2(5000, 770), Vector2(5650, 800), Vector2(6200, 715),
	Vector2(6650, 725), Vector2(7100, 725)
]
# Altura libre (distancia suelo->techo) en los mismos x aprox.
const ALTURA: Array = [
	Vector2(0, 650), Vector2(420, 320), Vector2(700, 195), Vector2(1100, 175),
	Vector2(1500, 46), Vector2(1950, 46), Vector2(2300, 175),
	Vector2(2700, 210), Vector2(3100, 545), Vector2(3950, 545),
	Vector2(4250, 480), Vector2(4380, 640), Vector2(4520, 210),
	Vector2(5000, 185), Vector2(5650, 160), Vector2(6200, 225),
	Vector2(6650, 430), Vector2(7100, 430)
]
const AGUA_X0 := 4920.0
const AGUA_X1 := 6080.0
const AGUA_Y := 688.0  # superficie del río/sifón
const ANCLA_POZO := Vector2(4310, -230)  # punto de anclaje sobre el pozo
const CAMPAMENTOS: Array[float] = [3400.0, 6720.0]  # x de campamentos ya montados
const SALIDA_X := 6980.0  # punto de extracción en la sala de cristales

static func _interp(puntos: Array, x: float) -> float:
	if x <= puntos[0].x:
		return puntos[0].y
	for i in range(puntos.size() - 1):
		var a: Vector2 = puntos[i]
		var b: Vector2 = puntos[i + 1]
		if x <= b.x:
			var t := (x - a.x) / maxf(1.0, b.x - a.x)
			return lerpf(a.y, b.y, t)
	return puntos[puntos.size() - 1].y

static func suelo_y(x: float) -> float:
	return _interp(SUELO, x)

static func altura_libre(x: float) -> float:
	return _interp(ALTURA, x)

static func techo_y(x: float) -> float:
	return suelo_y(x) - altura_libre(x)

static func pendiente(x: float) -> float:
	return (suelo_y(x + 14.0) - suelo_y(x - 14.0)) / 28.0

static func en_agua(x: float, y: float) -> bool:
	return x > AGUA_X0 and x < AGUA_X1 and y > AGUA_Y - 20.0

static func zona(x: float) -> String:
	if x < 420.0: return "Superficie — Campamento base"
	if x < 1450.0: return "Galería de entrada"
	if x < 2000.0: return "Paso bajo — arrastrándose"
	if x < 3050.0: return "Pendiente escalable"
	if x < 4200.0: return "Sala Grande"
	if x < 4480.0: return "Pozo vertical — rappel"
	if x < 4920.0: return "Galería inferior"
	if x < 6080.0: return "Río y sifón — nadando"
	if x < 6550.0: return "Galería de subida"
	return "Sala de Cristales"
