import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhysicalSingleActivator extends ShortcutActivator {
  const PhysicalSingleActivator(
    this.trigger, {
    this.meta = false,
    this.includeRepeats = true,
  });

  final PhysicalKeyboardKey trigger;
  final bool meta;
  final bool includeRepeats;

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    if (!includeRepeats && event is KeyRepeatEvent) return false;
    if (event is! KeyDownEvent) return false;
    return event.physicalKey == trigger && state.isMetaPressed == meta;
  }

  // Optional: For debugging or serialization
  @override
  String debugDescribeKeys() => '$trigger${meta ? ' + Meta' : ''}';

  // Required for proper equality checks
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhysicalSingleActivator &&
          runtimeType == other.runtimeType &&
          trigger == other.trigger &&
          meta == other.meta &&
          includeRepeats == other.includeRepeats;

  @override
  int get hashCode => Object.hash(trigger, meta, includeRepeats);
}
