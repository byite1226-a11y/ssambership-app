-- S18: 개별질문 첨삭 원본(ink.json) upsert 를 위한 스토리지 UPDATE 정책
-- (2026-07-07 운영 DB 적용 완료 — 기록용, 재적용 불요.
--  create policy 는 재실행 시 duplicate 에러가 난다.)
--
-- 배경: 첨삭 원본은 {questionId}/annotations/{원본첨부id}.json 에 같은 경로
--       upsert(이어 그리기 저장)된다. 기존 정책은 SELECT/INSERT 뿐이라
--       두 번째 저장부터 UPDATE 정책 부재로 거부되는 잠재 결함이 있었다
--       (fake 주입 테스트라 미검출 — 실서버 검토에서 발견).
-- 범위: UPDATE 는 두 번째 경로 세그먼트가 'annotations' 인 객체로 한정한다.
--       원본 첨부({questionId}/{ts}-{salt}.{ext})는 계속 덮어쓰기 불가 —
--       '첨삭 = 항상 새 첨부, 원본 불변' 규약의 정책 레벨 근거.

create policy iqa_storage_update_party_annotations on storage.objects
  for update to authenticated
  using (
    bucket_id = 'individual-question-attachments'
    and split_part(name, '/', 2) = 'annotations'
    and public.user_is_party_for_individual_question_storage_path(name)
  )
  with check (
    bucket_id = 'individual-question-attachments'
    and split_part(name, '/', 2) = 'annotations'
    and public.user_is_party_for_individual_question_storage_path(name)
  );
