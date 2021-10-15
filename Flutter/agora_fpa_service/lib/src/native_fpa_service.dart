import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:agora_fpa_service/src/fpa_service.dart';
import 'package:agora_fpa_service/src/fpa_config.dart';
import 'package:ffi/ffi.dart';

typedef FpaServiceEventNative = Void Function(Int32 event, Int32 errorCode);

typedef TokenWillExpireEventNative = Void Function(Pointer<Utf8> token);

typedef NetWorkChangedNative = Void Function(Int32 type);

class AgoraFpaServiceCObserver extends Struct {
  external Pointer<NativeFunction<FpaServiceEventNative>> fpaServiceEvent;
  external Pointer<NativeFunction<TokenWillExpireEventNative>>
      tokenWillExpireEvent;
  external Pointer<NativeFunction<NetWorkChangedNative>> netWorkChanged;
}

typedef AgoraFapServiceCreateNative = Pointer<NativeType> Function();

typedef AgoraFapServiceDestroyNative = Void Function(
    Pointer<NativeType> servicePtr);
typedef AgoraFapServiceDestroy = void Function(Pointer<NativeType> servicePtr);

typedef AgoraFapServiceGetHttpProxyPortNative = Int32 Function(
    Pointer<NativeType> servicePtr);
typedef AgoraFapServiceGetHttpProxyPort = int Function(
    Pointer<NativeType> servicePtr);

typedef AgoraFapServiceRenewTokenNative = Int32 Function(
  Pointer<NativeType> servicePtr,
  Pointer<Utf8> token,
);
typedef AgoraFapServiceRenewToken = int Function(
  Pointer<NativeType> servicePtr,
  Pointer<Utf8> token,
);

typedef AgoraFapServiceInitNative = Int32 Function(
  Pointer<NativeType> servicePtr,
  Pointer<Utf8> appId,
  Pointer<Utf8> token,
  Int32 logLevel,
  Int32 fileSizeInKb,
  Pointer<Utf8> logFilePath,
  Pointer<Utf8> tableString,
);
typedef AgoraFapServiceInit = int Function(
  Pointer<NativeType> servicePtr,
  Pointer<Utf8> appId,
  Pointer<Utf8> token,
  int logLevel,
  int fileSizeInKb,
  Pointer<Utf8> logFilePath,
  Pointer<Utf8> tableString,
);

typedef AgoraFapServiceUnregisterFpaServiceObserverNative = Int32 Function(
    Pointer<NativeType>);
typedef AgoraFapServiceUnregisterFpaServiceObserver = int Function(
    Pointer<NativeType>);

typedef AgoraFapServiceRegisterFpaServiceObserverNative = Int32 Function(
    Pointer<NativeType> servicePtr, Pointer<AgoraFpaServiceCObserver> observer);
typedef AgoraFapServiceRegisterFpaServiceObserver = int Function(
    Pointer<NativeType> servicePtr, Pointer<AgoraFpaServiceCObserver> observer);

typedef AgoraFapServiceGetLocalServerStatusNative = Int32 Function(
    Pointer<NativeType> servicePtr);
typedef AgoraFapServiceGetLocalServerStatus = int Function(
    Pointer<NativeType> servicePtr);

typedef AgoraFapServiceSetParametersNative = Int32 Function(
    Pointer<NativeType> servicePtr, Pointer<Utf8> param);
typedef AgoraFapServiceSetParameters = int Function(
    Pointer<NativeType> servicePtr, Pointer<Utf8> param);

typedef AgoraFapServiceUpdateChainIdTableNative = Int32 Function(
  Pointer<NativeType> servicePtr,
  Pointer<Utf8> chainIdTable,
);
typedef AgoraFapServiceUpdateChainIdTable = int Function(
  Pointer<NativeType> servicePtr,
  Pointer<Utf8> chainIdTable,
);

/// Class for binding C APIs
class NativeFpaService {
  NativeFpaService() {
    _agoraFpaServiceLib = Platform.isAndroid
        ? DynamicLibrary.open("libagora_fpa_service.so")
        : DynamicLibrary.process();

    _agoraFpaServicePtr = _agoraFpaServiceLib
        .lookup<NativeFunction<AgoraFapServiceCreateNative>>(
            'agora_fpa_service_create')
        .asFunction<AgoraFapServiceCreateNative>()();
  }

  late final DynamicLibrary _agoraFpaServiceLib;

  late final Pointer<NativeType> _agoraFpaServicePtr;

  static FpaServiceObserver? _agoraFpaServiceObserver;

