extends Node

# =====================================================
# SPELL TEMPLATE DATABASE
# -----------------------------------------------------
# Responsibilities:
# 1. Load all Spell (.tres) files from folder
# 2. Sort them by required_level
# 3. Create SpellManager instances when needed
# =====================================================


# ===============================
# CONFIGURATION
# ===============================

var spells_path: String = "res://Spells/Resources/"


# ===============================
# STORAGE
# ===============================

# All loaded Spell templates
var spell_resources: Array[Spell] = []

# All player-created spell instances
var spells: Array[SpellManager] = []


# ===============================
# INITIALIZATION
# ===============================

func _ready() -> void:
	# Load all spell templates at start
	spell_resources = _load_all_spells()



# =====================================================
# SPELL LOADING
# =====================================================

func _load_all_spells() -> Array[Spell]:
	#"""
	#Loads every Spell resource inside spells_path.
	#Returns a sorted array by required_level.
	#"""
	#
	var loaded_spells: Array[Spell] = []
	
	var dir = DirAccess.open(spells_path)
	
	# Safety check: folder exists?
	if dir == null:
		push_error("Spell folder not found at: " + spells_path)
		return loaded_spells
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		
		# Ignore folders and only load .tres files
		if !dir.current_is_dir() and file_name.ends_with(".tres"):
			
			var resource = load(spells_path + file_name)
			
			# Make sure it is actually a Spell
			if resource is Spell:
				loaded_spells.append(resource)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	
	# Sort spells by required_level (ascending)
	loaded_spells.sort_custom(func(a, b):
		return a.required_level < b.required_level
	)
	
	return loaded_spells



# =====================================================
# SPELL INSTANCE CREATION
# =====================================================

func add_new_spell(index: int, coords: Array[Vector2]) -> String:
	#"""
	#Creates a new SpellManager instance
	#using spell template at given index.
	#
	#Returns:
	#- Name of next spell if exists
	#- Empty string if no more spells
	#"""
	
	# Safety check: index valid?
	if index < 0 or index >= spell_resources.size():
		return ""
	
	
	# Create runtime spell instance
	var new_spell_instance = SpellManager.new(
		spell_resources[index],
		coords
	)
	
	# Store player spell
	spells.append(new_spell_instance)
	
	
	# Return next spell name if available
	if index + 1 < spell_resources.size():
		return spell_resources[index + 1].name
	
	return ""



# =====================================================
# OPTIONAL HELPER FUNCTIONS
# =====================================================

func get_all_spell_templates() -> Array[Spell]:
	return spell_resources


func get_all_player_spells() -> Array[SpellManager]:
	return spells
