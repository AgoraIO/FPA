import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:agora_fpa_service/agora_fpa_service.dart';
import 'package:agora_fpa_service/src/fpa_chain_info.dart';
import 'package:agora_fpa_service/src/fpa_proxy_service_error_code.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import 'fpa_http_proxy_chain_config.dart';
import 'fpa_proxy_service_config.dart';
import 'fpa_proxy_service_diagnosis_info.dart';
import 'fpa_proxy_service_observer.dart';
import 'native_iris_fpa_bindings.dart';

const int kBasicResultLength = 512;

class FpaProxyServiceImpl implements FpaProxyService {
  /// Constructor for testing purpose
  // @visibleForTesting
  // FpaProxyService.mock(NativeFpaService nativeAgoraFpaService) {
  //   _nativeFpaService = nativeAgoraFpaService;
  // }

  static DynamicLibrary _loadAgoraFpaServiceLib() {
    // DynamicLibrary.open("libagora_fpa_sdk.so");
    // DynamicLibrary.open("libagora_fpa_service.so");
    return Platform.isAndroid
        ? DynamicLibrary.open("libAgoraFpaWrapper.so")
        : DynamicLibrary.process();
  }

  FpaProxyServiceImpl._() {
    // _nativeFpaService = NativeFpaService();
    _binding = NativeIrisFpaBinding(_loadAgoraFpaServiceLib());
  }

  static const String kLocalHost = '127.0.0.1';

  static FpaProxyServiceImpl get instance => _instance;
  static FpaProxyServiceImpl _instance = FpaProxyServiceImpl._();

  // late final NativeFpaService _nativeFpaService;
  late final NativeIrisFpaBinding _binding;
  ffi.Pointer<ffi.Void>? _irisFpaPtr;
  ffi.Pointer<ffi.Void>? _irisEventHandlerPtr;
  FpaProxyServiceObserver? _fpaObserver;
  ReceivePort? _dartNativeReceivePort;
  int _dartNativePort = -1;

  // factory FpaProxyService.create() {
  //   _instance ??= FpaProxyService._();
  //   return _instance!;
  // }

  void _checkReturnCode(int ret) {
    if (ret < 0) {
      throw FpaProxyServiceException(ret);
    }
  }

  @override
  void start(FpaProxyServiceConfig config) {
    if (null != _irisFpaPtr) {
      return;
    }

    _irisFpaPtr = _binding.CreateIrisFpaProxyService();
    final p =
        jsonEncode({'config': config.toJson()}).toNativeUtf8().cast<ffi.Int8>();

    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceStart,
        p,
        ffi.nullptr,
      );

      // final ffi.Pointer<
      //         ffi.NativeFunction<
      //             ffi.Void Function(
      //                 ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>)>> eventPtr =
      //     ffi.Pointer.fromFunction(_onProxyEventHandle);

      _dartNativeReceivePort = ReceivePort()..listen(_onProxyEventHandle);
      _dartNativePort = _dartNativeReceivePort!.sendPort.nativePort;

      // final dartNativePortPtr = Int64Pointer()..value = _dartNativePort;

      // Pointer<ffi.Int64> dp = calloc.allocate(ffi.sizeOf<ffi.Int64>());
      // dp.value = _dartNativePort;
      debugPrint('_dartNativePort: $_dartNativePort');

      // final observerPtr = calloc<IrisCEventHandler>()..ref.OnEvent = eventPtr;
      _irisEventHandlerPtr = _binding.SetIrisFpaProxyServiceEventHandlerFlutter(
          _irisFpaPtr!, ffi.NativeApi.initializeApiDLData, _dartNativePort);

      _checkReturnCode(ret);
    } catch (e) {
      _irisFpaPtr = null;
      _irisEventHandlerPtr = null;
      rethrow;
    } finally {
      calloc.free(p);
    }
  }

  @override
  void stop() {
    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceStop,
        ffi.nullptr,
        ffi.nullptr,
      );
      _binding.UnsetIrisFpaProxyServiceEventHandler(
        _irisFpaPtr!,
        _irisEventHandlerPtr!,
      );
      _checkReturnCode(ret);
    } catch (e) {
      rethrow;
    } finally {
      _irisFpaPtr = null;
      _irisEventHandlerPtr = null;
      _instance._fpaObserver = null;
      _dartNativeReceivePort?.close();
      _dartNativeReceivePort = null;
    }
  }

