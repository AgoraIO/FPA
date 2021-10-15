import 'dart:convert';

import 'package:agora_fpa_service/src/native_fpa_service.dart';
import 'package:meta/meta.dart';

import 'fpa_config.dart';

/// Error code: too often
const int kErrorTooOften = -2;

/// Default host
const String kBaseHost = "127.0.0.1";

const String kChainIdHeader = "chan_id";
const String kRealPath = "real_path";

/// Local server status code
const int kLocalServerStatusIdle = 0;
const int kLocalServerStatusBuilding = 1;
const int kLocalServerStatusBuildingError = 2;

const int kLocalServerStatusOK = 3;

/// Observer event code
const int kObserverEventErrLocalServerStopped = 2;

/// Observer error code
const int kErrOK = 0;
const int kErrFpaNotInitialized = 1;

abstract class FpaServiceObserver {
  void onEvent(int event, int errorCode);
  void onTokenWillExpireEvent(String token);
}

class FpaService {
  /// Constructor for testing purpose
  @visibleForTesting
  FpaService.mock(NativeFpaService nativeAgoraFpaService) {
    _nativeFpaService = nativeAgoraFpaService;
  }

  FpaService._() {
    _nativeFpaService = NativeFpaService();
  }
  static FpaService? _instance;
  late final NativeFpaService _nativeFpaService;

  factory FpaService.create() {
    _instance ??= FpaService._();
    return _instance!;
  }

  int start(FpaConfig config) {
    if (_nativeFpaService.getServerStatus() == kLocalServerStatusOK) {
      return kErrorTooOften;
    }

    return _nativeFpaService.init(config);
  }

  void destroy() {
    _nativeFpaService.destroy();
    _instance = null;
  }

  int getHttpProxyPort() {
    return _nativeFpaService.getHttpProxyPort();
  }

  int renewToken(String token) {
    return _nativeFpaService.renewToken(token);
  }

  int registerObserver(FpaServiceObserver observer) {
    return _nativeFpaService.registerObserver(observer);
  }

  int unregisterObserver() {
    return _nativeFpaService.unregisterObserver();
  }

  int setParameters(String params) {
    return _nativeFpaService.setParameters(params);
  }

  int updateChainIdTable(Map<String, int> chainIdTable) {
    final chainIdTableString = jsonEncode(chainIdTable);
    return _nativeFpaService.updateChainIdTable(chainIdTableString);
  }
}
