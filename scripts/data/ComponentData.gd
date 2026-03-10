extends RefCounted
class_name ComponentData

var id: String
var name: String
var short_desc: String
var safety_role: String

func _init(p_id: String, p_name: String, p_short_desc: String, p_safety_role: String) -> void:
	id = p_id
	name = p_name
	short_desc = p_short_desc
	safety_role = p_safety_role
