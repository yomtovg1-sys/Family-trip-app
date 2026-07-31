import 'package:flutter/material.dart';

/// The kind of landscape silhouette drawn behind a trip's cover art — each
/// country is mapped to whichever of these best represents its signature
/// scenery.
enum LandscapeScene { mountain, coastalCliff, lakesForest, beach, desert, citySkyline, countryside }

/// A curated color treatment for a [LandscapeScene]. Several countries that
/// share a scene (e.g. two mountain nations) can still look different by
/// drawing from a different variant of that scene's palette.
class _ScenePalette {
  final List<Color> sky;
  final Color land;
  final Color accent;

  const _ScenePalette(this.sky, this.land, this.accent);
}

const Map<LandscapeScene, List<_ScenePalette>> _palettes = {
  LandscapeScene.mountain: [
    _ScenePalette([Color(0xFFFFD9B3), Color(0xFFFF9A76)], Color(0xFF3A4A66), Colors.white), // 0: warm alpenglow
    _ScenePalette([Color(0xFFBEE3F8), Color(0xFF7FB8E0)], Color(0xFF445566), Colors.white), // 1: cool snowy alps
    _ScenePalette([Color(0xFF1B2A4A), Color(0xFF16493E)], Color(0xFF0F1B2E), Color(0xFF7CF2C6)), // 2: arctic aurora
    _ScenePalette([Color(0xFFCDE7D8), Color(0xFF8BB79B)], Color(0xFF3F5B47), Color(0xFFE9DCC0)), // 3: andean earthy
    _ScenePalette([Color(0xFFE8E4D8), Color(0xFFC9BFA5)], Color(0xFF55524A), Colors.white), // 4: rugged rock
  ],
  LandscapeScene.coastalCliff: [
    _ScenePalette([Color(0xFFFFE8B8), Color(0xFFFFB88C)], Color(0xFFDDA15E), Color(0xFF2A6F77)), // 0: golden Amalfi
    _ScenePalette([Color(0xFFFFE3B3), Color(0xFFFF9E80)], Color(0xFF2E6F95), Colors.white), // 1: aegean sunset
    _ScenePalette([Color(0xFFBFD9E8), Color(0xFF7FA8C2)], Color(0xFF2C4A5C), Color(0xFFE8F2F5)), // 2: misty fjord
  ],
  LandscapeScene.lakesForest: [
    _ScenePalette([Color(0xFFCDEBD6), Color(0xFF8FCB9B)], Color(0xFF2E6B4F), Color(0xFFEFF7F1)), // 0: alpine lake
    _ScenePalette([Color(0xFFB8D8E0), Color(0xFF6FA8B8)], Color(0xFF1F4D3D), Color(0xFFE8F2E9)), // 1: northern pine
    _ScenePalette([Color(0xFF9FD8B0), Color(0xFF5FAE7A)], Color(0xFF1B4530), Color(0xFFE4EFC8)), // 2: tropical rainforest
  ],
  LandscapeScene.beach: [
    _ScenePalette([Color(0xFFAEE7F0), Color(0xFF6FCBDD)], Color(0xFF1F7A6C), Colors.white), // 0: turquoise lagoon
    _ScenePalette([Color(0xFFFFE3A3), Color(0xFFFF9F68)], Color(0xFF12796B), Color(0xFFEDE0C8)), // 1: golden lagoon
    _ScenePalette([Color(0xFFBEE8F5), Color(0xFF6FB9DE)], Color(0xFF0E7C8C), Colors.white), // 2: reef blue
  ],
  LandscapeScene.desert: [
    _ScenePalette([Color(0xFFFFE1A8), Color(0xFFFFB871)], Color(0xFFCB9A56), Color(0xFF8A6532)), // 0: golden dunes
    _ScenePalette([Color(0xFFFFD9A0), Color(0xFFFF8A65)], Color(0xFFA24E33), Color(0xFF7A3323)), // 1: red rock canyon
  ],
  LandscapeScene.citySkyline: [
    _ScenePalette([Color(0xFFE7D6E8), Color(0xFFB98CC2)], Color(0xFF2D2A3D), Color(0xFFFFD873)), // 0: dusk Paris
    _ScenePalette([Color(0xFF1B1F3B), Color(0xFF2E2A5C)], Color(0xFF121225), Color(0xFF5EE7FF)), // 1: neon night
    _ScenePalette([Color(0xFFFFD9A8), Color(0xFFFF8F6B)], Color(0xFF26262E), Color(0xFFFFC94D)), // 2: warm dusk
  ],
  LandscapeScene.countryside: [
    _ScenePalette([Color(0xFFFFEAB0), Color(0xFFFFB25E)], Color(0xFFC97B3D), Color(0xFF6B8E3D)), // 0: golden hills
    _ScenePalette([Color(0xFFD7E3E8), Color(0xFF9BB3BE)], Color(0xFF3E5C4A), Color(0xFF6B8E7A)), // 1: misty highlands
    _ScenePalette([Color(0xFFBFE0E8), Color(0xFF8FC7D6)], Color(0xFF2F6B45), Color(0xFF7FBF6B)), // 2: lush rolling green
  ],
};

