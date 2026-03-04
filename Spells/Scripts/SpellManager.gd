class_name SpellManager
extends Resource

# --------------------------------------------------
# This represents ONE player's spell instance.
# It stores:
# - XP
# - Level
# - Calculated Power
# - Gesture coordinates
# --------------------------------------------------


# ===============================
# CONFIGURATION
# ===============================

const XP_PER_LEVEL: int = 100     # Every 100 XP = +1 level
const POWER_PER_LEVEL: float = 2  # +2 power per level


# ===============================
# TEMPLATE REFERENCE
# ===============================

var spell: Spell                # Reference to template spell


# ===============================
# RUNTIME DATA
# ===============================

var coords: Array[Vector2] = [] # Gesture shape

var xp: int = 0                 # Total XP
var level: int = 1              # Current level
var power: float = 0.0          # Calculated power


# ===============================
# CONSTRUCTOR
# ===============================

func _init(new_spell: Spell, new_coords: Array[Vector2]) -> void:
	#"""
	#Called when creating new SpellManager.
	#"""
	spell = new_spell
	coords = new_coords
	
	_update_level()
	_update_power()


# ==================================================
# XP SYSTEM
# ==================================================

func add_xp(amount: int) -> void:
	#"""
	#Adds XP to the spell.
	#Automatically updates level and power.
	#"""
	xp += amount
	_update_level()
	_update_power()


func _update_level() -> void:
	#"""
	#Level increases every XP_PER_LEVEL XP.
	#Level never decreases.
	#"""
	level = max(1, xp / XP_PER_LEVEL + 1)


# ==================================================
# POWER CALCULATION
# ==================================================

func _update_power() -> void:
	#"""
	#Power increases linearly with level.
	#Example:
		#Level 1 → base_power
		#Level 2 → base_power + 2
		#Level 3 → base_power + 4
	#"""
	if spell == null:
		power = 0
		return
	
	power = spell.base_power + (level - 1) * POWER_PER_LEVEL


# ==================================================
# GETTERS (Safe Access)
# ==================================================

func get_spell() -> Spell:
	return spell

func get_coords() -> Array[Vector2]:
	return coords

func get_xp() -> int:
	return xp

func get_level() -> int:
	return level

func get_power() -> float:
	return power


# ==================================================
# OPTIONAL: Reset Spell Progress
# ==================================================

func reset_progress() -> void:
	#"""
	#Resets spell XP and level.
	#"""
	xp = 0
	level = 1
	_update_power()
