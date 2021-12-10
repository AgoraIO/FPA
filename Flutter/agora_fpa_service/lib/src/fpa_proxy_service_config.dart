import 'package:json_annotation/json_annotation.dart';

part 'fpa_proxy_service_config.g.dart';

@JsonSerializable()
class FpaProxyServiceConfig {
  FpaProxyServiceConfig({
    required this.appId,
    required this.token,
    this.logLevel = FpaProxyServiceLogLevel.none,
    this.logFileSizeKb = 0,
    this.logFilePath = '',
    // this.chainIdTable = const {},
  });
  @JsonKey(name: 'app_id')
  final String appId;

  @JsonKey(name: 'token')
  final String token;

  @JsonKey(name: 'log_level')
  final FpaProxyServiceLogLevel logLevel;

  @JsonKey(name: 'log_file_size_kb')
  final int logFileSizeKb;

  @JsonKey(name: 'log_file_path')
  final String logFilePath;
  // final Map<String, int> chainIdTable;

  // @override
  // bool operator ==(Object other) {
  //   if (identical(other, this)) return true;
  //   if (other.runtimeType != runtimeType) return false;

  //   return other is FpaProxyServiceConfig &&
  //       other.appId == appId &&
  //       other.token == token &&
  //       other.logLevel == logLevel &&
  //       other.fileSizeInKb == fileSizeInKb &&
  //       other.logFilePath == logFilePath &&
  //       other.chainIdTable == chainIdTable;
  // }

  // @override
  // int get hashCode => hashValues(
  //       appId,
  //       token,
  //       logLevel,
  //       fileSizeInKb,
  //       logFilePath,
  //       chainIdTable,
  //     );

  // @override
  // String toString() =>
  //     '${objectRuntimeType(this, 'FpaConfig')}($appId, $token, $logLevel, $fileSizeInKb, $logFilePath, $chainIdTable)';

  factory FpaProxyServiceConfig.fromJson(Map<String, dynamic> json) =>
      _$FpaProxyServiceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$FpaProxyServiceConfigToJson(this);
}

/// The log level
/// - 0 indication no log output
/// - 1 information level
/// - 2 warning level
/// - 4 error level
/// - 8 fatal level
@JsonEnum()
enum FpaProxyServiceLogLevel {
  @JsonValue(0)
  none,

  @JsonValue(1)
  info,

  @JsonValue(2)
  warn,

  @JsonValue(4)
  error,

  @JsonValue(8)
  fatal,
}

// extension LogLevelExt on FpaProxyServiceLogLevel {
//   int toInt() {
//     switch (this) {
//       case FpaProxyServiceLogLevel.none:
//         return 0;
//       case FpaProxyServiceLogLevel.info:
//         return 1;
//       case FpaProxyServiceLogLevel.warn:
//         return 2;
//       case FpaProxyServiceLogLevel.error:
//         return 4;
//       case FpaProxyServiceLogLevel.fatal:
//         return 8;
//     }
//   }
// }
