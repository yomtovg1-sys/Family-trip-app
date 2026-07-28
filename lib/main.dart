import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/itinerary_provider.dart';
import 'providers/packing_provider.dart';
import 'providers/photo_journal_provider.dart';
import 'providers/places_provider.dart';
import 'providers/reservations_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/trip_provider.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/home_screen.dart';
import 'screens/itinerary_screen.dart';
import 'screens/map_screen.dart';
import 'screens/packing_screen.dart';
import 'screens/photo_journal_screen.dart';
import 'screens/reservations_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/travel_wallet_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_section.dart';

void main() {
  runApp(const FamilyTripApp());
}

class FamilyTripApp extends StatelessWidget {
  const FamilyTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => ItineraryProvider()),
        ChangeNotifierProvider(create: (_) => PackingProvider()),
        ChangeNotifierProvider(create: (_) => ReservationsProvider()),
        ChangeNotifierProvider(create: (_) => PlacesProvider()),
        ChangeNotifierProvider(create: (_) => PhotoJournalProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
      ],
      child: MaterialApp(
        title: 'Family Trip Planner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        initialRoute: AppSection.homeRoute,
        routes: {
          AppSection.homeRoute: (_) => const HomeScreen(),
          AppSection.itineraryRoute: (_) => const ItineraryScreen(),
          AppSection.mapRoute: (_) => const MapScreen(),
          AppSection.packingRoute: (_) => const PackingScreen(),
          AppSection.expensesRoute: (_) => const ExpensesScreen(),
          AppSection.reservationsRoute: (_) => const ReservationsScreen(),
          AppSection.travelWalletRoute: (_) => const TravelWalletScreen(),
          AppSection.photosRoute: (_) => const PhotoJournalScreen(),
          AppSection.tasksRoute: (_) => const TasksScreen(),
          AppSection.aiAssistantRoute: (_) => const AiAssistantScreen(),
        },
      ),
    );
  }
}
