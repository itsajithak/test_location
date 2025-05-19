import 'package:flutter/material.dart';

class TabScreen extends StatefulWidget {
  List<Widget>? buttons;

  TabScreen({super.key, this.buttons});

  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = widget.buttons ?? [];
    List<Widget> rows = [];
    for (int i = 0; i < (buttons.length); i += 2) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buttons[i],
            if (i + 1 < (buttons.length)) ...[
              const SizedBox(width: 16),
              buttons[i + 1],
            ]
          ],
        ),
      );
      rows.add(const SizedBox(height: 16));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows..removeLast(),
    );
  }
}
