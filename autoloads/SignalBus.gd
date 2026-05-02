extends Node

# Tower / Circle
signal circle_damaged(amount: float)
signal circle_destroyed()

# Enemies
signal enemy_died(enemy_position: Vector2, soul_value: int, gold_value: int)
signal enemy_reached_tower()

# Player / Spells
signal spell_cast(element: String, position: Vector2)
signal player_leveled_up(new_level: int)

# Economy
signal souls_changed(new_amount: int)
signal gold_changed(new_amount: int)

# Waves
signal wave_started(wave_number: int)
signal corrupted_night_started()
signal corrupted_night_ended()
