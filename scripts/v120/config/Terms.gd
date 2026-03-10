extends RefCounted
class_name Terms

const VERSION: String = "1.2.0"
const PLAYER_ROLE: String = "승강기 안전관리자"
const OPERATOR_LABEL: String = "관리주체"

const STATUS_LABELS: Dictionary = {
	"normal": "정상",
	"busy": "혼잡 운행",
	"self_check_due": "자체점검 필요",
	"inspecting": "점검 중",
	"warning": "경고",
	"fault": "운행중지"
}

const ACTION_LABELS: Dictionary = {
	"self_check": "자체점검",
	"preventive": "예방정비",
	"emergency": "긴급보수",
	"vendor": "유지관리업체 호출",
	"notice": "안전안내 강화",
	"upgrade": "설비개선"
}

const COMPONENTS: Array[String] = [
	"비상통화장치", "문열림출발방지장치", "출입문 잠금장치", "제어반", "구동기",
	"과속조절기", "추락방지안전장치", "완충기", "가이드레일", "매다는장치"
]
