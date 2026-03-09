# Elevator Safety Tycoon (Godot 4 MVP)

엘리베이터 2대(5층 건물)를 운영하며 **점검/예방정비/긴급수리/업그레이드**를 선택해
안전 점수, 만족도, 민원, 예산을 동시에 관리하는 데스크톱용 시뮬레이션 MVP입니다.

## 현재 MVP 포함 기능
- 상단 상태바: 예산/안전/만족/점검률/민원/시간
- 중앙 건물 뷰: 5층 수요, 엘리베이터 A/B 위치 및 상태 애니메이션
- 우측 상세 패널: 선택 엘리베이터 상태/층/마모/위험/점검/업그레이드
- 액션 버튼: 정기점검, 예방정비, 긴급수리, 업그레이드, 안내강화
- Tick 기반 시간 흐름 + Day 라운드 종료
- 랜덤/조건 이벤트 팝업(선택지 기반 결과 반영)
- Day 리포트 팝업

## 실행
1. Godot 4.x로 프로젝트 열기
2. `scenes/Main.tscn` 실행 (기본 main scene으로 설정됨)

## 기본 구조
- `scenes/Main.tscn`
- `scenes/components/BuildingView.tscn`
- `scenes/components/ActionPanel.tscn`
- `scenes/components/EventPopup.tscn`
- `scenes/components/RoundReportPopup.tscn`
- `scripts/Main.gd`
- `scripts/GameState.gd`
- `scripts/EventManager.gd`
- `scripts/RoundManager.gd`
- `scripts/data/ElevatorData.gd`
- `scripts/data/EventData.gd`
- `scripts/ui/*.gd`