/// A country selectable when creating or editing a trip. Choosing one
/// auto-fills everything a trip needs — flag, default currency, timezone,
/// and a landmark-matched landscape cover — so a family never has to look
/// any of that up by hand.
class Country {
  final String name;
  final String iso2;
  final String currency;
  final String timezone;
  final String landmark;
  final LandscapeScene scene;
  final int paletteVariant;
  final String? flagEmojiOverride;

  const Country({
    required this.name,
    required this.iso2,
    required this.currency,
    required this.timezone,
    required this.landmark,
    required this.scene,
    this.paletteVariant = 0,
    this.flagEmojiOverride,
  });

  /// Derived from [iso2] via Unicode regional indicator symbols, so every
  /// country's flag exists automatically with no per-country emoji to
  /// maintain or get out of sync.
  String get flagEmoji {
    if (flagEmojiOverride != null) return flagEmojiOverride!;
    final codeUnits = iso2.toUpperCase().codeUnits;
    return String.fromCharCodes(codeUnits.map((c) => 0x1F1E6 + (c - 0x41)));
  }

  List<Color> get sky => _palettes[scene]![paletteVariant].sky;
  Color get land => _palettes[scene]![paletteVariant].land;
  Color get accent => _palettes[scene]![paletteVariant].accent;
}

