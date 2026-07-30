import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
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

/// Every persisted repository and provider the app needs, fully constructed
/// and loaded from on-device storage. Building this once — in [main] for a
/// real run, or directly in a test — is what lets [FamilyTripApp] itself
/// stay a plain, synchronous widget tree instead of needing a loading
/// screen while Hive boxes open.
class AppDependencies {
  final SettingsRepository settingsRepository;
  final BackupRepository backupRepository;
  final CloudRepository cloudRepository;
  final PersonalVault personalVault;
  final TripManager tripManager;
  final TripProvider tripProvider;
  final ItineraryProvider itineraryProvider;
  final PackingProvider packingProvider;
  final ReservationsProvider reservationsProvider;
  final PlacesProvider placesProvider;
  final MemoriesProvider memoriesProvider;
  final TasksProvider tasksProvider;

  AppDependencies({
    required this.settingsRepository,
    required this.backupRepository,
    required this.cloudRepository,
    required this.personalVault,
    required this.tripManager,
    required this.tripProvider,
    required this.itineraryProvider,
    required this.packingProvider,
    required this.reservationsProvider,
    required this.placesProvider,
    required this.memoriesProvider,
    required this.tasksProvider,
  });

  /// Opens every Hive box and loads (or, on a genuine first launch, seeds)
  /// all persisted app state. Everything here reuses each model's existing
  /// `toJson`/`fromJson` and each provider's existing seed data — this is a
  /// storage-backend swap, not a rewrite of what the app already does.
  static Future<AppDependencies> bootstrap() async {
    await Hive.initFlutter();

    final settingsRepository = LocalSettingsRepository(
      defaultAccountEmail: 'yomtovg1@gmail.com',
      defaultAccountName: 'Family Account',
    );
    const cloudRepository = UnavailableCloudRepository(CloudProviderKind.googleDrive);
    final templateRepository = InMemoryTemplateRepository();

    final appStateBox = await Hive.openBox<String>('app_state');

    final backupRepository = await HiveBackupRepository.open();
    final tripRepository = await HiveTripRepository.open();
    final vaultRepository = await HiveVaultRepository.open();
    final tripLinkService = await TripLinkService.open();

    final personalVault = PersonalVault(repository: vaultRepository);
    final tripManager = TripManager(
      tripRepository: tripRepository,
      personalVault: personalVault,
      linkService: tripLinkService,
      templateRepository: templateRepository,
      appStateBox: appStateBox,
    );
    final tripProvider = await TripProvider.open(tripManager: tripManager);

    final itineraryProvider = ItineraryProvider();
    final packingProvider = await PackingProvider.open();
    final reservationsProvider = await ReservationsProvider.open();
    final placesProvider = await PlacesProvider.open();
    final memoriesProvider = await MemoriesProvider.open();
    final tasksProvider = await TasksProvider.open();

    return AppDependencies(
      settingsRepository: settingsRepository,
      backupRepository: backupRepository,
      cloudRepository: cloudRepository,
      personalVault: personalVault,
      tripManager: tripManager,
      tripProvider: tripProvider,
      itineraryProvider: itineraryProvider,
      packingProvider: packingProvider,
      reservationsProvider: reservationsProvider,
      placesProvider: placesProvider,
      memoriesProvider: memoriesProvider,
      tasksProvider: tasksProvider,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.bootstrap();
  runApp(FamilyTripApp(dependencies: dependencies));
}

class FamilyTripApp extends StatelessWidget {
  final AppDependencies dependencies;

  const FamilyTripApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dependencies.personalVault),
        ChangeNotifierProvider.value(value: dependencies.tripManager),
        ChangeNotifierProvider.value(value: dependencies.tripProvider),
        ChangeNotifierProvider.value(value: dependencies.itineraryProvider),
        ChangeNotifierProvider.value(value: dependencies.packingProvider),
        ChangeNotifierProvider.value(value: dependencies.reservationsProvider),
        ChangeNotifierProvider.value(value: dependencies.placesProvider),
        ChangeNotifierProvider.value(value: dependencies.memoriesProvider),
        ChangeNotifierProvider.value(value: dependencies.tasksProvider),
        Provider<SettingsRepository>.value(value: dependencies.settingsRepository),
        ChangeNotifierProvider(
          create: (context) => BackupManager(
            tripProvider: context.read<TripProvider>(),
            placesProvider: context.read<PlacesProvider>(),
            reservationsProvider: context.read<ReservationsProvider>(),
            packingProvider: context.read<PackingProvider>(),
            memoriesProvider: context.read<MemoriesProvider>(),
            backupRepository: dependencies.backupRepository,
            settingsRepository: dependencies.settingsRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SyncService(
            backupManager: context.read<BackupManager>(),
            cloudRepository: dependencies.cloudRepository,
            settingsRepository: dependencies.settingsRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'EasyTrip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // The countdown boxes, chips, and other fixed-size elements
        // throughout this app are laid out for one specific font size —
        // they don't reflow for a larger one. Left unclamped, a device's
        // own text-size setting (Safari on iOS reports this to the page,
        // desktop browsers generally don't) scales every TextStyle up
        // without any of these fixed-size containers growing to match,
        // so text that no longer fits wraps mid-word or mid-number
        // instead of clipping — e.g. "09" breaking across two lines in a
        // 60x60 countdown box. Locking the scale to the design's intended
        // 1.0 keeps every screen exactly as designed everywhere.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
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
