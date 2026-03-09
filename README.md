# Elevator Safety Tycoon (Godot 4 MVP+)

엘리베이터 2대(5층 건물)를 운영하며 **정기점검/예방정비/긴급수리/안전홍보 캠페인/업그레이드**를 선택해
안전 점수, 만족도, 민원, 예산을 동시에 관리하는 데스크톱 시뮬레이션 게임입니다.

## 이번 고도화 핵심
- 시각 퀄리티 강화
  - BuildingView 층별 대기 게이지, 상태 마커(●/⚠/⛔/🛠), 선택 호기 강조
- 전략성 강화
  - A/B 호기 특성 차등(빠른 대신 취약 / 느리지만 안정)
  - Day 목표 시스템(무고장, 민원 억제, 점검률 회복 등) + 달성 보너스
- 시스템 전문성 강화
  - 이벤트가 특정 호기를 타겟팅하고 해당 호기에 우선 적용
  - fault 전용 수리 처리 및 부품 회복 일관화
  - 캠페인 효과가 이벤트 빈도/민원 압력에 실제 반영

## 실행
1. Godot 4.x로 프로젝트 열기
2. `scenes/Main.tscn` 실행

## 주요 구조
- `scripts/GameState.gd`: 운영/부품/캠페인/목표/리포트 계산
- `scripts/EventManager.gd`: 타겟 호기 기반 이벤트 생성
- `scripts/ui/BuildingView.gd`: 중앙 상황판 시각화 및 선택 호기 강조
- `scripts/ui/RoundReportPopup.gd`: 운영 리포트 + 목표 달성 결과
- `scripts/managers/UnlockManager.gd`: 도감/칭호 해금