/// Every country a trip can be created for, alphabetically by continent
/// below (sort by [Country.name] for display). Timezone is each country's
/// single primary/capital IANA zone — a deliberate simplification for
/// countries that legally span several.
const List<Country> worldCountries = [
  // Europe
  Country(name: 'Albania', iso2: 'AL', currency: 'ALL', timezone: 'Europe/Tirane', landmark: 'The Albanian Riviera', scene: LandscapeScene.countryside, paletteVariant: 2),
  Country(name: 'Andorra', iso2: 'AD', currency: 'EUR', timezone: 'Europe/Andorra', landmark: 'The Pyrenees', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Austria', iso2: 'AT', currency: 'EUR', timezone: 'Europe/Vienna', landmark: 'The Austrian Alps', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Belarus', iso2: 'BY', currency: 'BYN', timezone: 'Europe/Minsk', landmark: 'Belarusian countryside', scene: LandscapeScene.countryside, paletteVariant: 2),
  Country(name: 'Belgium', iso2: 'BE', currency: 'EUR', timezone: 'Europe/Brussels', landmark: 'Brussels', scene: LandscapeScene.citySkyline, paletteVariant: 2),
  Country(name: 'Bosnia and Herzegovina', iso2: 'BA', currency: 'BAM', timezone: 'Europe/Sarajevo', landmark: 'The Dinaric Alps', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Bulgaria', iso2: 'BG', currency: 'BGN', timezone: 'Europe/Sofia', landmark: 'The Rila Mountains', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Croatia', iso2: 'HR', currency: 'EUR', timezone: 'Europe/Zagreb', landmark: 'Plitvice Lakes', scene: LandscapeScene.lakesForest, paletteVariant: 0),
  Country(name: 'Cyprus', iso2: 'CY', currency: 'EUR', timezone: 'Asia/Nicosia', landmark: 'The Mediterranean coast', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Czechia', iso2: 'CZ', currency: 'CZK', timezone: 'Europe/Prague', landmark: 'Prague', scene: LandscapeScene.citySkyline, paletteVariant: 2),
  Country(name: 'Denmark', iso2: 'DK', currency: 'DKK', timezone: 'Europe/Copenhagen', landmark: 'The Danish coast', scene: LandscapeScene.coastalCliff, paletteVariant: 1),
  Country(name: 'Estonia', iso2: 'EE', currency: 'EUR', timezone: 'Europe/Tallinn', landmark: 'Estonian forests', scene: LandscapeScene.lakesForest, paletteVariant: 1),
  Country(name: 'Finland', iso2: 'FI', currency: 'EUR', timezone: 'Europe/Helsinki', landmark: 'The Finnish Lakeland', scene: LandscapeScene.lakesForest, paletteVariant: 1),
  Country(name: 'France', iso2: 'FR', currency: 'EUR', timezone: 'Europe/Paris', landmark: 'Paris', scene: LandscapeScene.citySkyline, paletteVariant: 0),
  Country(name: 'Germany', iso2: 'DE', currency: 'EUR', timezone: 'Europe/Berlin', landmark: 'Berlin', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Greece', iso2: 'GR', currency: 'EUR', timezone: 'Europe/Athens', landmark: 'Santorini', scene: LandscapeScene.coastalCliff, paletteVariant: 1),
  Country(name: 'Hungary', iso2: 'HU', currency: 'HUF', timezone: 'Europe/Budapest', landmark: 'Budapest', scene: LandscapeScene.citySkyline, paletteVariant: 2),
  Country(name: 'Iceland', iso2: 'IS', currency: 'ISK', timezone: 'Atlantic/Reykjavik', landmark: 'The Northern Lights', scene: LandscapeScene.mountain, paletteVariant: 2),
  Country(name: 'Ireland', iso2: 'IE', currency: 'EUR', timezone: 'Europe/Dublin', landmark: 'The Cliffs of Moher', scene: LandscapeScene.countryside, paletteVariant: 2),
  Country(name: 'Italy', iso2: 'IT', currency: 'EUR', timezone: 'Europe/Rome', landmark: 'The Amalfi Coast', scene: LandscapeScene.coastalCliff, paletteVariant: 0),
  Country(name: 'Kosovo', iso2: 'XK', currency: 'EUR', timezone: 'Europe/Belgrade', landmark: 'The Sharr Mountains', scene: LandscapeScene.mountain, paletteVariant: 1, flagEmojiOverride: '🇽🇰'),
  Country(name: 'Latvia', iso2: 'LV', currency: 'EUR', timezone: 'Europe/Riga', landmark: 'The Gauja Valley', scene: LandscapeScene.lakesForest, paletteVariant: 1),
  Country(name: 'Liechtenstein', iso2: 'LI', currency: 'CHF', timezone: 'Europe/Vaduz', landmark: 'The Alps', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Lithuania', iso2: 'LT', currency: 'EUR', timezone: 'Europe/Vilnius', landmark: 'The Curonian Spit', scene: LandscapeScene.lakesForest, paletteVariant: 1),
  Country(name: 'Luxembourg', iso2: 'LU', currency: 'EUR', timezone: 'Europe/Luxembourg', landmark: 'Luxembourg countryside', scene: LandscapeScene.countryside, paletteVariant: 2),
  Country(name: 'Malta', iso2: 'MT', currency: 'EUR', timezone: 'Europe/Malta', landmark: 'The Maltese coast', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Moldova', iso2: 'MD', currency: 'MDL', timezone: 'Europe/Chisinau', landmark: 'Moldovan vineyards', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Monaco', iso2: 'MC', currency: 'EUR', timezone: 'Europe/Monaco', landmark: 'The Monte Carlo coast', scene: LandscapeScene.coastalCliff, paletteVariant: 1),
  Country(name: 'Montenegro', iso2: 'ME', currency: 'EUR', timezone: 'Europe/Podgorica', landmark: 'The Bay of Kotor', scene: LandscapeScene.coastalCliff, paletteVariant: 1),
  Country(name: 'Netherlands', iso2: 'NL', currency: 'EUR', timezone: 'Europe/Amsterdam', landmark: 'Dutch windmills and canals', scene: LandscapeScene.countryside, paletteVariant: 2),
  Country(name: 'North Macedonia', iso2: 'MK', currency: 'MKD', timezone: 'Europe/Skopje', landmark: 'The Macedonian mountains', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Norway', iso2: 'NO', currency: 'NOK', timezone: 'Europe/Oslo', landmark: 'The Norwegian Fjords', scene: LandscapeScene.coastalCliff, paletteVariant: 2),
  Country(name: 'Poland', iso2: 'PL', currency: 'PLN', timezone: 'Europe/Warsaw', landmark: 'Polish countryside', scene: LandscapeScene.countryside, paletteVariant: 2),
  Country(name: 'Portugal', iso2: 'PT', currency: 'EUR', timezone: 'Europe/Lisbon', landmark: 'The Algarve Coast', scene: LandscapeScene.coastalCliff, paletteVariant: 0),
  Country(name: 'Romania', iso2: 'RO', currency: 'RON', timezone: 'Europe/Bucharest', landmark: 'The Carpathian Mountains', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Russia', iso2: 'RU', currency: 'RUB', timezone: 'Europe/Moscow', landmark: 'Moscow', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'San Marino', iso2: 'SM', currency: 'EUR', timezone: 'Europe/San_Marino', landmark: 'Monte Titano', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Serbia', iso2: 'RS', currency: 'RSD', timezone: 'Europe/Belgrade', landmark: 'Belgrade', scene: LandscapeScene.citySkyline, paletteVariant: 2),
  Country(name: 'Slovakia', iso2: 'SK', currency: 'EUR', timezone: 'Europe/Bratislava', landmark: 'The Tatra Mountains', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Slovenia', iso2: 'SI', currency: 'EUR', timezone: 'Europe/Ljubljana', landmark: 'Lake Bled', scene: LandscapeScene.lakesForest, paletteVariant: 1),
  Country(name: 'Spain', iso2: 'ES', currency: 'EUR', timezone: 'Europe/Madrid', landmark: 'Andalusia', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Sweden', iso2: 'SE', currency: 'SEK', timezone: 'Europe/Stockholm', landmark: 'The Swedish archipelago', scene: LandscapeScene.lakesForest, paletteVariant: 1),
  Country(name: 'Switzerland', iso2: 'CH', currency: 'CHF', timezone: 'Europe/Zurich', landmark: 'The Swiss Alps', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Ukraine', iso2: 'UA', currency: 'UAH', timezone: 'Europe/Kyiv', landmark: 'Ukrainian countryside', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'United Kingdom', iso2: 'GB', currency: 'GBP', timezone: 'Europe/London', landmark: 'The Scottish Highlands', scene: LandscapeScene.countryside, paletteVariant: 1),
  Country(name: 'Vatican City', iso2: 'VA', currency: 'EUR', timezone: 'Europe/Vatican', landmark: "St. Peter's Basilica", scene: LandscapeScene.citySkyline, paletteVariant: 2),

  // Asia
  Country(name: 'Afghanistan', iso2: 'AF', currency: 'AFN', timezone: 'Asia/Kabul', landmark: 'The Hindu Kush', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Armenia', iso2: 'AM', currency: 'AMD', timezone: 'Asia/Yerevan', landmark: 'Mount Ararat', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Azerbaijan', iso2: 'AZ', currency: 'AZN', timezone: 'Asia/Baku', landmark: 'The Baku skyline', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Bahrain', iso2: 'BH', currency: 'BHD', timezone: 'Asia/Bahrain', landmark: 'The Manama skyline', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Bangladesh', iso2: 'BD', currency: 'BDT', timezone: 'Asia/Dhaka', landmark: 'The Sundarbans mangroves', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Bhutan', iso2: 'BT', currency: 'BTN', timezone: 'Asia/Thimphu', landmark: 'The Himalayan monasteries', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Brunei', iso2: 'BN', currency: 'BND', timezone: 'Asia/Brunei', landmark: 'The Bruneian rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Cambodia', iso2: 'KH', currency: 'KHR', timezone: 'Asia/Phnom_Penh', landmark: 'Angkor Wat', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'China', iso2: 'CN', currency: 'CNY', timezone: 'Asia/Shanghai', landmark: 'The Shanghai skyline', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Georgia', iso2: 'GE', currency: 'GEL', timezone: 'Asia/Tbilisi', landmark: 'The Caucasus Mountains', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'India', iso2: 'IN', currency: 'INR', timezone: 'Asia/Kolkata', landmark: 'The Taj Mahal', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Indonesia', iso2: 'ID', currency: 'IDR', timezone: 'Asia/Jakarta', landmark: 'Bali', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Iran', iso2: 'IR', currency: 'IRR', timezone: 'Asia/Tehran', landmark: 'The Persian desert', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Iraq', iso2: 'IQ', currency: 'IQD', timezone: 'Asia/Baghdad', landmark: 'The Mesopotamian plains', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Israel', iso2: 'IL', currency: 'ILS', timezone: 'Asia/Jerusalem', landmark: 'The Dead Sea', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Japan', iso2: 'JP', currency: 'JPY', timezone: 'Asia/Tokyo', landmark: 'Mount Fuji', scene: LandscapeScene.mountain, paletteVariant: 0),
  Country(name: 'Jordan', iso2: 'JO', currency: 'JOD', timezone: 'Asia/Amman', landmark: 'Petra', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Kazakhstan', iso2: 'KZ', currency: 'KZT', timezone: 'Asia/Almaty', landmark: 'The Kazakh steppe', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Kuwait', iso2: 'KW', currency: 'KWD', timezone: 'Asia/Kuwait', landmark: 'The Kuwaiti desert', scene: LandscapeScene.desert, paletteVariant: 1),
  Country(name: 'Kyrgyzstan', iso2: 'KG', currency: 'KGS', timezone: 'Asia/Bishkek', landmark: 'The Tian Shan Mountains', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Laos', iso2: 'LA', currency: 'LAK', timezone: 'Asia/Vientiane', landmark: 'Laotian mountains', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Lebanon', iso2: 'LB', currency: 'LBP', timezone: 'Asia/Beirut', landmark: 'The Beirut coastline', scene: LandscapeScene.coastalCliff, paletteVariant: 1),
  Country(name: 'Malaysia', iso2: 'MY', currency: 'MYR', timezone: 'Asia/Kuala_Lumpur', landmark: 'The Kuala Lumpur skyline', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Maldives', iso2: 'MV', currency: 'MVR', timezone: 'Indian/Maldives', landmark: 'The Maldives atolls', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Mongolia', iso2: 'MN', currency: 'MNT', timezone: 'Asia/Ulaanbaatar', landmark: 'The Mongolian steppe', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Myanmar', iso2: 'MM', currency: 'MMK', timezone: 'Asia/Yangon', landmark: 'The Bagan temples', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Nepal', iso2: 'NP', currency: 'NPR', timezone: 'Asia/Kathmandu', landmark: 'The Himalayas', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'North Korea', iso2: 'KP', currency: 'KPW', timezone: 'Asia/Pyongyang', landmark: 'Pyongyang', scene: LandscapeScene.citySkyline, paletteVariant: 2),
  Country(name: 'Oman', iso2: 'OM', currency: 'OMR', timezone: 'Asia/Muscat', landmark: 'The Omani desert', scene: LandscapeScene.desert, paletteVariant: 1),
  Country(name: 'Pakistan', iso2: 'PK', currency: 'PKR', timezone: 'Asia/Karachi', landmark: 'The Karakoram Range', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Palestine', iso2: 'PS', currency: 'ILS', timezone: 'Asia/Gaza', landmark: 'The hills of Bethlehem', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Philippines', iso2: 'PH', currency: 'PHP', timezone: 'Asia/Manila', landmark: 'Palawan', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Qatar', iso2: 'QA', currency: 'QAR', timezone: 'Asia/Qatar', landmark: 'The Doha skyline', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Saudi Arabia', iso2: 'SA', currency: 'SAR', timezone: 'Asia/Riyadh', landmark: 'The Arabian desert', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Singapore', iso2: 'SG', currency: 'SGD', timezone: 'Asia/Singapore', landmark: 'The Singapore skyline', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'South Korea', iso2: 'KR', currency: 'KRW', timezone: 'Asia/Seoul', landmark: 'The Seoul skyline', scene: LandscapeScene.citySkyline, paletteVariant: 2),
  Country(name: 'Sri Lanka', iso2: 'LK', currency: 'LKR', timezone: 'Asia/Colombo', landmark: 'The Sri Lankan coast', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Syria', iso2: 'SY', currency: 'SYP', timezone: 'Asia/Damascus', landmark: 'The Syrian desert', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Taiwan', iso2: 'TW', currency: 'TWD', timezone: 'Asia/Taipei', landmark: 'Taipei 101', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Tajikistan', iso2: 'TJ', currency: 'TJS', timezone: 'Asia/Dushanbe', landmark: 'The Pamir Mountains', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Thailand', iso2: 'TH', currency: 'THB', timezone: 'Asia/Bangkok', landmark: 'The Phi Phi Islands', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Timor-Leste', iso2: 'TL', currency: 'USD', timezone: 'Asia/Dili', landmark: 'The Timorese coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Turkey', iso2: 'TR', currency: 'TRY', timezone: 'Europe/Istanbul', landmark: "Cappadocia's fairy chimneys", scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Turkmenistan', iso2: 'TM', currency: 'TMT', timezone: 'Asia/Ashgabat', landmark: 'The Karakum Desert', scene: LandscapeScene.desert, paletteVariant: 1),
  Country(name: 'United Arab Emirates', iso2: 'AE', currency: 'AED', timezone: 'Asia/Dubai', landmark: 'The Dubai skyline', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Uzbekistan', iso2: 'UZ', currency: 'UZS', timezone: 'Asia/Tashkent', landmark: 'Samarkand', scene: LandscapeScene.citySkyline, paletteVariant: 2),
  Country(name: 'Vietnam', iso2: 'VN', currency: 'VND', timezone: 'Asia/Ho_Chi_Minh', landmark: 'Ha Long Bay', scene: LandscapeScene.coastalCliff, paletteVariant: 1),
  Country(name: 'Yemen', iso2: 'YE', currency: 'YER', timezone: 'Asia/Aden', landmark: 'The Yemeni highlands', scene: LandscapeScene.desert, paletteVariant: 0),

  // Africa
  Country(name: 'Algeria', iso2: 'DZ', currency: 'DZD', timezone: 'Africa/Algiers', landmark: 'The Sahara dunes', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Angola', iso2: 'AO', currency: 'AOA', timezone: 'Africa/Luanda', landmark: 'The Angolan coast', scene: LandscapeScene.coastalCliff, paletteVariant: 1),
  Country(name: 'Benin', iso2: 'BJ', currency: 'XOF', timezone: 'Africa/Porto-Novo', landmark: 'Beninese savanna', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Botswana', iso2: 'BW', currency: 'BWP', timezone: 'Africa/Gaborone', landmark: 'The Okavango Delta', scene: LandscapeScene.countryside, paletteVariant: 2),
  Country(name: 'Burkina Faso', iso2: 'BF', currency: 'XOF', timezone: 'Africa/Ouagadougou', landmark: 'The Sahel', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Burundi', iso2: 'BI', currency: 'BIF', timezone: 'Africa/Bujumbura', landmark: 'Lake Tanganyika', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Cabo Verde', iso2: 'CV', currency: 'CVE', timezone: 'Atlantic/Cape_Verde', landmark: 'The Cabo Verde islands', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Cameroon', iso2: 'CM', currency: 'XAF', timezone: 'Africa/Douala', landmark: 'Mount Cameroon', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Central African Republic', iso2: 'CF', currency: 'XAF', timezone: 'Africa/Bangui', landmark: 'The Central African rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Chad', iso2: 'TD', currency: 'XAF', timezone: 'Africa/Ndjamena', landmark: 'The Sahel', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Comoros', iso2: 'KM', currency: 'KMF', timezone: 'Indian/Comoro', landmark: 'The Comoros coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Congo, Democratic Republic of the', iso2: 'CD', currency: 'CDF', timezone: 'Africa/Kinshasa', landmark: 'The Congo Rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Congo, Republic of the', iso2: 'CG', currency: 'XAF', timezone: 'Africa/Brazzaville', landmark: 'The Congo River', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Djibouti', iso2: 'DJ', currency: 'DJF', timezone: 'Africa/Djibouti', landmark: 'Lake Assal', scene: LandscapeScene.desert, paletteVariant: 1),
  Country(name: 'Egypt', iso2: 'EG', currency: 'EGP', timezone: 'Africa/Cairo', landmark: 'The Pyramids of Giza', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Equatorial Guinea', iso2: 'GQ', currency: 'XAF', timezone: 'Africa/Malabo', landmark: 'Bioko Island', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Eritrea', iso2: 'ER', currency: 'ERN', timezone: 'Africa/Asmara', landmark: 'The Eritrean coast', scene: LandscapeScene.desert, paletteVariant: 1),
  Country(name: 'Eswatini', iso2: 'SZ', currency: 'SZL', timezone: 'Africa/Mbabane', landmark: 'The Eswatini highlands', scene: LandscapeScene.countryside, paletteVariant: 1),
  Country(name: 'Ethiopia', iso2: 'ET', currency: 'ETB', timezone: 'Africa/Addis_Ababa', landmark: 'The Simien Mountains', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Gabon', iso2: 'GA', currency: 'XAF', timezone: 'Africa/Libreville', landmark: 'The Gabonese rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Gambia', iso2: 'GM', currency: 'GMD', timezone: 'Africa/Banjul', landmark: 'The Gambia River', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Ghana', iso2: 'GH', currency: 'GHS', timezone: 'Africa/Accra', landmark: 'The Ghanaian coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Guinea', iso2: 'GN', currency: 'GNF', timezone: 'Africa/Conakry', landmark: 'The Fouta Djallon highlands', scene: LandscapeScene.countryside, paletteVariant: 1),
  Country(name: 'Guinea-Bissau', iso2: 'GW', currency: 'XOF', timezone: 'Africa/Bissau', landmark: 'The Bijagós Islands', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Ivory Coast', iso2: 'CI', currency: 'XOF', timezone: 'Africa/Abidjan', landmark: 'The Ivorian coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Kenya', iso2: 'KE', currency: 'KES', timezone: 'Africa/Nairobi', landmark: 'The Maasai Mara', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Lesotho', iso2: 'LS', currency: 'LSL', timezone: 'Africa/Maseru', landmark: 'The Drakensberg Mountains', scene: LandscapeScene.mountain, paletteVariant: 4),
  Country(name: 'Liberia', iso2: 'LR', currency: 'LRD', timezone: 'Africa/Monrovia', landmark: 'The Liberian coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Libya', iso2: 'LY', currency: 'LYD', timezone: 'Africa/Tripoli', landmark: 'The Libyan desert', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Madagascar', iso2: 'MG', currency: 'MGA', timezone: 'Indian/Antananarivo', landmark: 'The Avenue of the Baobabs', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Malawi', iso2: 'MW', currency: 'MWK', timezone: 'Africa/Blantyre', landmark: 'Lake Malawi', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Mali', iso2: 'ML', currency: 'XOF', timezone: 'Africa/Bamako', landmark: 'Timbuktu', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Mauritania', iso2: 'MR', currency: 'MRU', timezone: 'Africa/Nouakchott', landmark: 'The Sahara', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Mauritius', iso2: 'MU', currency: 'MUR', timezone: 'Indian/Mauritius', landmark: 'Mauritius lagoons', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Morocco', iso2: 'MA', currency: 'MAD', timezone: 'Africa/Casablanca', landmark: 'The Sahara and the Atlas Mountains', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Mozambique', iso2: 'MZ', currency: 'MZN', timezone: 'Africa/Maputo', landmark: 'The Mozambican coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Namibia', iso2: 'NA', currency: 'NAD', timezone: 'Africa/Windhoek', landmark: 'The Namib Desert dunes', scene: LandscapeScene.desert, paletteVariant: 1),
  Country(name: 'Niger', iso2: 'NE', currency: 'XOF', timezone: 'Africa/Niamey', landmark: 'The Ténéré Desert', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Nigeria', iso2: 'NG', currency: 'NGN', timezone: 'Africa/Lagos', landmark: 'The Lagos skyline', scene: LandscapeScene.citySkyline, paletteVariant: 1),
  Country(name: 'Rwanda', iso2: 'RW', currency: 'RWF', timezone: 'Africa/Kigali', landmark: 'Volcanoes National Park', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Sao Tome and Principe', iso2: 'ST', currency: 'STN', timezone: 'Africa/Sao_Tome', landmark: 'The São Tomé coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Senegal', iso2: 'SN', currency: 'XOF', timezone: 'Africa/Dakar', landmark: 'The Senegalese coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Seychelles', iso2: 'SC', currency: 'SCR', timezone: 'Indian/Mahe', landmark: 'Seychelles beaches', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Sierra Leone', iso2: 'SL', currency: 'SLE', timezone: 'Africa/Freetown', landmark: 'The Freetown peninsula', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Somalia', iso2: 'SO', currency: 'SOS', timezone: 'Africa/Mogadishu', landmark: 'The Somali coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'South Africa', iso2: 'ZA', currency: 'ZAR', timezone: 'Africa/Johannesburg', landmark: 'Table Mountain', scene: LandscapeScene.mountain, paletteVariant: 4),
  Country(name: 'South Sudan', iso2: 'SS', currency: 'SSP', timezone: 'Africa/Juba', landmark: 'South Sudanese savanna', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Sudan', iso2: 'SD', currency: 'SDG', timezone: 'Africa/Khartoum', landmark: 'The Nubian desert', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Tanzania', iso2: 'TZ', currency: 'TZS', timezone: 'Africa/Dar_es_Salaam', landmark: 'Mount Kilimanjaro', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Togo', iso2: 'TG', currency: 'XOF', timezone: 'Africa/Lome', landmark: 'The Togolese coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Tunisia', iso2: 'TN', currency: 'TND', timezone: 'Africa/Tunis', landmark: 'The Sahara Desert', scene: LandscapeScene.desert, paletteVariant: 0),
  Country(name: 'Uganda', iso2: 'UG', currency: 'UGX', timezone: 'Africa/Kampala', landmark: 'Lake Victoria', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Zambia', iso2: 'ZM', currency: 'ZMW', timezone: 'Africa/Lusaka', landmark: 'Victoria Falls', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Zimbabwe', iso2: 'ZW', currency: 'ZWL', timezone: 'Africa/Harare', landmark: 'Victoria Falls', scene: LandscapeScene.countryside, paletteVariant: 0),

  // North America & Caribbean
  Country(name: 'Antigua and Barbuda', iso2: 'AG', currency: 'XCD', timezone: 'America/Antigua', landmark: "Antigua's beaches", scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Bahamas', iso2: 'BS', currency: 'BSD', timezone: 'America/Nassau', landmark: 'The Bahamian cays', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Barbados', iso2: 'BB', currency: 'BBD', timezone: 'America/Barbados', landmark: 'The Barbados coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Belize', iso2: 'BZ', currency: 'BZD', timezone: 'America/Belize', landmark: 'The Belize Barrier Reef', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Canada', iso2: 'CA', currency: 'CAD', timezone: 'America/Toronto', landmark: 'The Canadian Rockies', scene: LandscapeScene.mountain, paletteVariant: 1),
  Country(name: 'Costa Rica', iso2: 'CR', currency: 'CRC', timezone: 'America/Costa_Rica', landmark: 'The Costa Rican rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Cuba', iso2: 'CU', currency: 'CUP', timezone: 'America/Havana', landmark: 'Havana', scene: LandscapeScene.citySkyline, paletteVariant: 2),
  Country(name: 'Dominica', iso2: 'DM', currency: 'XCD', timezone: 'America/Dominica', landmark: "Dominica's rainforest", scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Dominican Republic', iso2: 'DO', currency: 'DOP', timezone: 'America/Santo_Domingo', landmark: 'Punta Cana', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'El Salvador', iso2: 'SV', currency: 'USD', timezone: 'America/El_Salvador', landmark: 'The Salvadoran coast', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Grenada', iso2: 'GD', currency: 'XCD', timezone: 'America/Grenada', landmark: "Grenada's coast", scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Guatemala', iso2: 'GT', currency: 'GTQ', timezone: 'America/Guatemala', landmark: 'Lake Atitlán', scene: LandscapeScene.mountain, paletteVariant: 3),
  Country(name: 'Haiti', iso2: 'HT', currency: 'HTG', timezone: 'America/Port-au-Prince', landmark: 'The Haitian coast', scene: LandscapeScene.coastalCliff, paletteVariant: 1),
  Country(name: 'Honduras', iso2: 'HN', currency: 'HNL', timezone: 'America/Tegucigalpa', landmark: 'Roatán', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Jamaica', iso2: 'JM', currency: 'JMD', timezone: 'America/Jamaica', landmark: 'The Jamaican coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Mexico', iso2: 'MX', currency: 'MXN', timezone: 'America/Mexico_City', landmark: 'Tulum', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Nicaragua', iso2: 'NI', currency: 'NIO', timezone: 'America/Managua', landmark: 'Lake Nicaragua', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Panama', iso2: 'PA', currency: 'PAB', timezone: 'America/Panama', landmark: 'The Panama Canal rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Saint Kitts and Nevis', iso2: 'KN', currency: 'XCD', timezone: 'America/St_Kitts', landmark: 'The St. Kitts coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Saint Lucia', iso2: 'LC', currency: 'XCD', timezone: 'America/St_Lucia', landmark: 'The Pitons', scene: LandscapeScene.mountain, paletteVariant: 0),
  Country(name: 'Saint Vincent and the Grenadines', iso2: 'VC', currency: 'XCD', timezone: 'America/St_Vincent', landmark: 'The Grenadines', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Trinidad and Tobago', iso2: 'TT', currency: 'TTD', timezone: 'America/Port_of_Spain', landmark: "Tobago's coast", scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'United States', iso2: 'US', currency: 'USD', timezone: 'America/New_York', landmark: 'The Grand Canyon', scene: LandscapeScene.desert, paletteVariant: 1),

  // South America
  Country(name: 'Argentina', iso2: 'AR', currency: 'ARS', timezone: 'America/Argentina/Buenos_Aires', landmark: 'Patagonia', scene: LandscapeScene.mountain, paletteVariant: 4),
  Country(name: 'Bolivia', iso2: 'BO', currency: 'BOB', timezone: 'America/La_Paz', landmark: 'The Salar de Uyuni', scene: LandscapeScene.desert, paletteVariant: 1),
  Country(name: 'Brazil', iso2: 'BR', currency: 'BRL', timezone: 'America/Sao_Paulo', landmark: 'The Amazon Rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Chile', iso2: 'CL', currency: 'CLP', timezone: 'America/Santiago', landmark: 'Torres del Paine', scene: LandscapeScene.mountain, paletteVariant: 4),
  Country(name: 'Colombia', iso2: 'CO', currency: 'COP', timezone: 'America/Bogota', landmark: 'The Coffee Triangle', scene: LandscapeScene.mountain, paletteVariant: 3),
  Country(name: 'Ecuador', iso2: 'EC', currency: 'USD', timezone: 'America/Guayaquil', landmark: 'The Galápagos Islands', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Guyana', iso2: 'GY', currency: 'GYD', timezone: 'America/Guyana', landmark: 'Kaieteur Falls', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Paraguay', iso2: 'PY', currency: 'PYG', timezone: 'America/Asuncion', landmark: 'Paraguayan countryside', scene: LandscapeScene.countryside, paletteVariant: 0),
  Country(name: 'Peru', iso2: 'PE', currency: 'PEN', timezone: 'America/Lima', landmark: 'Machu Picchu', scene: LandscapeScene.mountain, paletteVariant: 3),
  Country(name: 'Suriname', iso2: 'SR', currency: 'SRD', timezone: 'America/Paramaribo', landmark: 'Surinamese rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Uruguay', iso2: 'UY', currency: 'UYU', timezone: 'America/Montevideo', landmark: 'The Uruguayan coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Venezuela', iso2: 'VE', currency: 'VES', timezone: 'America/Caracas', landmark: 'Angel Falls', scene: LandscapeScene.mountain, paletteVariant: 0),

  // Oceania
  Country(name: 'Australia', iso2: 'AU', currency: 'AUD', timezone: 'Australia/Sydney', landmark: 'The Great Barrier Reef', scene: LandscapeScene.beach, paletteVariant: 2),
  Country(name: 'Fiji', iso2: 'FJ', currency: 'FJD', timezone: 'Pacific/Fiji', landmark: 'The Fijian islands', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Kiribati', iso2: 'KI', currency: 'AUD', timezone: 'Pacific/Tarawa', landmark: 'The Kiribati atolls', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Marshall Islands', iso2: 'MH', currency: 'USD', timezone: 'Pacific/Majuro', landmark: 'The Marshall Islands', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Micronesia', iso2: 'FM', currency: 'USD', timezone: 'Pacific/Pohnpei', landmark: 'Micronesian reefs', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Nauru', iso2: 'NR', currency: 'AUD', timezone: 'Pacific/Nauru', landmark: 'The Nauru coast', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'New Zealand', iso2: 'NZ', currency: 'NZD', timezone: 'Pacific/Auckland', landmark: 'Milford Sound', scene: LandscapeScene.coastalCliff, paletteVariant: 2),
  Country(name: 'Palau', iso2: 'PW', currency: 'USD', timezone: 'Pacific/Palau', landmark: 'The Rock Islands', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Papua New Guinea', iso2: 'PG', currency: 'PGK', timezone: 'Pacific/Port_Moresby', landmark: 'Papua New Guinean rainforest', scene: LandscapeScene.lakesForest, paletteVariant: 2),
  Country(name: 'Samoa', iso2: 'WS', currency: 'WST', timezone: 'Pacific/Apia', landmark: 'Samoan beaches', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Solomon Islands', iso2: 'SB', currency: 'SBD', timezone: 'Pacific/Guadalcanal', landmark: 'The Solomon Islands', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Tonga', iso2: 'TO', currency: 'TOP', timezone: 'Pacific/Tongatapu', landmark: 'Tongan reefs', scene: LandscapeScene.beach, paletteVariant: 0),
  Country(name: 'Tuvalu', iso2: 'TV', currency: 'AUD', timezone: 'Pacific/Funafuti', landmark: 'The Tuvalu atolls', scene: LandscapeScene.beach, paletteVariant: 1),
  Country(name: 'Vanuatu', iso2: 'VU', currency: 'VUV', timezone: 'Pacific/Efate', landmark: 'Vanuatu volcanoes', scene: LandscapeScene.beach, paletteVariant: 1),
];

/// Shown when a trip has no matching or recognized country — never assigned
/// by the country picker itself, only used as a safe default.
const Country fallbackCountry = Country(
  name: 'Other',
  iso2: '',
  currency: 'USD',
  timezone: 'UTC',
  landmark: 'Somewhere Beautiful',
  scene: LandscapeScene.countryside,
  paletteVariant: 2,
  flagEmojiOverride: '🌍',
);

/// Case-insensitive lookup by country name, e.g. as stored on a [Trip].
/// Returns null if [name] is null/blank so callers can fall back to their
/// own default (e.g. no cover at all vs. [fallbackCountry]).
Country? countryByName(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final normalized = name.trim().toLowerCase();
  for (final country in worldCountries) {
    if (country.name.toLowerCase() == normalized) return country;
  }
  return fallbackCountry;
}
