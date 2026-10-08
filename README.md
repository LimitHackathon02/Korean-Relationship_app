# Korean-Relationship_app — 백엔드 (모바일 앱용)

외국인 유학생이 교수님·선배·알바 사장님 등 상대와의 관계에 맞는 한국어 메시지를 쓰고, 점검하고, 해석하고, 연습하도록 돕는 **API 서버**입니다. HyperCLOVA X(CLOVA Studio) API만 사용합니다.

이 저장소는 **모바일 앱(Flutter Android/iOS)이 호출할 백엔드만** 담고 있습니다. 앱은 같은 Wi-Fi에서 이 서버의 `/api/*`를 HTTP로 호출합니다.

> - 출처: `Korean_Realationship_backfront_V1`의 `backend/` (bf78455) + 앱 접속용 실행 옵션 `-Lan`
> - 웹(Flutter 웹)과 함께 쓰는 버전은 `Korean_Realationship_backfront_V1` 저장소에 있습니다.
> - 무엇을 바꾸려면 어디를 고치는지는 [DEV_GUIDE.md](DEV_GUIDE.md)를 보세요.

## 실행 (Windows PowerShell)

```powershell
# 이 PC에서만 확인할 때
powershell -ExecutionPolicy Bypass -File scripts\start.ps1

# 휴대폰·에뮬레이터 앱에서 접속할 때 (같은 Wi-Fi)
powershell -ExecutionPolicy Bypass -File scripts\start.ps1 -Lan
```

- API 문서(Swagger): http://127.0.0.1:8081/docs (`/`로 들어가도 여기로 이동)
- `-Lan`으로 실행하면 앱에 넣을 주소(에뮬레이터용, 휴대폰용)가 화면에 표시됩니다.

처음 실행하면 `.venv` 생성, 패키지 설치, `.env` 복사가 자동으로 됩니다. 기본은 **MOCK 모드**(실제 호출 없음)입니다.

## HyperCLOVA X 연결

1. CLOVA Studio에서 API 키를 발급받습니다 (해커톤에서는 운영진이 지급하는 키를 사용).
2. `.env`를 엽니다.
   ```
   MOCK_MODE=0
   CLOVA_API_KEY=발급받은_키
   ```
3. 연결 확인: `.venv\Scripts\python.exe scripts\smoke_test.py` (이미지까지: `--image 캡처.png`)
4. 서버를 다시 시작합니다. `GET /api/health`의 `mock`이 `false`면 실제 호출 모드입니다.

모델명이나 주소가 다르게 지급되면 `.env`의 `CLOVA_BASE_URL`, `MODEL_ANALYSIS`, `MODEL_VISION`, `MODEL_LIGHT`를 바꿉니다. API 경로나 파라미터 이름이 바뀌면 [app/hcx/client.py](app/hcx/client.py) 맨 위 상수만 고칩니다.

API 키는 **이 서버의 `.env`에만** 넣습니다. 앱 코드나 빌드 설정에는 넣지 않습니다 (앱을 풀어 보면 보입니다).

## 앱에서 연결하기

### 1. 서버 주소

| 앱을 실행하는 곳 | 앱에 넣을 서버 주소 |
|---|---|
| Android 에뮬레이터 | `http://10.0.2.2:8081` (에뮬레이터에서 PC를 가리키는 고정 주소) |
| iOS 시뮬레이터 (Mac) | `http://127.0.0.1:8081` |
| 실제 휴대폰 (같은 Wi-Fi) | `http://PC의IP:8081` — `start.ps1 -Lan` 실행 화면에 표시됨 |

앱에서 `127.0.0.1`은 휴대폰(에뮬레이터) 자기 자신을 가리키므로 PC의 서버에 닿지 않습니다.

### 2. 휴대폰에서 접속이 안 될 때

1. 서버를 `-Lan`으로 실행했는지 확인합니다 (`0.0.0.0`으로 떠야 외부에서 접속됨).
2. Windows 방화벽에서 8081 포트를 허용합니다. **관리자 권한** PowerShell에서 한 번만 실행합니다.
   ```powershell
   New-NetFirewallRule -DisplayName "Korean-Relationship API 8081" -Direction Inbound -Protocol TCP -LocalPort 8081 -Action Allow -Profile Private
   ```
   Wi-Fi가 "공용 네트워크"로 잡혀 있으면 `-Profile Private`을 `-Profile Any`로 바꾸거나, Windows 설정에서 네트워크를 "개인"으로 바꿉니다.
3. 휴대폰 브라우저로 `http://PC의IP:8081/health`를 열어 `{"status":"ok"}`가 보이는지 확인합니다. 브라우저에서 안 열리면 앱에서도 안 됩니다.
4. 학교·행사장 Wi-Fi는 기기 간 통신을 막아 두는 경우가 있습니다. 그럴 땐 휴대폰 핫스팟에 PC와 휴대폰을 같이 연결합니다.

