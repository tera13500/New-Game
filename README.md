# Elevator Safety Tycoon v1.1.10

엘리베이터 2대를 운영하며 안전/점검/민원/만족도를 관리하는 도트 감성 데스크톱 시뮬레이션 게임입니다.
플레이어는 건물 운영 책임자로서 고장을 줄이고 일일 목표를 달성해 예산과 안전 지표를 유지해야 합니다.

## 1.1.10 핵심 변경
- 액션/업그레이드/캠페인 비용을 `GameBalance.gd`로 통합해 UI 표시와 실제 차감 로직을 일치시킴
- 타이틀/메인/팝업/버튼 스타일을 픽셀 프레임 계열로 통일
- 튜토리얼을 하이라이트 마스크 + 실습 2단계(정기점검, 호기 선택)로 강화
- BuildingView에 샤프트 프레임/층 라인/도어 상태/상태 아이콘 연출 추가
- recent log를 아이콘+색상 기반 항목형 리스트로 개선
- 이벤트 다양성을 12개+ 유지(major/minor/info 균형)

## 핵심 플레이 루프
1. 상단 카드와 BuildingView로 상태 확인
2. 액션 버튼(정기점검/예방정비/긴급수리/업그레이드/안내강화)에서 비용과 효과를 보고 선택
3. Major 이벤트는 팝업에서 판단, Minor/Info 이벤트는 로그에서 추적
4. Day 리포트로 목표 달성 여부와 다음 우선순위 점검

## 시작 흐름
- 타이틀에서 `튜토리얼 시작` 또는 `바로 시작` 선택
- 튜토리얼 중에는 라운드/이벤트 진행이 정지됨
- 튜토리얼 종료 시 자동으로 Day 운영 시작

## 이벤트 구조
- **Major**: 중요 의사결정 팝업
- **Minor**: 자동 처리 + 로그 안내
- **Info**: 긍정/중립 운영 메시지

## 폰트/테마 안내
- 프로젝트는 `themes/PixelTheme.tres`를 통해 픽셀 프레임 스타일과 텍스트 계층(Heading/SubTitle/Small)을 적용합니다.
- 현재 저장소에는 별도 한글 픽셀 폰트 바이너리를 포함하지 않았습니다. 폰트 자산 추가 시 Theme 슬롯에 바로 연결할 수 있게 구조를 정리했습니다.

## 실행 방법 (Godot 4.6.x)
1. Godot 4.6.x로 프로젝트 열기
2. 메인 씬: `scenes/TitleScreen.tscn`
3. 실행 후 시작 모드 선택

## 주요 파일
- `scripts/config/GameBalance.gd`: 비용/확률/제한 상수
- `scripts/config/GameText.gd`: 튜토리얼 문구/포커스 데이터
- `scripts/Main.gd`: 라운드 흐름, 튜토리얼, 로그, 팝업 제어
- `scenes/components/BuildingView.tscn`, `scripts/ui/BuildingView.gd`: 중심 운영 화면
- `scenes/components/ActionPanel.tscn`, `scripts/ui/ActionPanel.gd`: 비용 표시 액션 패널
