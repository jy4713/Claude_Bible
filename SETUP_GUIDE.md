# 성경앱 설치 및 실행 가이드

## 1. Flutter SDK 설치

https://docs.flutter.dev/get-started/install/windows 에서 Flutter SDK를 다운로드

```bash
# Flutter PATH 설정 후 확인
flutter --version
flutter doctor
```

## 2. Assets 준비 (이미 완료됨)

```bash
python setup_assets.py
```

## 3. 의존성 설치

```bash
cd bible_app
flutter pub get
```

## 4. Android 빌드 및 실행

```bash
# 연결된 기기/에뮬레이터 목록 확인
flutter devices

# 디버그 모드로 실행
flutter run

# 릴리스 APK 빌드
flutter build apk --release
# → bible_app/build/app/outputs/flutter-apk/app-release.apk
```

## 5. 웹 빌드 및 실행

```bash
# 웹 디버그 실행
flutter run -d chrome

# 웹 릴리스 빌드
flutter build web --release
# → bible_app/build/web/
```

### 웹 SQLite 설정 (추가 필요)

웹에서 SQLite를 사용하려면 `sqflite_common_ffi_web` 패키지 설정이 필요합니다:

1. `pubspec.yaml`에 추가:
   ```yaml
   sqflite_common_ffi_web: ^0.4.3
   ```

2. `web/` 폴더에 sqlite3.wasm 추가:
   - https://pub.dev/packages/sqlite3/versions 에서 다운로드
   - 또는: `dart pub global run sqlite3:download_wasm`

3. `lib/main.dart`에서 web 초기화 추가:
   ```dart
   import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
   // if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
   ```

## 6. 앱 구조

```
성경앱
├── 📖 성경  - 번역 선택, 구약/신약, 장/절 이동, 검색, 비교 (좌우/상하)
├── 🎵 찬송가 - 악보 이미지 + 가사 (새찬송가.cmp ZIP에서 추출)
├── 💬 주석  - 현재 성경 본문 주석 (만나주석.cdb)
└── ⚙️ 설정  - 글자 크기, 테마, 성경/주석/찬송가 파일 관리
```

## 7. DB 파일 추가 방법

설정 탭 → 해당 섹션 → "파일 추가" → `.bdb` / `.cdb` / `.hdb` 선택

지원 형식:
- **성경**: `*.bdb` (Bethlehem Bible DB format)
- **주석**: `*.cdb` (Commentary DB)
- **찬송가**: `*.hdb` (Hymnal DB)
- **찬송가 악보**: `*.cmp` (ZIP of PNG images)

## 8. 비교 모드 사용

1. 성경 화면 → 상단 책 아이콘 탭
2. 비교 토글 ON
3. 레이아웃: 좌우 / 상하 선택
4. 보고 싶은 번역 여러 개 체크
