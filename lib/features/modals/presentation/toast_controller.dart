import 'dart:async';

class ToastController {
  ToastController({required void Function() onChanged})
      : _onChanged = onChanged;

  static const _duration = Duration(milliseconds: 2400);

  final void Function() _onChanged;
  final List<String> _queue = [];
  Timer? _timer;
  bool _disposed = false;

  String message = '';
  bool visible = false;

  void show(String nextMessage, {required bool canQueue}) {
    if (_disposed) return;
    if (visible && canQueue) {
      _queue.add(nextMessage);
      return;
    }
    _showNow(nextMessage);
  }

  void _showNow(String nextMessage) {
    if (_disposed) return;
    message = nextMessage;
    visible = true;
    _onChanged();
    _timer?.cancel();
    _timer = Timer(_duration, () {
      if (_disposed) return;
      if (_queue.isNotEmpty) {
        _showNow(_queue.removeAt(0));
        return;
      }
      visible = false;
      _onChanged();
    });
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _queue.clear();
    message = '';
    visible = false;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _queue.clear();
  }
}
