class_name Spell
extends Resource

# --------------------------------------------------
# This is the TEMPLATE of a spell.
# It contains base data and never changes at runtime.
# --------------------------------------------------

@export var name: String = ""
@export var required_level: int = 1     # Minimum level needed to unlock
@export var base_power: float = 5.0     # Starting damage
@export var base_cooldown: float = 1.0  # Base reuse time
