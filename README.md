# Elevator Safety Tycoon v1.1.8

Godot 4.6.x + GDScript 기반 데스크톱 엘리베이터 운영/안전관리 시뮬레이션 게임입니다.

## v1.1.8 핵심 개선
- 타이틀 화면 추가: 게임 설명/시작하기/튜토리얼 동선 제공
- 단계형 온보딩 오버레이 추가: 초보자 첫 진입 혼란 완화
- 이벤트 등급 정리: Major는 팝업, Minor는 자동 처리 + 최근 로그
- 팝업 빈도 완화: 일일 Major 팝업 수 제한 + 틱 쿨다운
- 메인 화면 로그 패널 추가: 최근 이벤트 5개를 스크롤 없이 확인
- UX 안정화: 팝업/튜토리얼/도감 중 라운드 일시정지 일관성 유지
- 버전 표기/프로젝트 메타를 1.1.8로 업데이트

## 실행
1. Godot 4.6.x로 프로젝트 열기
2. 타이틀 화면(`scenes/TitleScreen.tscn`)에서 `튜토리얼 시작` 또는 `바로 시작` 선택

## 주요 구조
- `scenes/TitleScreen.tscn`: 타이틀/게임 소개/진입 동선
- `scripts/ui/TitleScreen.gd`: 시작 버튼 흐름 제어
- `scripts/Main.gd`: 온보딩, 이벤트 팝업 빈도 제어, 최근 로그
- `scripts/EventManager.gd`: Major/Minor 이벤트 분류 데이터
- `scripts/GameState.gd`: 핵심 시뮬레이션 상태/행동 로직
