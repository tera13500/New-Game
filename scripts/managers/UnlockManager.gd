extends Node
class_name UnlockManager

signal codex_unlocked(component_id: String)

var unlocked_components: Array[String] = ["door_sensor", "overload_sensor", "emergency_call"]
var earned_titles: Array[String] = []

func unlock_component(component_id: String) -> void:
	if unlocked_components.has(component_id):
		return
	unlocked_components.append(component_id)
	emit_signal("codex_unlocked", component_id)

func evaluate_titles(game_state: GameState) -> void:
	if game_state.complaints <= 2 and game_state.day >= 3:
		_add_title("민원 제로 운영자")
	if game_state.inspection_rate >= 90.0:
		_add_title("점검 성실 관리자")
	if game_state.safety_score >= 90.0:
		_add_title("안전문화 확산 건물")

func _add_title(title: String) -> void:
	if earned_titles.has(title):
		return
	earned_titles.append(title)
