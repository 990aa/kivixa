import 'package:flutter/material.dart';

class AdaptiveSwitch extends Switch {
  const AdaptiveSwitch({
    super.key,
    required super.value,
    required super.onChanged,
    super.thumbIcon,
    super.thumbColor,
    super.focusNode,
    super.autofocus = false,
    super.mouseCursor,
  }) : super.adaptive();
}
