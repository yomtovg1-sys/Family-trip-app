import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/cloud_account.dart';
import 'providers/itinerary_provider.dart';
import 'providers/memories_provider.dart';
import 'providers/packing_provider.dart';
import 'providers/places_provider.dart';
import 'providers/reservations_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/trip_provider.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/home_screen.dart';
import 'screens/itinerary_screen.dart';
import 'screens/map_screen.dart';
import 'screens/memories_screen.dart';
import 'screens/packing_screen.dart';
import 'screens/personal_vault_screen.dart';
import 'screens/places_screen.dart';
import 'screens/reservations_screen.dart';
import 'screens/sync_backup_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/travel_wallet_screen.dart';
import 'screens/trip_manager_screen.dart';
import 'services/backup_manager.dart';
import 'services/backup_repository.dart';
import 'services/cloud_repository.dart';
import 'services/personal_vault.dart';
import 'services/settings_repository.dart';
import 'services/sync_service.dart';
import 'services/template_repository.dart';
import 'services/trip_link_service.dart';
import 'services/trip_manager.dart';
import 'services/trip_repository.dart';
import 'services/vault_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/app_section.dart';

void main() {
  runApp(const FamilyTripApp());
}

class FamilyTripApp extends StatelessWidget {
  const FamilyTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepository = LocalSettingsRepository(
      defaultAccountEmail: 'yomtovg1@gmail.com',
      defaultAccountName: 'Family Account',
    );
    final backupRepository = LocalBackupRepository();
    const cloudRepository = UnavailableCloudRepository(CloudProviderKind.googleDrive);
    final tripRepository = InMemoryTripRepository();
    final tripLinkService = TripLinkService();
    final templateRepository = InMemoryTemplateRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PersonalVault(repository: InMemoryVaultRepository())),
        ChangeNotifierProvider(
          create: (context) => TripManager(
            tripRepository: tripRepository,
            personalVault: context.read<PersonalVault>(),
            linkService: tripLinkService,
            templateRepository: templateRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TripProvider(tripManager: context.read<TripManager>()),
        ),
        ChangeNotifierProvider(create: (_) => ItineraryProvider()),
        ChangeNotifierProvider(create: (_) => PackingProvider()),
        ChangeNotifierProvider(create: (_) => ReservationsProvider()),
        ChangeNotifierProvider(create: (_) => PlacesProvider()),
        ChangeNotifierProvider(create: (_) => MemoriesProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        Provider<SettingsRepository>.value(value: settingsRepository),
        ChangeNotifierProvider(
          create: (context) => BackupManager(
            tripProvider: context.read<TripProvider>(),
            placesProvider: context.read<PlacesProvider>(),
            reservationsProvider: context.read<ReservationsProvider>(),
            packingProvider: context.read<PackingProvider>(),
            memoriesProvider: context.read<MemoriesProvider>(),
            backupRepository: backupRepository,
            settingsRepository: settingsRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SyncService(
            backupManager: context.read<BackupManager>(),
            cloudRepository: cloudRepository,
            settingsRepository: settingsRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'EasyTrip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        initialRoute: AppSection.homeRoute,
        routes: {
          AppSection.homeRoute: (_) => const HomeScreen(),
          AppSection.itineraryRoute: (_) => const ItineraryScreen(),
          AppSection.mapRoute: (_) => const MapScreen(),
          AppSection.placesRoute: (_) => const PlacesScreen(),
          AppSection.packingRoute: (_) => const PackingScreen(),
          AppSection.expensesRoute: (_) => const ExpensesScreen(),
          AppSection.reservationsRoute: (_) => const ReservationsScreen(),
          AppSection.travelWalletRoute: (_) => const TravelWalletScreen(),
          AppSection.photosRoute: (_) => const MemoriesScreen(),
          AppSection.tasksRoute: (_) => const TasksScreen(),
          AppSection.aiAssistantRoute: (_) => const AIAssistantScreen(),
          AppSection.syncBackupRoute: (_) => const SyncBackupScreen(),
          AppSection.personalVaultRoute: (_) => const PersonalVaultScreen(),
          AppSection.tripManagerRoute: (_) => const TripManagerScreen(),
        },
      ),
    );
  }
}
