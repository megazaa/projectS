extends Resource
class_name interact_manager
enum types{
	door,
	key,
	item,
	evidence
}
@export var item_name:String = "name"
@export var types_name:types
@export var key_for:String = ""
