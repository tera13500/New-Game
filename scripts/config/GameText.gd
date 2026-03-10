extends RefCounted
class_name GameText

const TUTORIAL_PAGES: Array[Dictionary] = [
	{"title":"게임 목표", "body":"고장을 줄이고 안전·만족을 유지해 일일 목표를 달성하세요.", "focus":"top"},
	{"title":"상단 자원 카드", "body":"예산/안전/만족/점검률/민원을 먼저 보고 오늘 우선순위를 정합니다.", "focus":"top"},
	{"title":"중앙 BuildingView", "body":"층별 대기량과 A/B호기 상태를 확인하세요. 경고 색상 상태를 우선 확인해 즉시 대응하세요.", "focus":"building"},
	{"title":"우측 운영 패널", "body":"현재 상태, 핵심 장치 TOP3, 권장 액션, 로그 순서로 판단하세요.", "focus":"right"},
	{"title":"실습: 정기점검", "body":"하단 [정기점검] 버튼을 1회 눌러보세요.", "focus":"actions", "requires_action":"inspection"},
	{"title":"실습: 엘리베이터 선택", "body":"우측의 호기 선택에서 다른 호기를 눌러보세요.", "focus":"right", "requires_action":"select_elevator"},
	{"title":"최근 로그", "body":"Minor/Info 이벤트는 로그에서 추적합니다.", "focus":"logs"},
	{"title":"속도 조절", "body":"상단 속도 버튼(1x/2x/3x)으로 운영 템포를 조절할 수 있습니다.", "focus":"top"},
	{"title":"시작 준비 완료", "body":"이제 운영을 시작합니다. 작은 경고를 먼저 잡는 것이 핵심입니다.", "focus":"building"}
]


static func format_number(value: int) -> String:
	var text_value: String = str(value)
	var out: String = ""
	var count: int = 0
	for i: int in range(text_value.length() - 1, -1, -1):
		out = text_value[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
