import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:diti/src/core/di/app_info_providers.dart';

void main() {
  group('formatAppVersion', () {
    test('formats version without build number', () {
      final info = PackageInfo(
        appName: 'Diti',
        packageName: 'com.adilabs.diti',
        version: '2.2.0',
        buildNumber: '',
        buildSignature: '',
      );
      expect(formatAppVersion(info), '2.2.0');
    });

    test('formats version with build number', () {
      final info = PackageInfo(
        appName: 'Diti',
        packageName: 'com.adilabs.diti',
        version: '2.2.0',
        buildNumber: '42',
        buildSignature: '',
      );
      expect(formatAppVersion(info), '2.2.0+42');
    });
  });

  group('appInfoProviders', () {
    test('appVersionProvider returns formatted version from packageInfoProvider', () async {
      final container = ProviderContainer(
        overrides: [
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '1',
              buildSignature: '',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final version = await container.read(appVersionProvider.future);
      expect(version, '2.2.0+1');
    });
  });
}