### 3. Android에서 http 허용 (개발용)

Android는 기본적으로 `http://` 통신을 막습니다. 개발 중에는 앱의 `android/app/src/main/AndroidManifest.xml`에 아래처럼 추가합니다.

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application
    android:usesCleartextTraffic="true"
    ...>
```

스토어에 배포하거나 외부 서버에 올릴 때는 `https` 주소를 사용하고 이 설정은 끕니다.

### 4. 공통 규칙

- 연결 확인: `GET /health` → `{"status":"ok","mock":true|false}`
- `.env`에 `TEAM_API_KEY`를 설정했다면, 모든 `/api/*` 요청에 `X-Team-Key` 헤더로 같은 값을 보냅니다 (`/health`, `/api/health` 제외). 비워 두면 검사하지 않습니다.
- 오류는 항상 `{"detail": "사람이 읽을 수 있는 메시지"}` 형태입니다 (422 입력 오류, 404 없는 상대·세션, 429·5xx HCX 오류).
- AI를 호출하는 모든 응답에는 `meta: {calls: [{model, mock, cached, total_tokens, latency_ms}], total_tokens}`가 붙습니다.
- 한글이 깨지지 않도록 응답은 `utf8.decode(res.bodyBytes)`로 읽습니다.
- `CORS_ORIGINS`는 웹 브라우저용 설정이라 앱에는 영향이 없습니다.

### 5. Flutter 호출 예시 (`http` 패키지)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const api = 'http://10.0.2.2:8081'; // 실제 휴대폰은 http://PC의IP:8081

// ② 코칭
Future<Map<String, dynamic>> coach(String text) async {
  final res = await http.post(
    Uri.parse('$api/api/coach'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'text': text, 'relation': 'professor'}),
  );
  final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  if (res.statusCode != 200) throw Exception(body['detail']);
  return body; // scores, issues[].start/end (원문 하이라이트 위치), revised
}

// ③ 캡처 해석: 카메라·갤러리 사진을 multipart로 전송
Future<Map<String, dynamic>> interpretImage(String imagePath) async {
  final req = http.MultipartRequest('POST', Uri.parse('$api/api/interpret'))
    ..fields['relation'] = 'professor'
    ..files.add(await http.MultipartFile.fromPath('image', imagePath));
  final res = await http.Response.fromStream(await req.send());
  final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  if (res.statusCode != 200) throw Exception(body['detail']);
  return body; // extracted_text, intent, emotion, reply_draft
}
```

이미지는 20MB 이하 PNG/JPEG/WEBP/BMP를 받으며, 서버가 크기를 줄이고 JPEG로 바꿔 HCX에 보냅니다.

## API

| API | 기능 | 주요 응답 필드 | 사용 모델 |
|---|---|---|---|
| `POST /api/compose` | ① 관계·목적·핵심 내용 → 메시지 초안 | `draft`, `notes` | HCX-007 (+임베딩) |
| `POST /api/coach` | ② 내 메시지 점검 | `scores`, `issues[]`(`quote`, `start`, `end`, …), `revised`, `summary` | HCX-007 (+임베딩) |
| `POST /api/interpret` | ③ 받은 메시지(텍스트/캡처) 해석 | `extracted_text`, `intent`, `emotion`, `urgency`, `key_points`, `reply_draft` | HCX-005 → HCX-007 |
| `POST /api/rehearsal/start` · `/{id}/message` · `/{id}/end`, `GET /{id}` | ④ 역할극 연습 → 피드백 리포트 | `session_id`, `reply`, `report` | DASH-002 → HCX-007 |
| `/api/contacts` (CRUD), `/{id}/interactions` | ⑤ 상대 프로필과 지난 기록 | — | — |
| `POST /api/route` | 자유 입력 → 기능 분류 | `feature` | DASH-002 |
| `GET /api/usage` | 기능별·모델별 토큰, 한도, 최근 호출 | — | — |
| `GET /api/domain` | 프론트 선택지 (관계·목적·시나리오) | — | — |
| `GET /api/knowledge/search` | 참고 자료 검색 확인 | — | 임베딩 |
| `GET /api/health` | MOCK 여부, 모델 설정 | — | — |

요청 형식은 [DEV_GUIDE.md](DEV_GUIDE.md) 6-5장이나 `/docs`에서 확인합니다. compose·coach·interpret·rehearsal에 `contact_id`를 넘기면 그 상대의 프로필과 지난 기록이 프롬프트 `{memory}`에 들어가고, 이번 결과가 기록에 추가됩니다.

## 기능별로 떼어 쓰기

**기능 이름 하나가 모든 파일 이름에 똑같이 쓰입니다.** 기능 하나를 가져가거나 빼려면 그 이름의 파일만 찾으면 됩니다.

| 기능 | 라우트 | 서비스 | 프롬프트 · 스키마 (`customize/`) | 테스트 |
|---|---|---|---|---|
| ① compose | `routes/compose.py` | `services/compose.py` | `prompts/compose.md`, `schemas/compose.json` | `test_compose.py` |
| ② coach | `routes/coach.py` | `services/coach.py`, `services/coach_highlight.py` | `prompts/coach.md`, `schemas/coach.json` | `test_coach.py` |
| ③ interpret | `routes/interpret.py` | `services/interpret.py` | `prompts/interpret_ocr.md`, `prompts/interpret.md`, `schemas/interpret.json` | `test_interpret.py` |
| ④ rehearsal | `routes/rehearsal.py` | `services/rehearsal.py`, `stores/rehearsal_store.py` | `prompts/rehearsal_role.md`, `prompts/rehearsal_feedback.md`, `schemas/rehearsal_feedback.json` | `test_rehearsal.py` |
| ⑤ contacts | `routes/contacts.py` | `stores/contact_store.py` | — | `test_contacts.py` |
| route | `routes/route.py` | `services/route.py` | `prompts/route.md` | `test_route.py` |
| usage | `routes/usage.py` | (`hcx/usage.py`) | — | `test_usage.py` |
| knowledge | `routes/knowledge.py` | `services/knowledge.py` | `knowledge/*.md` | `test_knowledge.py` |

**모든 기능이 같이 쓰는 부품** (기능을 가져갈 때 함께 가져가야 함):

| 파일 | 역할 |
|---|---|
| `app/hcx/` | HyperCLOVA X 호출 창구 (MOCK, 캐시, 한도, 사용량 기록) |
| `app/services/shared.py` | `build_prompt_values()` 프롬프트 변수 + 참고 자료 + 메모리, `find_contact()`, `save_interaction()`, `call_meta()` |
| `app/customize.py` | `customize/` 읽기 (요청마다 다시 읽음) |
| `app/core.py`, `app/deps.py`, `app/config.py` | 부품 묶음, 라우트 공통 의존성, `.env` 설정 |
| `customize/domain.yaml` | 서비스명, 관계·목적·격식, 리허설 시나리오, 엔진 설정값 |

**기능 하나를 빼려면**: [app/main.py](app/main.py)에서 그 기능의 `include_router` 줄을 지우고, 위 표의 같은 이름 파일을 삭제합니다. `contacts`를 빼면 다른 기능의 `contact_id`도 쓸 수 없고, `knowledge`를 빼면 `shared.py`의 참고 자료 검색도 함께 정리해야 합니다.

## 구조

```
app/
  main.py             앱 조립, 라우터 연결
  config.py           .env → Settings
  core.py             공통 부품 묶음 (hcx, customize, knowledge, contacts, rehearsals)
  deps.py             라우트 공통 의존성 (X-Team-Key 검사)
  customize.py        customize/ 읽기
  hcx/                HyperCLOVA X 호출 창구 — 모든 호출이 client.py를 거침
  routes/             API 라우트 (파일 하나 = 기능 하나)
  services/           기능 로직 (파일 하나 = 기능 하나) + shared.py
  stores/             SQLite 저장소 (contact_store, rehearsal_store)
customize/            당일 교체 영역 — 코드 수정 없이 서비스 성격 변경
  domain.yaml         서비스명, 관계·목적·격식, 리허설 시나리오, 엔진 설정값
  prompts/*.md        시스템 프롬프트 ({변수} 자리 채움)
  schemas/*.json      Structured Outputs 스키마
  knowledge/*.md      참고 자료 ('## 제목' 단위)
scripts/              start.ps1, smoke_test.py
tests/                pytest (파일 이름 = 기능 이름)
data/                 사용량 로그·캐시·DB (Git 제외)
```

## 주제 공개 당일

```powershell
Select-String -Path customize\*, customize\*\* -Pattern "TODO\(DAY-OF\)"
```

위 명령으로 채울 곳을 찾습니다. 프롬프트·스키마·domain.yaml은 저장하면 서버 재시작 없이 바로 반영됩니다. 스키마 필드 이름을 바꾸면 응답 JSON의 필드 이름도 바뀌므로 프론트도 맞춰야 합니다.

## 크레딧 절약 장치

- `temperature=0` 요청은 응답을 캐시합니다 (`CACHE_TTL_SECONDS`).
- `MAX_LIVE_CALLS`, `TOKEN_STOP_THRESHOLD`에 도달하면 실제 호출을 막습니다.
- 모든 호출은 `data/usage_log.jsonl`에 기능·모델·토큰·지연시간이 기록되고, `GET /api/usage`로 볼 수 있습니다.

## 테스트

```powershell
.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.venv\Scripts\python.exe -m pytest -q
```
