import 'package:flutter_riverpod/flutter_riverpod.dart';

final isSendingProvider = NotifierProvider<IsSendingNotifier, bool>(IsSendingNotifier.new);

class IsSendingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }
  
  void setIsSending(bool value) {
    state = value;
  }
}
