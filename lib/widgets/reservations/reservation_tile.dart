import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reservation.dart';

class ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;

  const ReservationTile({super.key, required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');
    final color = reservation.category.color;
    final isCancelled = reservation.status == ReservationStatus.cancelled;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(reservation.category.icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                        color: isCancelled ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${reservation.provider} · ${timeFormat.format(reservation.dateTime)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: reservation.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reservation.status.label,
                  style: TextStyle(
                    color: reservation.status.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
