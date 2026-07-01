# APP_FEATURE_STATUS — 앱 전 기능 실제 작동 점검 (실코드 근거)

> 목적: 앱(C:\dev\ssambership_app) 하단 5탭의 모든 기능이 **실제로 구현·작동하는지** 코드로 판정.
> 판정: **완전작동 / 부분구현 / 미완·스텁 / 깨짐**. 근거는 실제 파일:라인(Supabase 쿼리 연결·버튼 배선·스텁 마커).
> 이번 턴 **코드 수정 0**(점검·문서만). 색 토큰 미터치. 작성일: 2026-07-02.
> 방법: 탭별 read-only 코드 탐색 5건 + 스텁 마커 grep + 기존 docs(FEATURE_AUDIT·CANON_SYNC_TODO) 대조.

---

## 🆕 2026-07-02 구현 배치(부족 기능 12건) — 결과

무인 배치로 아래를 구현·커밋(각 독립 커밋, 각 커밋 전 flutter test·analyze 통과). **DB·Storage 변경 0, color_tokens 미터치.**

| # | 작업 | 상태 | 비고(인프라 의존) |
|---|---|---|---|
| 1 | 질문 이미지 첨부 | ✅ 선택 동작 / 업로드 graceful | **버킷 필요**: `question-attachments`(+방참여자 정책) 생성 후 `attachment_upload.dart:96 _storageReady=true` |
| 2 | 알림 설정 토글 저장 | ✅ graceful | **컬럼 필요**: `users.notification_enabled`(bool)+본인 update RLS |
| 3 | 프로필 수정 | ✅ 동작 | `users.nickname`·`grade_level` update(본인 RLS) — 이미 있으면 즉시 작동 |
| 4 | 멘토찾기→질문방 탭 전환 | ✅ 동작 | TabNavigator 사용, 인프라 불필요 |
| 5 | 커뮤니티 조회수 증분 | ✅ graceful | **RPC 필요/확인**: `increment_community_post_view`·`increment_shortform_post_view`(웹 사용중) |
| 6 | 커뮤니티 페이징·무한스크롤 | ✅ 동작 | 게시판·숏폼 완성. 댓글은 repo 파라미터만 준비(UI는 기존) |
| 7 | 숏폼 반응 초기 로드 | ✅ 동작 | `shortform_reactions` 조회 |
| 8 | 질문방 목록 주간 잔여 표시 | ✅ 동작 | RPC `get_weekly_question_usage` |
| 9 | 연결노트 진입 위치 | ✅ 이미 충족 | 오너 체크포인트(AppBar 라벨 버튼)+허브 EntranceCard. 별도 커밋 없음 |
| 10 | 구독 status 세분화 | ✅ 동작 | 정본 라벨(이용 중/결제 확인 필요/해지됨/만료됨/환불됨/대기 중). 표시만 |
| 11 | 커뮤니티 라벨·순서 정본 | ✅ 동작 | study='학습법', 순서 study·school·career·college·free |
| 12 | 알림 딥링크·분류 정본 | ✅ 동작(분류) | 정본 키워드 관대 매칭. 딥링크는 탭 라우팅(푸시 인프라 미접촉) |

### ★ 오너가 Supabase에서 만들어야 할 인프라(아침에 바로) — 이 배치가 '준비되면 자동 작동'하도록 짜둠
1. **[작업1] Storage 버킷 `question-attachments`** + '방 참여자만 read/write' 정책 → 생성 후 `lib/features/question_room/data/attachments/attachment_upload.dart:96` 의 `_storageReady=false→true`. (버킷명은 웹과 통일할 것 — 다르면 같은 파일 `bucket` 상수도 수정.)
2. **[작업2] `users.notification_enabled` boolean 컬럼** + 본인 update RLS → 알림 토글이 자동 영속화. (컬럼명은 `notification_settings_repository.dart:16 column` 상수와 일치시킬 것.)
3. **[작업5] 조회수 증분 RPC 존재 확인**: `increment_community_post_view(p_post_id)`·`increment_shortform_post_view(p_post_id)`. 웹이 이미 사용 중이라 있을 가능성 높음 — 없으면 조회수만 안 오름(앱은 조용히 무시, 안 죽음).
4. **[작업8·A2] RPC `get_weekly_question_usage(p_student_id,p_mentor_id)`** 존재·정상 동작(이미 A2에서 사용). + (선택)서버측 한도 강제 트리거는 별건.
5. **[참고] 프로필/설정/첨부는 모두 graceful** — 위 인프라가 없어도 앱은 죽지 않고 "준비 중"/로컬 유지로 동작한다.

