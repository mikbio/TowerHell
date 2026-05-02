extends GutTest

func before_each() -> void:
	GameManager.start_run()

func test_start_run_resets_hp() -> void:
	GameManager.damage_circle(50.0)
	GameManager.start_run()
	assert_eq(GameManager.circle_hp, GameManager.CIRCLE_MAX_HP)

func test_damage_circle_reduces_hp() -> void:
	GameManager.damage_circle(30.0)
	assert_eq(GameManager.circle_hp, 70.0)

func test_damage_circle_cannot_go_below_zero() -> void:
	GameManager.damage_circle(200.0)
	assert_eq(GameManager.circle_hp, 0.0)

func test_circle_destroyed_signal_emitted() -> void:
	watch_signals(SignalBus)
	GameManager.damage_circle(GameManager.CIRCLE_MAX_HP)
	assert_signal_emitted(SignalBus, "circle_destroyed")

func test_level_up_on_exp_gain() -> void:
	GameManager.add_exp(GameManager.EXP_PER_LEVEL)
	assert_eq(GameManager.player_level, 2)

func test_exp_overflow_carries_to_next_level() -> void:
	GameManager.add_exp(GameManager.EXP_PER_LEVEL * 2.5)
	assert_eq(GameManager.player_level, 3)
