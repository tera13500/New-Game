# Elevator Safety Tycoon v1.1.7

Godot 4.6.x + GDScript 기반 데스크톱 엘리베이터 운영/안전관리 시뮬레이션 게임입니다.

## v1.1.7 핵심 변경
- 파싱/타입 추론 안정화(명시 타입 보강, `:=` 제거)
- fault 이벤트 긴급수리 시 실제 고장 해제 로직 연결
- 이벤트/업그레이드/도감 팝업 중 라운드 일시정지 일관화
- safety_score 자동 회복 완화(행동 기반 상승 구조 강화)
- 운영 성과 보상 루프 강화(무고장/민원 억제/점검률/만족도/목표 보상)
- 사용자 노출 텍스트에서 내부 ID 제거(장치명 한글화)
- BuildingView 상황판 시각 polish(상태 마커/게이지/선택 강조/pulse)

## 실행
1. Godot 4.6.x로 프로젝트 열기
2. `scenes/Main.tscn` 실행

## 주요 구조
- `scripts/GameState.gd`: 운영/부품/캠페인/목표/보상/리포트 계산
- `scripts/EventManager.gd`: 타겟 호기 기반 이벤트 생성
- `scripts/Main.gd`: UI/팝업 흐름 제어 및 라운드 정지/재개
- `scripts/ui/BuildingView.gd`: 중앙 상황판 시각화
- `scripts/ui/EventPopup.gd`: 이벤트 선택 UI
- `scripts/ui/RoundReportPopup.gd`: 운영 리포트 UI
- `scripts/ui/ComponentCodexPopup.gd`: 부품 도감 UI
