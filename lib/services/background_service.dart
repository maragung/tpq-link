import 'dart:async';
import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

const String _pendingTasksKey = 'pending_crud_tasks';
const String _taskName = 'processPendingTasks';

/// WorkManager top-level callback — must be a top-level or static function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _taskName) {
      await BackgroundService._processQueue();
      return true;
    }
    return Future.value(false);
  });
}

/// Provides a persistent CRUD operation queue that survives the app being
/// backgrounded or killed.
///
/// Usage:
///   1. Call [BackgroundService.initialize] once in main().
///   2. Before (or instead of) a direct API call, call [BackgroundService.enqueue].
///      The service tries the request immediately; if offline/failed, it retries
///      in the background via WorkManager.
///   3. For operations that must be confirmed synchronously (e.g., PIN dialogs),
///      keep the direct call path and only fall back to the queue on error.
class BackgroundService {
  static const _storage = FlutterSecureStorage();

  /// Initialise WorkManager — call once in main() after WidgetsFlutterBinding.
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Attempt the request immediately. If it fails (network error or non-200),
  /// persist it in the queue and schedule a background retry via WorkManager.
  static Future<Map<String, dynamic>> enqueueOrExecute(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    Map<String, dynamic> result;
    try {
      result = await _execute(method, url, body: body);
    } catch (e) {
      result = {'success': false, 'pesan': e.toString()};
    }

    if (result['success'] != true) {
      await _persistTask(method, url, body: body);
      await _scheduleRetry();
    }

    return result;
  }

  // ── queue management ──────────────────────────────────────────────────────

  static Future<void> _persistTask(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final raw = await _storage.read(key: _pendingTasksKey);
    final tasks = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    tasks.add({
      'method': method,
      'url': url,
      'body': body,
      'queued_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });

    await _storage.write(key: _pendingTasksKey, value: jsonEncode(tasks));
  }

  static Future<void> _scheduleRetry() async {
    await Workmanager().registerOneOffTask(
      'crud_retry_${DateTime.now().millisecondsSinceEpoch}',
      _taskName,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  // Maximum number of attempts before a task is considered permanently failed.
  static const _maxRetries = 10;

  // HTTP status codes that indicate a permanent failure — no point retrying.
  // 429 (Too Many Requests) is intentionally excluded; it is transient.
  static const _permanentErrorCodes = {400, 401, 403, 404, 405, 410, 422};

  /// Processes all queued tasks. Called by WorkManager in its own isolate.
  ///
  /// A task is discarded only when:
  ///   - it succeeds (success == true), OR
  ///   - the server returns a permanent 4xx error (bad request, unauthorised,
  ///     not found, etc.), OR
  ///   - it has exceeded [_maxRetries] attempts.
  ///
  /// Network errors and 5xx responses keep the task in the queue so it will
  /// be retried on the next WorkManager run.
  static Future<void> _processQueue() async {
    final raw = await _storage.read(key: _pendingTasksKey);
    if (raw == null || raw.isEmpty) return;

    final tasks = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final remaining = <Map<String, dynamic>>[];

    // Restore saved token so requests are authenticated
    final token = await _storage.read(key: 'auth_token');
    if (token != null) await ApiService.setToken(token);

    // Restore server URL
    final serverUrl = await _storage.read(key: 'server_url');
    if (serverUrl != null && serverUrl.isNotEmpty) {
      await ApiService.setServerUrl(serverUrl);
    }

    for (final task in tasks) {
      final retryCount = (task['retry_count'] as int?) ?? 0;

      // Discard tasks that have already exhausted all retry attempts.
      if (retryCount >= _maxRetries) continue;

      try {
        final result = await _execute(
          task['method'] as String,
          task['url'] as String,
          body: task['body'] != null
              ? Map<String, dynamic>.from(task['body'] as Map)
              : null,
        );

        if (result['success'] == true) {
          // Success — drop from queue.
          continue;
        }

        final statusCode = result['statusCode'] as int?;
        if (statusCode != null && _permanentErrorCodes.contains(statusCode)) {
          // Permanent server-side error — drop from queue, no point retrying.
          continue;
        }

        // Transient failure (network error, 5xx, 429) — keep and increment.
        remaining.add({...task, 'retry_count': retryCount + 1});
      } catch (_) {
        // Unexpected exception (e.g. socket error) — keep and increment.
        remaining.add({...task, 'retry_count': retryCount + 1});
      }
    }

    if (remaining.isEmpty) {
      await _storage.delete(key: _pendingTasksKey);
    } else {
      await _storage.write(
          key: _pendingTasksKey, value: jsonEncode(remaining));
    }
  }

  static Future<Map<String, dynamic>> _execute(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    switch (method.toUpperCase()) {
      case 'POST':
        return ApiService.post(url, body: body);
      case 'PUT':
        return ApiService.put(url, body: body);
      case 'DELETE':
        return ApiService.delete(url, body: body);
      default:
        return {'success': false, 'pesan': 'Metode tidak didukung: $method'};
    }
  }

  /// Returns the number of tasks still waiting in the queue.
  static Future<int> pendingCount() async {
    final raw = await _storage.read(key: _pendingTasksKey);
    if (raw == null) return 0;
    try {
      return (jsonDecode(raw) as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Clears the entire pending queue (e.g., on logout).
  static Future<void> clearQueue() async {
    await _storage.delete(key: _pendingTasksKey);
  }
}
