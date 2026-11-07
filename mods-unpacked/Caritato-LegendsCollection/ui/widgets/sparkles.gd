extends Control

# Estrellas pequeñas que suben despacio alrededor del centro y, con burst(),
# una explosión. Con shape = "confetti" son papelitos que caen girando. Se
# dibuja por código; no usa partículas del motor.

const FistBump = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/fist_bump.gd")

const TINTS := [Color("a970ff"), Color("d7bcff"), Color("ffd166"), Color("ffffff")]

var ambient := true
var spread := Vector2(220, 60)
var shape := "star"
var tints: Array = TINTS
var gravity := 0.0
var _particles := []
var _spawn_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()


func _ready() -> void:
	set_process(true)


func burst(count: int = 40) -> void:
	var center := rect_size / 2.0
	for _i in count:
		var angle := _rng.randf() * TAU
		var speed := _rng.randf_range(280.0, 680.0)
		_particles.append({
			"pos": center,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"drag": 0.93,
			"life": 0.0,
			"max": _rng.randf_range(0.8, 1.4),
			"size": _rng.randf_range(9.0, 20.0),
			"color": tints[_rng.randi() % tints.size()],
			"rot": _rng.randf() * TAU,
			"spin": _rng.randf_range(-8.0, 8.0),
		})


func _process(delta: float) -> void:
	if ambient:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = 0.14
			var center := rect_size / 2.0
			_particles.append({
				"pos": center + Vector2(_rng.randf_range(-spread.x, spread.x), _rng.randf_range(0.0, spread.y)),
				"vel": Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-95.0, -55.0)),
				"drag": 1.0,
				"life": 0.0,
				"max": _rng.randf_range(1.6, 2.4),
				"size": _rng.randf_range(6.0, 12.0),
				"color": tints[_rng.randi() % tints.size()],
				"rot": _rng.randf() * TAU,
				"spin": _rng.randf_range(-1.5, 1.5),
			})

	var alive := []
	for particle in _particles:
		particle.life += delta
		if particle.life >= particle.max:
			continue
		particle.pos += particle.vel * delta
		particle.vel *= particle.drag
		particle.vel.y += gravity * delta
		particle.rot += particle.spin * delta
		alive.append(particle)
	_particles = alive
	update()


func _draw() -> void:
	for particle in _particles:
		var t: float = particle.life / particle.max
		var color: Color = particle.color
		color.a = min(1.0, particle.life * 8.0) * (1.0 - t * t) * 0.9
		var size: float = particle.size * (1.0 - 0.35 * t)
		if shape == "confetti":
			draw_colored_polygon(_confetti_points(particle.pos, size, particle.rot), color, PoolVector2Array(), null, null, true)
		else:
			draw_colored_polygon(FistBump.star_points(particle.pos, size * 0.75, size * 0.32, 5, particle.rot), color, PoolVector2Array(), null, null, true)


static func _confetti_points(center: Vector2, size: float, rotation: float) -> PoolVector2Array:
	var points := PoolVector2Array()
	for corner in [Vector2(-1, -0.45), Vector2(1, -0.45), Vector2(1, 0.45), Vector2(-1, 0.45)]:
		points.append(center + (corner * size * 0.6).rotated(rotation))
	return points
