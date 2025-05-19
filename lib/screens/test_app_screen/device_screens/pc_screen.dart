import 'package:flutter/material.dart';

class PcScreen extends StatefulWidget {
  List<Widget>? buttons;

  PcScreen({super.key, this.buttons});

  @override
  State<PcScreen> createState() => _PcScreenState();
}

class _PcScreenState extends State<PcScreen> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.buttons
              ?.expand((button) => [button, const SizedBox(width: 20)])
              .toList() ??
          []
        ..removeLast(),
    );
  }
}
