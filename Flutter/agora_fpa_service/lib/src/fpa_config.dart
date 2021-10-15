import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class FpaConfig {
  FpaConfig({
    required this.appId,
    required this.token,
    this.logLevel = 0,
    this.fileSizeInKb = 1024,
    this.logFilePath,
    this.chainIdTable = const {},
  });
  final String appId;
  final String token;
  final int logLevel;
  final int fileSizeInKb;
  final String? logFilePath;
  final Map<String, int> chainIdTable;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is FpaConfig &&
        other.appId == appId &&
        other.token == token &&
        other.logLevel == logLevel &&
        other.fileSizeInKb == fileSizeInKb &&
        other.logFilePath == logFilePath &&
        other.chainIdTable == chainIdTable;
  }

  @override
  int get hashCode => hashValues(
        appId,
        token,
        logLevel,
        fileSizeInKb,
        logFilePath,
        chainIdTable,
      );

  @override
  String toString() =>
      '${objectRuntimeType(this, 'FpaConfig')}($appId, $token, $logLevel, $fileSizeInKb, $logFilePath, $chainIdTable)';
}

/// The log level
/// - 0 indication no log output
/// - 1 information level
/// - 2 warning level
/// - 4 error level
/// - 8 fatal level
enum LogLevel {
  disable,
  info,
  warning,
  error,
  fatal,
}

extension LogLevelExt on LogLevel {
  int toInt() {
    switch (this) {
      case LogLevel.disable:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 4;
      case LogLevel.fatal:
        return 8;
    }
  }
}
