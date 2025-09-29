import 'package:flutter/foundation.dart';

class DebugService {
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
  
  static void logError(String error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ ERROR: $error');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }
  
  static void logInfo(String info) {
    if (kDebugMode) {
      print('ℹ️ INFO: $info');
    }
  }
  
  static void logSuccess(String message) {
    if (kDebugMode) {
      print('✅ SUCCESS: $message');
    }
  }
  
  static void logWarning(String warning) {
    if (kDebugMode) {
      print('⚠️ WARNING: $warning');
    }
  }
}