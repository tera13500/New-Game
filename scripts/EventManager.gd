extends Node
class_name EventManager

func get_event_for_state(game_state: GameState) -> EventData:
	var forced: EventData = _pick_condition_event(game_state)
	if forced != null:
		return forced
	if randf() < 0.44:
		return _pick_weighted_random_event(game_state)
	return null

func _pick_condition_event(game_state: GameState) -> EventData:
	for elevator: ElevatorData in game_state.elevators:
		if elevator.status == "fault":
			return EventData.new(
				"fault_real", "실제 고장 발생", "%s가 정지했습니다. 즉시 대응이 필요합니다." % elevator.name,
				"fault", "elevator_fault",
				[
					{"label":"긴급수리 즉시 진행 (-5200)", "effect":{"money":0, "log":"고장 즉시 대응"}, "fault_action":"immediate"},
					{"label":"임시 격리 후 반나절 지연", "effect":{"log":"고장 대응 지연"}, "fault_action":"delay"},
					{"label":"안내 강화 후 외주 수리", "effect":{"log":"외주 수리 선택"}, "fault_action":"outsource"}
				],
				["emergency_call", "brake_system", "governor"], ["emergency_guide"], "긴급수리", "governor", elevator.id
			)
	if game_state.inspection_rate < 45.0:
		return EventData.new(
			"inspection_overdue", "정기점검 기한 초과", "점검 지연으로 제동/제어계 리스크가 상승했습니다.",
			"risk", "inspection_low",
			[
				{"label":"오늘 전수 점검 (-3000)", "effect":{"money":-3000, "safety":4.0, "risk":-8.0, "log":"전수 점검 실행"}},
				{"label":"내일 점검", "effect":{"safety":-3.0, "risk":5.0, "complaints":1, "log":"점검 연기"}}
			],
			["controller", "brake_system"], [], "정기점검", "controller", -1
		)
	return null

func _pick_weighted_random_event(game_state: GameState) -> EventData:
	var pool: Array[EventData] = _random_pool(game_state)
	var weighted: Array[EventData] = []
	for ev: EventData in pool:
		var copies: int = max(1, int(round(3.0 * game_state.get_event_weight(ev.event_id))))
		for _i: int in copies:
			weighted.append(ev)
	return weighted[randi_range(0, weighted.size() - 1)]

func _random_pool(game_state: GameState) -> Array[EventData]:
	var target: ElevatorData = game_state.elevators[randi_range(0, game_state.elevators.size() - 1)]
	return [
		EventData.new("door_delay", "문 닫힘 지연", "%s 문이 닫히기 전에 재개방되는 빈도가 늘었습니다." % target.name, "warning", "random",
			[{"label":"도어 오퍼레이터 조정 (-900)", "effect":{"money":-900, "risk":-2.0, "satisfaction":1.0, "log":"문 구동 조정"}}, {"label":"관찰", "effect":{"satisfaction":-1.0, "complaints":1, "risk":1.0, "log":"문 지연 관찰"}}],
			["door_operator", "door_sensor"], ["door_safety"], "예방정비", "door_operator", target.id),
		EventData.new("door_sensor", "문 센서 이상", "%s의 센서 감도가 떨어져 끼임 감지가 불안정합니다." % target.name, "risk", "random",
			[{"label":"센서 교체 (-1800)", "effect":{"money":-1800, "safety":2.0, "risk":-5.0, "log":"센서 교체"}}, {"label":"임시 보정", "effect":{"money":-600, "safety":-1.0, "risk":2.0, "log":"임시 보정"}}],
			["door_sensor", "door_interlock"], ["door_safety"], "정기점검", "door_sensor", target.id),
		EventData.new("overload_warn", "과부하 경고", "%s에서 피크 시간 과밀 탑승이 잦아졌습니다." % target.name, "warning", "random",
			[{"label":"과밀 방지 안내 실행 (-700)", "effect":{"money":-700, "complaints":-1, "risk":-1.5, "log":"과밀 방지 안내"}}, {"label":"현상 유지", "effect":{"satisfaction":-1.5, "complaints":1, "risk":1.8, "log":"과밀 대응 미흡"}}],
			["overload_sensor"], ["overload_notice"], "안내강화", "overload_sensor", target.id),
		EventData.new("noise_vibration", "소음/진동 증가", "%s 주행계 진동이 증가했습니다." % target.name, "risk", "random",
			[{"label":"가이드레일 정렬 점검 (-1600)", "effect":{"money":-1600, "risk":-4.0, "safety":1.0, "log":"레일 점검"}}, {"label":"다음 라운드", "effect":{"risk":2.0, "complaints":1, "log":"진동 대응 이월"}}],
			["guide_rail", "hoist_rope", "brake_system"], [], "예방정비", "guide_rail", target.id),
		EventData.new("floor_miss", "층 정지 오차", "%s 정차 위치 오차가 보고되었습니다." % target.name, "warning", "random",
			[{"label":"제어반 캘리브레이션 (-1400)", "effect":{"money":-1400, "risk":-3.0, "satisfaction":1.0, "log":"정차 오차 조정"}}, {"label":"다음 점검 때", "effect":{"complaints":1, "risk":1.2, "log":"정차 오차 지연"}}],
			["controller", "brake_system"], [], "정기점검", "controller", target.id)
	]
