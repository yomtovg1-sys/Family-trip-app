import 'package:flutter/material.dart';

/// A 1–5 star priority rating. Read-only unless [onChanged] is given, in
/// which case each star becomes tappable.
class StarRating extends StatelessWidget {
  final int value;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRating({super.key, required this.value, this.size = 18, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFFFB300);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(i),
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i <= value ? color : color.withValues(alpha: 0.4),
              ),
            ),
          ),
      ],
    );
  }
}
