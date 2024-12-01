#@export var mission_name:String = "nothing for now"
#@export var objectives_name_1:String = ""
#@export var objectives_name_2:String = ""
#@export var objectives_name_3:String = ""
#@export var objectives_checked_1:bool
#@export var objectives_checked_2:bool
#@export var objectives_checked_3:bool
extends Resource
class_name quest_manager
# Mission name
@export var mission_name: String = "nothing for now"

# Objectives: List of names and their completion status
@export var objectives: Array[Dictionary] = [
	{"name": "", "checked": false},
	{"name": "", "checked": false},
	{"name": "", "checked": false}
]

# Function to update an objective's status
func set_objective_status(index: int, status: bool) -> void:
	if index >= 0 and index < objectives.size():
		objectives[index]["checked"] = status
	else:
		print("Invalid objective index")

# Function to retrieve an objective
func get_objective(index: int) -> Dictionary:
	if index >= 0 and index < objectives.size():
		return objectives[index]
	else:
		print("Invalid objective index")
		return {}
