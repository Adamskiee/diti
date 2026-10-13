import 'dart:async';

/// An asynchronous FIFO queue that serializes execution of tasks.
///
/// Guarantees that each task runs sequentially in FIFO order and that
/// subsequent queued tasks continue running even if an earlier task throws.
class CommandQueue {
  Future<void> _lastTask = Future<void>.value();

  /// Runs [action] after all previously queued tasks have completed.
  ///
  /// Returns a [Future] that completes with the result of [action], or
  /// with its error if [action] throws.
  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();

    _lastTask = _lastTask.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }).catchError((_) {});

    return completer.future;
  }
}
