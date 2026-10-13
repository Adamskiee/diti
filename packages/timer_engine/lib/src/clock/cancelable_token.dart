abstract interface class CancelableToken {
  void cancel();
  bool get isCancelled;
}

class SimpleCancelableToken implements CancelableToken {
  bool _cancelled = false;
  final void Function()? onCancel;

  SimpleCancelableToken({this.onCancel});

  @override
  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      onCancel?.call();
    }
  }

  @override
  bool get isCancelled => _cancelled;
}
