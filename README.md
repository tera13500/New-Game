# Elevator Safety Tycoon v1.1.8

엘리베이터 2대를 운영하며 안전/점검/민원/만족도를 함께 관리하는 데스크톱 시뮬레이션 게임입니다.
플레이어는 건물의 운영 책임자로서 고장을 줄이고, 점검률을 유지하며, 이용자 경험을 안정적으로 관리해야 합니다.

## 핵심 플레이 루프
1. **상태 확인**: 상단 카드(예산·안전·만족·점검률·민원·시간)와 중앙 BuildingView를 확인
2. **운영 액션 선택**: 정기점검 / 예방정비 / 긴급수리 / 업그레이드 / 안내강화
3. **이벤트 대응**: Major 이벤트는 팝업에서 판단, Minor/Info는 최근 로그로 자동 처리
4. **Day 리포트 반영**: 일일 목표 달성 여부와 추천 액션을 다음 Day에 반영

## 시작 흐름 / 튜토리얼
- 타이틀 화면에서 **튜토리얼 시작** 또는 **바로 시작** 선택
- 튜토리얼 시작 시:
  - 메인 진입 후 튜토리얼 오버레이 표시
  - 튜토리얼 동안 라운드 완전 정지
  - 마지막 단계에서 게임 시작
- 바로 시작 시:
  - 튜토리얼 없이 즉시 Day 진행

## 이벤트 처리 구조
- **Major**: 운영 판단이 필요한 중요 이벤트 (팝업)
- **Minor**: 자동 처리 후 최근 로그 기록
- **Info**: 짧은 안내/상태 로그
- 팝업 과다 방지를 위해 연속 중복 팝업과 일일 팝업 횟수를 제한

## 실행 방법 (Godot 4.6.x)
1. Godot 4.6.x로 프로젝트 열기
2. 메인 씬: `scenes/TitleScreen.tscn`
3. 실행 후 시작 모드 선택

## 주요 파일
- `project.godot`: 프로젝트 설정 / 메인 씬 / autoload
- `scenes/TitleScreen.tscn`: 타이틀 UI 및 시작 동선
- `scenes/Main.tscn`: 메인 HUD, 우측 패널, 튜토리얼 오버레이
- `scripts/Main.gd`: 라운드 흐름, 이벤트 처리, 튜토리얼 제어, 최근 로그
- `scenes/components/BuildingView.tscn`, `scripts/ui/BuildingView.gd`: 픽셀 감성 운영 뷰
- `scenes/components/EventPopup.tscn`, `scripts/ui/EventPopup.gd`: 중요 이벤트 팝업 UX