---

## ★ 먼저: 미완·깨짐 요약 (출시 전 판단할 것)

**하드 '깨짐(에러·크래시)'은 0건.** 코어 Q&A 루프(질문 작성→답변→확인)와 조회 기능들은 실제 Supabase에 연결되어 작동한다.
문제는 **'보이지만 실제로는 안 되는' 기능 8종**과 **인프라 대기 스텁**이다.

### 🔴 '보이지만 실제로는 안 되는' 기능 (사용자가 눌렀는데 반응 없음/저장 안 됨)
| # | 기능 | 증상 | 근거 | 종류 |
|---|---|---|---|---|
| 1 | **구독/충전/결제·정산·프로필편집/약관 버튼** | 눌러도 웹 안 열리고 "준비 중" 스낵바만 | `web_bridge_config.dart:14` `baseUrl=''` | **오너 설정값**(URL 확정 시 즉시 동작) |
| 2 | **채팅 이미지/파일 첨부** | 첨부 버튼 보이나 "준비 중(저장소/ image_picker 인수인계)" | `chat_screen.dart:149-164`, `mentor_answer_screen.dart:154-168`, `attachment_upload.dart:61,96` | **인프라**(Storage 버킷 + image_picker 패키지) |
| 3 | **숏폼 영상 재생** | 재생 아이콘 보이나 눌러도 재생 안 됨(썸네일만) | `thumbnail_view.dart:6,29`, `shortform_card.dart:10`, `community_models.dart:67` | **인프라/패키지**(video player 미도입) |
| 4 | **숏폼 좋아요/스크랩** | 토글은 되나 기존 반응 상태 미로드 → 항상 꺼진 것으로 보임 | `shortform_detail_screen.dart:42-47`(initState에 상태로드 없음) | **앱만** |
| 5 | **커뮤니티 조회수** | "조회 N" 표시되나 글 진입해도 증가 안 함 | `community_read_repository.dart`(incrementView 부재) | **인프라**(증분 RPC) |
| 6 | **알림 딥링크** | 알림 눌러도 해당 글/스레드로 안 가고 탭만 전환 | `deep_link_service.dart:12`(TODO), `notifications_screen.dart:146-152` | 앱+인프라(푸시) |
| 7 | **설정 알림 토글** | 켜고/꺼도 저장 안 됨(재진입 시 기본값) | `settings_section.dart:25-46`(로컬 상태만) | **앱만**(+ 저장 백엔드) |
| 8 | **회원가입 링크** | "웹에서 가입" 눌러도 "링크 준비 중" | `login_screen.dart:76` | 오너 설정값 |

### 🟠 미완·스텁 (기능 골격만, 실행 인프라 대기)
- **푸시 알림 전체** — FCM 미도입 + `device_tokens` 테이블 없음 + Edge Function `send-push` 미배포 + 트리거 미연결. (`lib/core/push/*`, HANDOFF.md) → **인프라**
- **커뮤니티 목록 페이징** — 전체 로드(limit/offset 없음). 데이터 많아지면 성능 저하. (`community_read_repository.dart:23-59`) → 앱만
- **딥링크 라우팅** — 골격만(스트림 구독·경로 매핑 미구현). → 앱+인프라
- **온보딩** — 진입→로그인 골격만(`onboarding_screen.dart:8`). → 앱만
- **요금제 라벨/가격/문항수 상수** — `plan_constants.dart` 전부 비움/TODO(요금제명 미표시). → 오너 확정값

