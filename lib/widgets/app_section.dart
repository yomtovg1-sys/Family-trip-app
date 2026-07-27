import 'package:flutter/material.dart';

class AppSection {
  final String route;
  final String title;
  final IconData icon;
  final Color color;

  const AppSection({
    required this.route,
    required this.title,
    required this.icon,
    required this.color,
  });

  static const String homeRoute = '/';
  static const String itineraryRoute = '/itinerary';
  static const String mapRoute = '/map';
  static const String packingRoute = '/packing';
  static const String budgetRoute = '/budget';
  static const String reservationsRoute = '/reservations';
  static const String photosRoute = '/photos';
  static const String tasksRoute = '/tasks';

  static const home = AppSection(
    route: homeRoute,
    title: 'Home',
    icon: Icons.home_rounded,
    color: Color(0xFF2E7D6B),
  );

  static const itinerary = AppSection(
    route: '/itinerary',
    title: 'Itinerary',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFF3A6EA5),
  );

  static const map = AppSection(
    route: '/map',
    title: 'Map',
    icon: Icons.map_rounded,
    color: Color(0xFF2F9E44),
  );

  static const packing = AppSection(
    route: '/packing',
    title: 'Packing',
    icon: Icons.checklist_rounded,
    color: Color(0xFFB5651D),
  );

  static const budget = AppSection(
    route: '/budget',
    title: 'Budget',
    icon: Icons.savings_rounded,
    color: Color(0xFF2B8A8A),
  );

  static const reservations = AppSection(
    route: '/reservations',
    title: 'Reservations',
    icon: Icons.confirmation_number_rounded,
    color: Color(0xFF6741D9),
  );

  static const photoJournal = AppSection(
    route: '/photos',
    title: 'Photo Journal',
    icon: Icons.photo_library_rounded,
    color: Color(0xFFD6336C),
  );

  static const tasks = AppSection(
    route: '/tasks',
    title: 'Family Tasks',
    icon: Icons.task_alt_rounded,
    color: Color(0xFFE8590C),
  );

  static const List<AppSection> quickAccess = [
    itinerary,
    map,
    packing,
    budget,
    reservations,
    photoJournal,
    tasks,
  ];

  static const List<AppSection> all = [
    home,
    itinerary,
    map,
    packing,
    budget,
    reservations,
    photoJournal,
    tasks,
  ];
}