//   static void _onProxyEventHandle(
//       ffi.Pointer<ffi.Int8> eventN, ffi.Pointer<ffi.Int8> resN) {
//     final event = eventN.cast<Utf8>().toDartString();
// debugPrint('event: $event');
//     if (event == 'onProxyEvent') {
//       final res = resN.cast<Utf8>().toDartString();
//       // final resMap = Map.from(jsonDecode(res));
//       // final eventCode = resMap['event'] as String;
//       // final connectionInfo = resMap['connection_info'];
//       // final err = resMap['err'];
//       final proxyEvent = ProxyEvent.fromJson(jsonDecode(res));
//       _instance._fpaObserver?.onProxyEvent(
//         proxyEvent.event,
//         proxyEvent.connectionInfo,
//         proxyEvent.errorCode,
//       );
//     }
//   }

  static void _onProxyEventHandle(dynamic data) {
    debugPrint('_onProxyEventHandle data: $data');
    // final event = eventN.cast<Utf8>().toDartString();
    // debugPrint('event: $event');
    final dataList = List.from(data);
    final event = dataList[0];
    if (event == 'onProxyEvent') {
      // final res = resN.cast<Utf8>().toDartString();
      final res = dataList[1] as String;

      debugPrint('res: $res');

      '{"event":0,"connection_info":{"dst_ip_or_domain":"frank-web-demo.rtns.sd-rtn.com","connection_id":"CB97AA96B2764A7D830CBB9AB1A40948","proxy_type":"https","dst_port":30113,"local_port":41663},"err":0}';
      // final resMap = Map.from(jsonDecode(res));
      // final eventCode = resMap['event'] as String;
      // final connectionInfo = resMap['connection_info'];
      // final err = resMap['err'];
      final proxyEvent = ProxyEvent.fromJson(jsonDecode(res));
      _instance._fpaObserver?.onProxyEvent(
        proxyEvent.event,
        proxyEvent.connectionInfo,
        proxyEvent.errorCode,
      );
    }
  }

  @override
  void setObserver(FpaProxyServiceObserver observer) {
    _instance._fpaObserver = observer;
  }

  @override
  int getHttpProxyPort() {
    final ffi.Pointer<ffi.Int8> result =
        calloc.allocate(kBasicResultLength).cast<ffi.Int8>();
    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceGetHttpProxyPort,
        ffi.nullptr,
        result,
      );

      _checkReturnCode(ret);

      return int.tryParse(result.cast<Utf8>().toDartString()) ?? 0;
    } catch (e) {
      return FpaProxyServiceErrorCode.badPort;
    } finally {
      calloc.free(result);
    }
  }

  @override
  int getTransparentProxyPort(FpaChainInfo info) {
    final ffi.Pointer<ffi.Int8> result =
        calloc.allocate(kBasicResultLength).cast<ffi.Int8>();

    final param =
        jsonEncode({'info': info.toJson()}).toNativeUtf8().cast<ffi.Int8>();
    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceGetTransparentProxyPort,
        param,
        result,
      );

      _checkReturnCode(ret);

      return int.tryParse(result.cast<Utf8>().toDartString()) ?? 0;
    } catch (e) {
      rethrow;
    } finally {
      calloc.free(param);
      calloc.free(result);
    }
  }

  @override
  void setParameters(String params) {
    final p = jsonEncode({
      // TODO(littlegnal): Change the key to 'param'
      'parameters': params,
    });
    final pN = p.toNativeUtf8().cast<ffi.Int8>();
    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceSetParameters,
        pN,
        ffi.nullptr,
      );
      _checkReturnCode(ret);
    } catch (e) {
      rethrow;
    } finally {
      calloc.free(pN);
    }
  }

  @override
  void setOrUpdateHttpProxyChainConfig(FpaHttpProxyChainConfig config) {
    final p = jsonEncode({'config': config.toJson()});
    final pN = p.toNativeUtf8().cast<ffi.Int8>();
    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceSetOrUpdateHttpProxyChainConfig,
        pN,
        ffi.nullptr,
      );

      _checkReturnCode(ret);
    } catch (e) {
      rethrow;
    } finally {
      calloc.free(pN);
    }
  }

  @override
  FpaProxyServiceDiagnosisInfo getDiagnosisInfo() {
    final ffi.Pointer<ffi.Int8> result =
        calloc.allocate(kBasicResultLength).cast<ffi.Int8>();

    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceGetDiagnosisInfo,
        ffi.nullptr,
        result,
      );

      _checkReturnCode(ret);

      final res = result.cast<Utf8>().toDartString();
      final info = FpaProxyServiceDiagnosisInfo.fromJson(jsonDecode(res));

      return info;
    } catch (e) {
      rethrow;
    } finally {
      calloc.free(result);
    }
  }

  @override
  String getSDKVersionInner() {
    final ffi.Pointer<ffi.Int8> result =
        calloc.allocate(kBasicResultLength).cast<ffi.Int8>();

    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceGetAgoraFpaProxyServiceSdkVersion,
        ffi.nullptr,
        result,
      );

      _checkReturnCode(ret);

      return result.cast<Utf8>().toDartString();
    } catch (e) {
      return 'unknow';
    } finally {
      calloc.free(result);
    }
  }

  @override
  String getBuildInfoInner() {
    final ffi.Pointer<ffi.Int8> result =
        calloc.allocate(kBasicResultLength).cast<ffi.Int8>();

    try {
      final ret = _binding.CallIrisFpaProxyServiceApi(
        _irisFpaPtr!,
        ApiTypeProxyService.KServiceGetAgoraFpaProxyServiceSdkBuildInfo,
        ffi.nullptr,
        result,
      );

      _checkReturnCode(ret);

      return result.cast<Utf8>().toDartString();
    } catch (e) {
      return 'unknow';
    } finally {
      calloc.free(result);
    }
  }
}
