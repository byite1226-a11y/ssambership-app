import 'package:flutter/foundation.dart';

/// 개발 전용 도구(위젯 갤러리 등) 활성화 여부.
/// ★ 출시(release) 빌드에서는 kReleaseMode == true → false 가 되어 dev 라우트/진입이 제외된다.
final bool kDevToolsEnabled = !kReleaseMode;
