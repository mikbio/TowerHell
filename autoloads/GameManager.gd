extends Node

const CIRCLE_MAX_HP: float = 100.0
const EXP_PER_LEVEL: float = 100.0
const EXP_MULTIPLIER: float = 1.2  # each level needs 20% more EXP

var circle_hp: float = CIRCLE_MAX_HP
var player_level: int = 1
var player_exp: float = 0.0
var exp_to_next_level: float = EXP_PER_LEVEL
var is_run_active: bool = false

func start_run() -> void:
	circle_hp = CIRCLE_MAX_HP
	player_level = 1
	player_exp = 0.0
	exp_to_next_level = EXP_PER_LEVEL
	is_run_active = true

func damage_circle(amount: float) -> void:
	circle_hp = maxf(0.0, circle_hp - amount)
	SignalBus.circle_damaged.emit(amount)
	if circle_hp <= 0.0:
		is_run_active = false
		SignalBus.circle_destroyed.emit()

func add_exp(amount: float) -> void:
	player_exp += amount
	while player_exp >= exp_to_next_level:
		player_exp -= exp_to_next_level
		player_level += 1
		exp_to_next_level *= EXP_MULTIPLIER
		SignalBus.player_leveled_up.emit(player_level)

func get_circle_hp_percent() -> float:
	return circle_hp / CIRCLE_MAX_HP