  int init(FpaConfig config) {
    final fp = _agoraFpaServiceLib.lookupFunction<AgoraFapServiceInitNative,
        AgoraFapServiceInit>('agora_fpa_service_init');
    final appIdN = config.appId.toNativeUtf8();
    final tokenN = config.token.toNativeUtf8();
    final logFilePathN =
        config.logFilePath?.toNativeUtf8() ?? Pointer.fromAddress(0);
    final tableStringN = jsonEncode(config.chainIdTable).toNativeUtf8();

    final ret = fp(
      _agoraFpaServicePtr,
      appIdN,
      tokenN,
      config.logLevel.toInt(),
      config.fileSizeInKb,
      logFilePathN,
      tableStringN,
    );

    calloc.free(appIdN);
    calloc.free(tokenN);
    calloc.free(logFilePathN);
    calloc.free(tableStringN);

    return ret;
  }

  void destroy() {
    _agoraFpaServiceObserver = null;

    final fp = _agoraFpaServiceLib
        .lookup<NativeFunction<AgoraFapServiceDestroyNative>>(
            'agora_fpa_service_destroy')
        .asFunction<AgoraFapServiceDestroy>();
    fp(_agoraFpaServicePtr);
  }

  int getHttpProxyPort() {
    final fp = _agoraFpaServiceLib.lookupFunction<
            AgoraFapServiceGetHttpProxyPortNative,
            AgoraFapServiceGetHttpProxyPort>(
        'agora_fpa_service_get_http_proxy_port');

    return fp(_agoraFpaServicePtr);
  }

  int renewToken(String token) {
    final fp = _agoraFpaServiceLib.lookupFunction<
        AgoraFapServiceRenewTokenNative,
        AgoraFapServiceRenewToken>('agora_fpa_service_renew_token');
    final nu = token.toNativeUtf8();
    final int ret = fp(_agoraFpaServicePtr, nu);
    calloc.free(nu);
    return ret;
  }

  static void _fpaServiceEventHandle(int event, int errorCode) {
    _agoraFpaServiceObserver?.onEvent(event, errorCode);
  }

  static void _tokenWillExpireEventHandle(Pointer<Utf8> token) {
    final tokenString = token.toDartString();
    _agoraFpaServiceObserver?.onTokenWillExpireEvent(tokenString);
  }

  static void _netWorkChangedHandle(int type) {}

  int registerObserver(FpaServiceObserver observer) {
    _agoraFpaServiceObserver = observer;
    final fp = _agoraFpaServiceLib.lookupFunction<
            AgoraFapServiceRegisterFpaServiceObserverNative,
            AgoraFapServiceRegisterFpaServiceObserver>(
        'agora_fpa_service_unRegister_fpa_service_observer');

    final Pointer<NativeFunction<FpaServiceEventNative>> eventPtr =
        Pointer.fromFunction(_fpaServiceEventHandle);

    final Pointer<NativeFunction<TokenWillExpireEventNative>> tokenExpirePtr =
        Pointer.fromFunction(_tokenWillExpireEventHandle);

    final Pointer<NativeFunction<NetWorkChangedNative>> networkChangePtr =
        Pointer.fromFunction(_netWorkChangedHandle);

    final observerPtr = calloc<AgoraFpaServiceCObserver>()
      ..ref.fpaServiceEvent = eventPtr
      ..ref.tokenWillExpireEvent = tokenExpirePtr
      ..ref.netWorkChanged = networkChangePtr;

    final ret = fp(_agoraFpaServicePtr, observerPtr);
    return ret;
  }

  int unregisterObserver() {
    _agoraFpaServiceObserver = null;

    final fp = _agoraFpaServiceLib.lookupFunction<
            AgoraFapServiceUnregisterFpaServiceObserverNative,
            AgoraFapServiceUnregisterFpaServiceObserver>(
        'agora_fpa_service_unRegister_fpa_service_observer');
    return fp(_agoraFpaServicePtr);
  }

  int getServerStatus() {
    final fp = _agoraFpaServiceLib.lookupFunction<
            AgoraFapServiceGetLocalServerStatusNative,
            AgoraFapServiceGetLocalServerStatus>(
        'agora_fpa_service_get_local_server_status');
    return fp(_agoraFpaServicePtr);
  }

  int setParameters(String params) {
    final fp = _agoraFpaServiceLib.lookupFunction<
        AgoraFapServiceSetParametersNative,
        AgoraFapServiceSetParameters>('agora_fpa_service_set_parameters');
    final paramsN = params.toNativeUtf8();
    final ret = fp(_agoraFpaServicePtr, paramsN);
    calloc.free(paramsN);
    return ret;
  }

  int updateChainIdTable(String chainIdTableString) {
    final fp = _agoraFpaServiceLib.lookupFunction<
            AgoraFapServiceUpdateChainIdTableNative,
            AgoraFapServiceUpdateChainIdTable>(
        'agora_fpa_service_update_chain_id_table');
    final chainIdTableN = chainIdTableString.toNativeUtf8();
    final ret = fp(_agoraFpaServicePtr, chainIdTableN);
    calloc.free(chainIdTableN);
    return ret;
  }
}
