import '../models/place.dart';
import '../models/trip_template.dart';

/// Storage for [TripTemplate]s. In-memory and seeded today; swapping in a
/// backend later (or letting families save their own trips as templates)
/// only means implementing this interface.
abstract class TemplateRepository {
  List<TripTemplate> getAll();
  TripTemplate? byId(String id);
}

class InMemoryTemplateRepository implements TemplateRepository {
  final List<TripTemplate> _templates = _seedTemplates();

  @override
  List<TripTemplate> getAll() => List.unmodifiable(_templates);

  @override
  TripTemplate? byId(String id) {
    for (final template in _templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  static List<TripTemplate> _seedTemplates() {
    return [
      const TripTemplate(
        id: 'template-japan',
        name: 'Japan Template',
        emoji: '🗼',
        description: 'A starting point for any Japan trip: rail-friendly packing, iconic spots, and visa prep.',
        packingItems: [
          TemplatePackingItem(name: 'Passport & visa copies', category: 'Essentials'),
          TemplatePackingItem(name: 'JR Rail Pass voucher', category: 'Essentials'),
          TemplatePackingItem(name: 'Portable WiFi / SIM', category: 'Electronics'),
          TemplatePackingItem(name: 'Comfortable walking shoes', category: 'Clothing'),
          TemplatePackingItem(name: 'Light rain jacket', category: 'Clothing'),
          TemplatePackingItem(name: 'Coin purse (cash-first culture)', category: 'Essentials'),
        ],
        favoritePlaces: [
          TemplatePlace(
            name: 'Shinjuku Gyoen',
            category: PlaceCategory.nature,
            area: 'Shinjuku, Tokyo',
            latitude: 35.6852,
            longitude: 139.7100,
          ),
          TemplatePlace(
            name: 'teamLab Planets',
            category: PlaceCategory.attractions,
            area: 'Toyosu, Tokyo',
            latitude: 35.6455,
            longitude: 139.7930,
            notes: 'Wear shorts — some rooms involve wading through water.',
          ),
          TemplatePlace(
            name: 'Ichiran Ramen Shinjuku',
            category: PlaceCategory.restaurants,
            area: 'Shinjuku, Tokyo',
            latitude: 35.6935,
            longitude: 139.7005,
          ),
        ],
        checklist: [
          'Check passport expiry (6+ months validity)',
          'Order a JR Rail Pass before departure',
          'Notify bank of travel dates',
          'Download offline maps for Tokyo/Kyoto',
        ],
        notes: [
          'Convenience stores (konbini) are reliable for cash, food, and SIM top-ups.',
          'Most restaurants are cash-only outside major chains — carry yen.',
        ],
      ),
      const TripTemplate(
        id: 'template-beach',
        name: 'Beach Getaway Template',
        emoji: '🏖️',
        description: 'Sun, sand, and nothing forgotten — packing and checklist for a relaxed beach trip.',
        packingItems: [
          TemplatePackingItem(name: 'Swimsuits', category: 'Clothing'),
          TemplatePackingItem(name: 'Reef-safe sunscreen', category: 'Toiletries'),
          TemplatePackingItem(name: 'Beach towels', category: 'Gear'),
          TemplatePackingItem(name: 'Snorkel gear', category: 'Gear'),
          TemplatePackingItem(name: 'Waterproof phone pouch', category: 'Electronics'),
        ],
        favoritePlaces: [],
        checklist: [
          'Check reef/marine park entry fees',
          'Book beachfront dinner reservation',
          'Confirm rental car has beach access permit (if needed)',
        ],
        notes: ['Book snorkeling or water tours a few days ahead — they fill up.'],
      ),
      const TripTemplate(
        id: 'template-road-trip',
        name: 'Road Trip Template',
        emoji: '🚗',
        description: 'For multi-stop drives: car essentials, roadside snacks, and a rest-stop checklist.',
        packingItems: [
          TemplatePackingItem(name: 'Phone car mount & charger', category: 'Electronics'),
          TemplatePackingItem(name: 'Cooler with snacks & drinks', category: 'Food'),
          TemplatePackingItem(name: 'First aid kit', category: 'Essentials'),
          TemplatePackingItem(name: 'Paper map / offline navigation', category: 'Essentials'),
        ],
        favoritePlaces: [],
        checklist: [
          'Check tire pressure and spare tire',
          'Download offline maps for the whole route',
          'Plan fuel/charging stops in advance',
        ],
        notes: ['Screenshot each night\'s hotel confirmation in case of no signal.'],
      ),
    ];
  }
}
