import 'package:flutter/material.dart';

import '../../../../design/tokens/typography.dart';
import '../../../../design/widgets/initial_avatar.dart';
import '../../data/mypage_models.dart';

/// 프로필 헤더(이름·역할·이메일·학년). 값이 없으면 비운다(하드코딩/날조 없음).
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.profile});

  final MyProfile profile;

  @override
  Widget build(BuildContext context) {
    final List<String> sub = <String>[
      if (profile.roleLabel.isNotEmpty) profile.roleLabel,
      if (profile.grade != null) profile.grade!,
    ];
    return Row(
      children: <Widget>[
        InitialAvatar(name: profile.name, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                profile.name.isNotEmpty ? profile.name : '내 정보',
                style: AppTypography.title,
              ),
              if (sub.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(sub.join(' · '), style: AppTypography.caption),
              ],
              if (profile.email != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(profile.email!, style: AppTypography.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
