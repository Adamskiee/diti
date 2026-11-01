import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Formats the app version string according to semantic versioning and optional build number.
/// E.g. "2.2.0" or "2.2.0+1".
String formatAppVersion(PackageInfo info) {
  if (info.buildNumber.isNotEmpty) {
    return '${info.version}+${info.buildNumber}';
  }
  return info.version;
}

/// Provider that asynchronously loads [PackageInfo] from the platform.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// Provider that returns the formatted app version string.
final appVersionProvider = FutureProvider<String>((ref) async {
  final packageInfo = await ref.watch(packageInfoProvider.future);
  return formatAppVersion(packageInfo);
});
