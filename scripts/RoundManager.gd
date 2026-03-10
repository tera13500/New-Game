extends Node
class_name RoundManager

signal tick_advanced
signal day_finished

@export var tick_interval_sec: float = 1.2
@export var ticks_per_day: int = 14

var _running: bool = false
var _accum: float = 0.0
var _tick_counter: int = 0

func start() -> void:
	_accum = 0.0
	_running = true

func stop() -> void:
	_running = false
	_accum = 0.0

func _process(delta: float) -> void:
	if not _running:
		return
	_accum += delta
	if _accum < tick_interval_sec:
		return
	_accum = 0.0
	_tick_counter += 1
	emit_signal("tick_advanced")
	if _tick_counter >= ticks_per_day:
		_tick_counter = 0
		emit_signal("day_finished")
