extends Node
class_name EventManager

func get_event_for_state(game_state: GameState) -> EventData:
	var forced := _pick_condition_event(game_state)
	if forced != null:
		return forced
	if randf() < 0.38:
		return _pick_random_event()
	return null

func _pick_condition_event(game_state: GameState) -> EventData:
	for elevator in game_state.elevators:
		if elevator.status == "fault":
			return EventData.new(
				"fault_real",
				"실제 고장 발생",
				"%s에서 실제 고장이 발생했습니다. 즉시 대응이 필요합니다." % elevator.name,
				"fault",
				"elevator_fault",
				[
					{"label": "긴급수리 즉시 진행 (-5200)", "effect": {"money": -5200, "safety": 2.0, "satisfaction": 3.0, "complaints": -2, "risk": -18.0, "wear": -8.0, "log": "고장 긴급 대응"}},
					{"label": "반나절 후 처리 (비용 절감)", "effect": {"money": -2600, "safety": -4.0, "satisfaction": -6.0, "complaints": 2, "risk": 10.0, "log": "고장 대응 지연"}}
				]
			)
	if game_state.complaints >= 10:
		return EventData.new(
			"complaint_spike",
			"경미한 민원 급증",
			"대기 불만 민원이 누적되었습니다.",
			"warning",
			"complaints_high",
			[
				{"label": "안내 인력 배치 (-1200)", "effect": {"money": -1200, "satisfaction": 3.0, "complaints": -2, "log": "민원 대응 인력 배치"}},
				{"label": "추이를 관찰한다", "effect": {"satisfaction": -2.0, "complaints": 1, "log": "민원 방치"}}
			]
		)
	if game_state.inspection_rate < 45.0:
		return EventData.new(
			"inspection_overdue",
			"정기점검 기한 초과",
			"정기점검 이행률이 크게 떨어졌습니다.",
			"risk",
			"inspection_low",
			[
				{"label": "오늘 전수 점검 (-3000)", "effect": {"money": -3000, "safety": 4.0, "risk": -8.0, "log": "전수 점검 실행"}},
				{"label": "다음날 점검", "effect": {"safety": -3.0, "risk": 5.0, "complaints": 1, "log": "점검 연기"}}
			]
		)
	return null

func _pick_random_event() -> EventData:
	var pool: Array[EventData] = [
		EventData.new("door_delay", "문 닫힘 지연", "출근 시간 문 닫힘 지연이 반복됩니다.", "warning", "random", [
			{"label": "센서 민감도 조정 (-900)", "effect": {"money": -900, "satisfaction": 1.0, "risk": -2.0, "log": "문 지연 즉시 조정"}},
			{"label": "경과 관찰", "effect": {"satisfaction": -1.0, "complaints": 1, "risk": 1.0, "log": "문 지연 관찰"}}
		]),
		EventData.new("door_sensor", "문 센서 이상", "문 센서 감도가 떨어져 안전 여유가 감소했습니다.", "risk", "random", [
			{"label": "센서 교체 (-1800)", "effect": {"money": -1800, "safety": 2.0, "risk": -5.0, "log": "문 센서 교체"}},
			{"label": "소프트 보정", "effect": {"money": -600, "safety": -1.0, "risk": 2.0, "log": "센서 임시 보정"}}
		]),
		EventData.new("floor_miss", "층 정지 오차", "정차 오차 신고가 들어왔습니다.", "warning", "random", [
			{"label": "즉시 캘리브레이션 (-1400)", "effect": {"money": -1400, "satisfaction": 1.0, "risk": -3.0, "log": "정차 오차 조정"}},
			{"label": "다음 점검 때 처리", "effect": {"complaints": 1, "satisfaction": -1.0, "risk": 1.5, "log": "정차 오차 지연"}}
		]),
		EventData.new("button_lag", "버튼 반응 불량", "호출 버튼 반응 속도가 느립니다.", "warning", "random", [
			{"label": "버튼 모듈 교체 (-1100)", "effect": {"money": -1100, "satisfaction": 2.0, "complaints": -1, "log": "버튼 모듈 교체"}},
			{"label": "안내문 게시", "effect": {"satisfaction": -0.5, "complaints": 1, "log": "버튼 지연 안내만 진행"}}
		]),
		EventData.new("noise_vibration", "소음/진동 증가", "야간 시간대 소음 민원이 들어왔습니다.", "risk", "random", [
			{"label": "방진 패드 교체 (-1600)", "effect": {"money": -1600, "safety": 1.0, "risk": -4.0, "log": "방진 패드 교체"}},
			{"label": "다음 라운드로 이월", "effect": {"satisfaction": -2.0, "complaints": 1, "risk": 2.0, "log": "소음 대응 이월"}}
		]),
		EventData.new("overload_warn", "과부하 경고", "혼잡 시간 과부하 경고가 다수 발생했습니다.", "warning", "random", [
			{"label": "혼잡 안내 강화 (-700)", "effect": {"money": -700, "complaints": -1, "risk": -1.5, "log": "과부하 안내 강화"}},
			{"label": "무시", "effect": {"satisfaction": -1.5, "complaints": 1, "risk": 2.0, "log": "과부하 무시"}}
		]),
		EventData.new("inspection_due", "정기점검 기한 도래", "점검 주기가 임박했습니다.", "warning", "random", [
			{"label": "사전 점검 예약 (-800)", "effect": {"money": -800, "safety": 1.0, "risk": -1.0, "log": "사전 점검 예약"}},
			{"label": "추가 운행 우선", "effect": {"safety": -1.0, "risk": 1.2, "log": "점검보다 운행 우선"}}
		]),
		EventData.new("aging_warn", "노후화 경고", "노후화 지표가 상승하고 있습니다.", "warning", "random", [
			{"label": "예방정비 예산 선반영 (-1300)", "effect": {"money": -1300, "risk": -3.0, "wear": -2.5, "log": "노후화 선제 대응"}},
			{"label": "당장 보류", "effect": {"wear": 2.0, "risk": 2.0, "log": "노후화 대응 보류"}}
		]),
		EventData.new("emergency_call", "비상통화 장치 점검 필요", "비상통화 장치 점검 결과 경고가 떴습니다.", "risk", "random", [
			{"label": "즉시 점검 (-1000)", "effect": {"money": -1000, "safety": 2.0, "risk": -2.0, "log": "비상통화 점검"}},
			{"label": "다음 회차 점검", "effect": {"safety": -2.0, "complaints": 1, "log": "비상통화 점검 지연"}}
		]),
		EventData.new("peak_surge", "특정 시간대 수요 폭주", "예상보다 큰 수요가 발생했습니다.", "warning", "random", [
			{"label": "임시 운행 최적화 (-900)", "effect": {"money": -900, "satisfaction": 2.0, "complaints": -1, "wear": 1.5, "log": "수요 폭주 대응"}},
			{"label": "기존 운행 유지", "effect": {"satisfaction": -2.0, "complaints": 2, "log": "수요 폭주 미대응"}}
		])
	]
	return pool[randi_range(0, pool.size() - 1)]
