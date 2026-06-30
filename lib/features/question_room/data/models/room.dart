import 'model_parse.dart';

/// 질문방(mentor_student_rooms) 모델 = 학생–멘토 1:1 연결.
///
/// ★ DB에 없는 필드(잔여 질문수·방 상태)는 두지 않는다.
///   잔여수는 구독/결제(subscriptions/payments) 책임이며 이 레이어가 다루지 않는다.
///   (student_id, mentor_id) UNIQUE — 쌍당 방 1개. 앱에서 INSERT 불가(RLS 정책 없음).
class Room {
  const Room({
    required this.id,
    required this.studentId,
    required this.mentorId,
    this.subscriptionId,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String mentorId;
  final String? subscriptionId;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      mentorId: map['mentor_id'] as String,
      subscriptionId: map['subscription_id'] as String?,
      paymentId: map['payment_id'] as String?,
      createdAt: parseTime(map['created_at']),
      updatedAt: parseTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'student_id': studentId,
        'mentor_id': mentorId,
        'subscription_id': subscriptionId,
        'payment_id': paymentId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
