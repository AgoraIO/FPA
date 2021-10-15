import 'dart:convert';

import 'package:agora_fpa_service/src/native_fpa_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora_fpa_service/agora_fpa_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'fpa_service_test.mocks.dart';

class _AgoraFpaServiceObserver implements FpaServiceObserver {
  @override
  void onEvent(int event, int errorCode) {}

  @override
  void onTokenWillExpireEvent(String token) {}
}

@GenerateMocks([], customMocks: [
  MockSpec<NativeFpaService>(returnNullOnMissingStub: true)
])
void main() {
  late FpaService agoraFpaService;
  late NativeFpaService nativeAgoraFpaService;
  setUp(() {
    nativeAgoraFpaService = MockNativeFpaService();
    agoraFpaService = FpaService.mock(nativeAgoraFpaService);
  });
  group('NativeAgoraFpaService', () {
    test('init called', () {
      when(nativeAgoraFpaService.getServerStatus())
          .thenReturn(kLocalServerStatusIdle);

      final config = FpaConfig(appId: 'appId', token: 'token');
      when(nativeAgoraFpaService.init(config)).thenReturn(0);
      final ret = agoraFpaService.start(config);
      expect(ret, 0);
    });

    test('init not been called', () {
      when(nativeAgoraFpaService.getServerStatus())
          .thenReturn(kLocalServerStatusOK);
      final config = FpaConfig(appId: 'appId', token: 'token');
      final ret = agoraFpaService.start(config);
      expect(ret, kErrorTooOften);
      verifyNever(nativeAgoraFpaService.init(config));
    });

    test('destroy called', () {
      agoraFpaService.destroy();
      verify(nativeAgoraFpaService.destroy()).called(1);
    });

    test('getHttpProxyPort called', () {
      when(nativeAgoraFpaService.getHttpProxyPort()).thenReturn(8888);
      final ret = agoraFpaService.getHttpProxyPort();
      expect(ret, 8888);
    });

    test('renewToken called', () {
      when(nativeAgoraFpaService.renewToken('new token')).thenReturn(0);
      final ret = agoraFpaService.renewToken('new token');
      expect(ret, 0);
    });

    test('registerObserver called', () {
      final observer = _AgoraFpaServiceObserver();
      when(nativeAgoraFpaService.registerObserver(observer)).thenReturn(0);
      final ret = agoraFpaService.registerObserver(observer);
      expect(ret, 0);
    });

    test('unregisterObserver called', () {
      when(nativeAgoraFpaService.unregisterObserver()).thenReturn(0);
      final ret = agoraFpaService.unregisterObserver();
      expect(ret, 0);
    });

    test('setParameters called', () {
      when(nativeAgoraFpaService.setParameters('p')).thenReturn(0);
      final ret = agoraFpaService.setParameters('p');
      expect(ret, 0);
    });

    test('updateChainIdTable called', () {
      final chainIdTable = jsonEncode(const {});
      when(nativeAgoraFpaService.updateChainIdTable(chainIdTable))
          .thenReturn(0);
      final ret = agoraFpaService.updateChainIdTable(const {});
      expect(ret, 0);
    });
  });
}
