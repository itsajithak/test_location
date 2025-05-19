import 'package:flutter/material.dart';

class MobileScreen extends StatefulWidget {
  List<Widget>? buttons;

  MobileScreen({super.key, this.buttons});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.buttons
              ?.expand((button) => [button, const SizedBox(height: 12)])
              .toList() ??
          []
        ..removeLast(),
    );
  }
}
