extends RefCounted
class_name EventData

var event_id: String
var title: String
var description: String
var severity: String
var trigger_condition: String
var options: Array[Dictionary]

func _init(
	p_event_id: String,
	p_title: String,
	p_description: String,
	p_severity: String,
	p_trigger_condition: String,
	p_options: Array[Dictionary]
) -> void:
	event_id = p_event_id
	title = p_title
	description = p_description
	severity = p_severity
	trigger_condition = p_trigger_condition
	options = p_options
