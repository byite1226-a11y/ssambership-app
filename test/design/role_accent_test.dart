import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssambership_app/core/auth/auth_service.dart';
import 'package:ssambership_app/design/role_accent.dart';

void main() {
  group('RoleAccent.forRole', () {
    test('멘토는 초록(#059669)', () {
      expect(RoleAccent.forRole(AppRole.mentor).accent, const Color(0xFF059669));
    });
    test('학생은 파랑(#2563EB)', () {
      expect(RoleAccent.forRole(AppRole.student).accent, const Color(0xFF2563EB));
    });
    test('공개/게스트/관리자는 파랑 폴백', () {
      expect(RoleAccent.forRole(AppRole.guest).accent, const Color(0xFF2563EB));
      expect(RoleAccent.forRole(AppRole.admin).accent, const Color(0xFF2563EB));
    });
    test('accentMuted 는 각 역할의 진한 변형', () {
      expect(RoleAccent.forRole(AppRole.mentor).accentMuted, const Color(0xFF047857));
      expect(RoleAccent.forRole(AppRole.student).accentMuted, const Color(0xFF1D4ED8));
    });
  });
}
