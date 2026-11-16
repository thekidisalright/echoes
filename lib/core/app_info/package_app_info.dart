import 'package:package_info_plus/package_info_plus.dart';

import 'app_info.dart';

/// [AppInfo] lido do pacote instalado (`versionName` do Android).
class PackageAppInfo implements AppInfo {
  @override
  Future<String> version() async => (await PackageInfo.fromPlatform()).version;
}
