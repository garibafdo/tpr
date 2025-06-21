import 'package:flutter/material.dart';

class MATButton extends StatelessWidget {
  const MATButton({
    super.key,
    this.onMulaButtonClicked,
    this.onAtthaButtonClicked,
    this.onTikaButtonClicked,
  });

  final VoidCallback? onMulaButtonClicked;
  final VoidCallback? onAtthaButtonClicked;
  final VoidCallback? onTikaButtonClicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(label: 'M', onPressed: onMulaButtonClicked),
          const VerticalDivider(width: 1, thickness: 1),
          _buildButton(label: 'A', onPressed: onAtthaButtonClicked),
          const VerticalDivider(width: 1, thickness: 1),
          _buildButton(label: 'T', onPressed: onTikaButtonClicked),
        ],
      ),
    );
  }

  Widget _buildButton({required String label, VoidCallback? onPressed}) {
    return SizedBox(
      width: 24,
      child: TextButton(
        style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(0))),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