### 실질 출시 판단(핵심)
- **가장 크리티컬(코어 수익 동선)**: #1 `baseUrl` 미설정 → 구독·충전·결제가 전부 "준비 중". 구독형 앱인데 **가입·구독 진입이 막힘**. URL만 확정하면 즉시 해제(앱 코드 한 곳). **출시 전 필수.**
- **범위 의존**: 숏폼(#3 재생)·첨부(#2)를 출시 범위에 넣으면 그 기능은 미완 노출 → 범위 제외하거나 가려야 함.
- **UX 저하(비차단)**: 딥링크·조회수·숏폼반응·알림토글·페이징·푸시 — 코어 작동엔 지장 없음.

---

## 집계
| 판정 | 건수 | 비고 |
|---|---|---|
| **완전작동** | 25 | 실제 Supabase 쿼리·배선 완결 |
| **부분구현** | 7 | 일부만 동작(위 🔴 다수) |
| **미완·스텁** | 6 | 골격/인프라 대기(위 🟠) |
| **깨짐** | 0 | 크래시·에러 없음 |

---

## 탭별 상세

### 1) 질문방 (question_room)
| 기능 | 판정 | 근거(파일:라인) | 사용자 영향 | 종류 |
|---|---|---|---|---|
| 멘토방 목록+구독상태 | 완전작동 | `question_room_screen.dart:79-96`(myRooms·SubscriptionReader·MentorLookup 실쿼리) | 없음 | 앱 |
| 방 진입 | 완전작동 | `mentor_room_home_screen.dart:43-59`, `student_room_home_screen.dart:50-81` | 없음 | 앱(RLS) |
| 질문 스레드 목록 | 완전작동 | `question_list_screen.dart:50`, `read_repository.dart:38-45` | 없음 | 앱 |
| 질문작성+과목필터(A1)+주간한도(A2) | 완전작동 | `new_question_screen.dart:44-96`(mentorTeachingSubjects·weeklyUsage RPC·createThread INSERT) | 없음 | 앱(단, A2 서버강제는 DB 트리거 필요) |
| 채팅·답변보기·실시간 | 완전작동 | `chat_screen.dart:91-128`, `thread_realtime.dart:27-87`(postgres_changes) | 실시간은 publication 필요, 미포함시 수동새로고침 폴백 | **인프라**(realtime publication) |
| 첨부(이미지/파일) | 부분구현 | `attachment_upload.dart:61,96`(disabled), `chat_screen.dart:149-164`(준비중 안내), 표시 미연결 | 🔴 첨부 불가 | **인프라**(Storage 버킷+image_picker) |
| 연결노트(읽기/쓰기) | 완전작동 | `connection_notes_screen.dart:58-97`(notes·upsertMyNote 실쿼리) | 없음 | 앱 |
| 답변 확인(confirm) | 완전작동 | `question_list_screen.dart:207-221`, `write_repository.dart:76-99`(UPDATE) | 없음 | 앱 |

### 2) 커뮤니티 (community)
| 기능 | 판정 | 근거 | 사용자 영향 | 종류 |
|---|---|---|---|---|
| 게시판 목록+카테고리 | 완전작동 | `board_list_view.dart:25-39`(community_posts 실쿼리, .eq('category')) | 없음 | 앱 |
| 게시글 상세 | 완전작동 | `board_detail_screen.dart:47,59-71,176-184` | 없음 | 앱 |
| 댓글 목록·작성 | 완전작동 | `community_read/write_repository.dart:52-91`(select/insert) | 없음 | 앱 |
| 좋아요/스크랩(게시판) | 완전작동 | `board_detail_screen.dart:57-110`(post_reactions toggle) | 없음 | 앱 |
| 좋아요/스크랩(숏폼) | 부분구현 | `shortform_detail_screen.dart:42-47`(초기 상태 로드 없음 → 항상 false) | 🔴 기존 반응 안 보임 | 앱만 |
| 신고 | 완전작동 | `report_sheet.dart:18-78`, `write_repository.dart:105-113`(content_reports insert) | 없음 | 앱 |
| 숏폼 목록(feed) | 완전작동 | `shortform_feed_view.dart:28,38`(shortform_posts 실쿼리) | 없음 | 앱 |
| 숏폼 영상 재생 | 미완·스텁 | `thumbnail_view.dart:6,29`(재생 플러그인 없음, 썸네일+아이콘만) | 🔴 재생 불가 | **패키지/인프라**(video player+Storage) |
| 조회수 집계 | 미완 | `community_read_repository.dart`(incrementView 부재) | 🔴 조회수 안 오름 | **인프라**(증분 RPC) |
| 목록 페이징 | 미완 | `community_read_repository.dart:23-59`(전체 로드) | 데이터 많아지면 느림 | 앱만 |

### 3) 멘토찾기 (mentors)
| 기능 | 판정 | 근거 | 사용자 영향 | 종류 |
|---|---|---|---|---|
| 멘토 목록 로드 | 완전작동 | `mentor_directory_repository.dart:29`(rpc mentor_directory_list_v2), :90,:106(프로필·플랜) | 없음 | 앱(RPC) |
| 검색/필터 | 부분구현 | `mentors_screen.dart:177-182`(클라이언트 필터만, 서버 필터 없음) | 정확일치·필드 제한 | 앱만 |
| 정렬(최신/이름) | 완전작동 | `mentors_screen.dart:27,184-196` | 없음(인기순은 지표없어 제외) | 앱 |
| 상세 프로필 | 완전작동 | `mentor_detail_screen.dart:30-69`, `repo.fetchExtras`(get_mentor_avg_response_hours RPC) | 없음 | 앱(RPC) |
| 가격 표시 | 완전작동 | `mentor_models.dart:25-26,143-147`(mentor_plans 실값, 하드코딩 아님) | 없음 | 앱 |
| 구독하기 버튼 | 부분구현 | `mentor_card.dart:99`, `mentor_detail_screen.dart:109`→`openSubscribeWeb`; `web_bridge_config.dart:14`(baseUrl='') | 🔴 웹 안 열림("준비 중") | 오너 설정값 |

### 4) 알림 (notifications)
| 기능 | 판정 | 근거 | 사용자 영향 | 종류 |
|---|---|---|---|---|
| 알림 목록 로드 | 완전작동 | `notifications_repository.dart:38-43`(notifications 실쿼리) | 없음 | 앱 |
| 유형 표시(3종+기타) | 완전작동 | `app_notification.dart:27-58`(분류) | 공지·리뷰 등은 '기타'로 뭉침(의도) | 앱 |
| 유형 필터 탭 | 완전작동 | `notifications_screen.dart:177-204` | 없음 | 앱 |
| 읽음/모두읽음 | 완전작동 | `notifications_repository.dart:56-72`(UPDATE) | 없음 | 앱 |
| 딥링크 | 부분구현 | `deep_link_service.dart:12`(TODO), `notifications_screen.dart:146-152`(탭 전환만) | 🔴 특정 글/스레드로 못 감 | 앱+인프라 |
| 푸시 인프라 | 미완·스텁 | `push_ports.dart:39`, `device_token_registrar.dart:13`(_tableExists=false), `edge_function_push_sender.dart:17`(_deployed=false), `push_trigger.dart`(미연결) | 푸시 안 옴 | **인프라**(FCM+device_tokens+Edge Function) |

### 5) 마이페이지 (mypage)
| 기능 | 판정 | 근거 | 사용자 영향 | 종류 |
|---|---|---|---|---|
| 프로필(이름·이메일·학년) | 완전작동 | `mypage_repository.dart:60-80`(users 실쿼리) | 없음 | 앱 |
| 구독현황+주간잔여 | 완전작동 | `mypage_repository.dart:83-113`(get_weekly_question_usage RPC), `student_subscription_section.dart:93-102` | 없음(직전 수정 반영) | 앱(RPC) |
| 구독 상태 | 완전작동(2분기) | `mypage_models.dart:73-74`(active/만료만) | 만료예정·결제실패 구분 없음(별도 TODO) | 앱만 |
| 캐시 잔액+내역 | 완전작동 | `mypage_repository.dart:116-152`(cash_wallets·cash_ledger 실쿼리) | 없음 | 앱 |
| 충전/결제·구독관리 버튼 | 부분구현 | `web_bridge_actions.dart:21-36`; `web_bridge_config.dart:14`(baseUrl='') | 🔴 웹 안 열림("준비 중") | 오너 설정값 |
| 설정: 로그아웃 | 완전작동 | `settings_section.dart:65-71`(AuthService.signOut) | 없음 | 앱 |
| 설정: 알림 토글 | 부분구현 | `settings_section.dart:25-46`(로컬 상태만) | 🔴 저장 안 됨 | 앱만 |
| 설정: 약관·개인정보 | 미완·스텁 | `settings_section.dart:78-82`("준비 중") | 열람 불가 | 오너 설정값/웹 |
| 멘토 대시보드 | 완전작동 | `mypage_repository.dart:154-184`(rooms·threads·settlement_items 실쿼리) | 없음 | 앱 |

---

## 인프라 필요 항목 (앱만으로 못 고치는 것)
| 항목 | 필요 인프라 | 영향 기능 | 인수인계 문서 |
|---|---|---|---|
| 웹 도메인 확정 | `WebBridgeConfig.baseUrl` 설정값(오너) | 구독·충전·결제·정산·프로필편집·회원가입 | (S12) `web_bridge_config.dart` 주석 |
| Storage 버킷 + image_picker | `question-attachments` 버킷 생성 + 패키지 도입 | 채팅 첨부 | (S6) `attachment_upload.dart` |
| Realtime publication | question_messages·question_threads를 `supabase_realtime`에 포함 | 실시간 채팅(미포함시 폴백) | (S6) `thread_realtime.dart:23` |
| 숏폼 video player | video player 패키지 + 재생 배선 | 숏폼 영상 | `thumbnail_view.dart` |
| 조회수 증분 RPC | `increment_*_view` RPC | 커뮤니티 조회수 | `community_*_repository` |
| 푸시 인프라 | FCM 도입 + `device_tokens` 테이블 + Edge Function `send-push` 배포 + 트리거 연결 | 푸시·딥링크 | (S7) `lib/core/push/HANDOFF.md` |
| A2 서버강제(선택) | question_threads INSERT 트리거 | 주간한도 우회 방지 | `DB_VERIFY_QUERIES.md` A2-Q3 |
| 요금제 상수 | 요금제명·가격·문항수 확정값 | 요금제 라벨 표시 | `plan_constants.dart` |

## 앱만으로 수정 가능한 것 (인프라 불필요)
- 숏폼 좋아요/스크랩 초기 상태 로드(initState) — `shortform_detail_screen.dart`
- 커뮤니티 목록 페이징(limit/offset 쿼리) — `community_read_repository.dart`
- 알림 토글 저장(로컬 영속화) — `settings_section.dart`
- 멘토 검색 서버필터/구독상태 다분기 — (표시·정합, CANON_SYNC_TODO 참조)
- `baseUrl` 한 줄 채우기(오너가 URL만 주면 앱 반영) — 구독/충전/결제 동선 전체 해제

---

## 판정 근거 방법
- 탭별 read-only 코드 탐색(질문방·커뮤니티·멘토찾기·알림·마이페이지) + `lib/**/*.dart` 스텁 마커 grep(TODO/골격/준비중/인수인계/미구현) + 기존 `FEATURE_AUDIT.md`·`CANON_SYNC_TODO.md` 대조.
- '완전작동' = 화면이 실제 `.from()/.rpc()`로 데이터를 읽고, 버튼이 실제 write/액션 함수에 연결됨(목데이터·빈 함수 아님).
- '부분/미완' = 일부만 동작하거나 골격·안내만. '깨짐' = 크래시/에러(이번 점검 0건).

---
_(끝) 이번 턴 코드 수정 0. 점검·문서만. color_tokens 미터치, DB 변경 0._
