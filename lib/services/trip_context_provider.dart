import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/trip_context.dart';
import 'trip_manager.dart';

/// The single canonical way a widget asks "what trip am I looking at?"
/// Every screen that needs the active trip's identity should go through
/// this instead of reaching into [TripManager] directly — one call site
/// means "connecting every screen" is a real, checkable property of the
/// codebase rather than a convention people can drift away from.
class TripContextProvider {
  const TripContextProvider._();

  static TripContext of(BuildContext context, {bool listen = true}) {
    final manager = listen ? context.watch<TripManager>() : context.read<TripManager>();
    return manager.currentContext;
  }
}
