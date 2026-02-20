import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Custom logger utility for QuickBill app
class AppLogger {
  /// Debug level logs (for development)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'QuickBill.Debug',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Info level logs (general information)
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'QuickBill.Info',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Warning level logs (potential issues)
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'QuickBill.Warning',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Error level logs (errors that need attention)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'QuickBill.Error',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Fatal level logs (critical errors)
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'QuickBill.Fatal',
      level: 1200,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
