extends RefCounted
class_name SafetyCampaignData

var id: String
var name: String
var short_desc: String
var duration_ticks: int

func _init(p_id: String, p_name: String, p_short_desc: String, p_duration_ticks: int) -> void:
	id = p_id
	name = p_name
	short_desc = p_short_desc
	duration_ticks = p_duration_ticks
