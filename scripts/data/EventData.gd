extends RefCounted
class_name EventData

var event_id: String
var title: String
var description: String
var severity: String
var trigger_condition: String
var options: Array[Dictionary]
var component_tags: Array[String]
var campaign_tags: Array[String]
var recommended_action: String
var unlock_component_id: String
var target_elevator_id: int
var event_level: String

func _init(
	p_event_id: String,
	p_title: String,
	p_description: String,
	p_severity: String,
	p_trigger_condition: String,
	p_options: Array[Dictionary],
	p_component_tags: Array[String] = [],
	p_campaign_tags: Array[String] = [],
	p_recommended_action: String = "",
	p_unlock_component_id: String = "",
	p_target_elevator_id: int = -1,
	p_event_level: String = "major"
) -> void:
	event_id = p_event_id
	title = p_title
	description = p_description
	severity = p_severity
	trigger_condition = p_trigger_condition
	options = p_options
	component_tags = p_component_tags
	campaign_tags = p_campaign_tags
	recommended_action = p_recommended_action
	unlock_component_id = p_unlock_component_id
	target_elevator_id = p_target_elevator_id
	event_level = p_event_level
