-- S19: individual-question-attachments 버킷 mime 화이트리스트에 application/json 1개 추가
--
-- 배경: S18 첨삭 원본(ink.json)은 {questionId}/annotations/{원본첨부id}.json 을
--       contentType application/json 으로 이 버킷에 업로드한다. 운영 실측(2026-07-07)
--       결과 allowed_mime_types 에 json 이 없어 첫 업로드부터 mime 거부된다
--       (20260707T1130 UPDATE 정책은 재저장 권한만 해결 — mime 는 별개).
-- 범위: 'application/json' 1개 append 만. 기존 허용 타입 삭제·순서 변경·
--       file_size_limit·public 등 다른 설정 변경 없음. 멱등(이미 있으면 no-op).
--       allowed_mime_types 가 null(무제한)인 경우도 no-op — append 가 오히려
--       제한을 만드는 것을 방지.

update storage.buckets
set allowed_mime_types = allowed_mime_types || array['application/json']
where id = 'individual-question-attachments'
  and allowed_mime_types is not null
  and not ('application/json' = any(allowed_mime_types));
