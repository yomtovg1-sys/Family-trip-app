import 'package:flutter/material.dart';

/// The kind of landscape silhouette drawn behind a trip's cover art — each
/// destination country is mapped to whichever of these best represents its
/// signature scenery.
enum LandscapeScene { mountain, coastalCliff, lakesForest, beach, desert, citySkyline, countryside }

/// A destination country's auto-assigned cover: a well-known landmark
/// rendered as a simple vector landscape, so every trip gets a beautiful,
/// destination-matched cover with no network fetch and no licensing risk.
class DestinationCover {
  final String country;
  final String flagEmoji;
  final String landmark;
  final LandscapeScene scene;
  final List<Color> sky;
  final Color land;
  final Color accent;

  const DestinationCover({
    required this.country,
    required this.flagEmoji,
    required this.landmark,
    required this.scene,
    required this.sky,
    required this.land,
    required this.accent,
  });
}

/// Common family-trip destinations, each with a landmark-matched cover.
/// Not exhaustive — [fallbackCover] covers any country not listed here.
const List<DestinationCover> destinationCovers = [
  DestinationCover(
    country: 'Japan',
    flagEmoji: '🇯🇵',
    landmark: 'Mount Fuji',
    scene: LandscapeScene.mountain,
    sky: [Color(0xFFFFD9B3), Color(0xFFFF9A76)],
    land: Color(0xFF3A4A66),
    accent: Colors.white,
  ),
  DestinationCover(
    country: 'Italy',
    flagEmoji: '🇮🇹',
    landmark: 'Amalfi Coast',
    scene: LandscapeScene.coastalCliff,
    sky: [Color(0xFFFFE8B8), Color(0xFFFFB88C)],
    land: Color(0xFFDDA15E),
    accent: Color(0xFF2A6F77),
  ),
  DestinationCover(
    country: 'Switzerland',
    flagEmoji: '🇨🇭',
    landmark: 'The Swiss Alps',
    scene: LandscapeScene.mountain,
    sky: [Color(0xFFBEE3F8), Color(0xFF7FB8E0)],
    land: Color(0xFF445566),
    accent: Colors.white,
  ),
  DestinationCover(
    country: 'Croatia',
    flagEmoji: '🇭🇷',
    landmark: 'Plitvice Lakes',
    scene: LandscapeScene.lakesForest,
    sky: [Color(0xFFCDEBD6), Color(0xFF8FCB9B)],
    land: Color(0xFF2E6B4F),
    accent: Color(0xFFEFF7F1),
  ),
  DestinationCover(
    country: 'France',
    flagEmoji: '🇫🇷',
    landmark: 'Paris',
    scene: LandscapeScene.citySkyline,
    sky: [Color(0xFFE7D6E8), Color(0xFFB98CC2)],
    land: Color(0xFF2D2A3D),
    accent: Color(0xFFFFD873),
  ),
  DestinationCover(
    country: 'Greece',
    flagEmoji: '🇬🇷',
    landmark: 'Santorini',
    scene: LandscapeScene.coastalCliff,
    sky: [Color(0xFFFFE3B3), Color(0xFFFF9E80)],
    land: Color(0xFF2E6F95),
    accent: Colors.white,
  ),
  DestinationCover(
    country: 'Spain',
    flagEmoji: '🇪🇸',
    landmark: 'Andalusia',
    scene: LandscapeScene.countryside,
    sky: [Color(0xFFFFEAB0), Color(0xFFFFB25E)],
    land: Color(0xFFC97B3D),
    accent: Color(0xFF6B8E3D),
  ),
  DestinationCover(
    country: 'United States',
    flagEmoji: '🇺🇸',
    landmark: 'Grand Canyon',
    scene: LandscapeScene.desert,
    sky: [Color(0xFFFFD9A0), Color(0xFFFF8A65)],
    land: Color(0xFFA24E33),
    accent: Color(0xFF7A3323),
  ),
  DestinationCover(
    country: 'United Kingdom',
    flagEmoji: '🇬🇧',
    landmark: 'Scottish Highlands',
    scene: LandscapeScene.countryside,
    sky: [Color(0xFFD7E3E8), Color(0xFF9BB3BE)],
    land: Color(0xFF3E5C4A),
    accent: Color(0xFF6B8E7A),
  ),
  DestinationCover(
    country: 'Iceland',
    flagEmoji: '🇮🇸',
    landmark: 'Northern Lights',
    scene: LandscapeScene.mountain,
    sky: [Color(0xFF1B2A4A), Color(0xFF16493E)],
    land: Color(0xFF0F1B2E),
    accent: Color(0xFF7CF2C6),
  ),
  DestinationCover(
    country: 'Thailand',
    flagEmoji: '🇹🇭',
    landmark: 'Phi Phi Islands',
    scene: LandscapeScene.beach,
    sky: [Color(0xFFAEE7F0), Color(0xFF6FCBDD)],
    land: Color(0xFF1F7A6C),
    accent: Colors.white,
  ),
  DestinationCover(
    country: 'Portugal',
    flagEmoji: '🇵🇹',
    landmark: 'Algarve Coast',
    scene: LandscapeScene.coastalCliff,
    sky: [Color(0xFFFFE0B0), Color(0xFFFF9E6B)],
    land: Color(0xFFB5722E),
    accent: Color(0xFF1D6E86),
  ),
  DestinationCover(
    country: 'Mexico',
    flagEmoji: '🇲🇽',
    landmark: 'Tulum',
    scene: LandscapeScene.beach,
    sky: [Color(0xFFFFE3A3), Color(0xFFFF9F68)],
    land: Color(0xFF12796B),
    accent: Color(0xFFEDE0C8),
  ),
  DestinationCover(
    country: 'Australia',
    flagEmoji: '🇦🇺',
    landmark: 'Great Barrier Reef',
    scene: LandscapeScene.beach,
    sky: [Color(0xFFBEE8F5), Color(0xFF6FB9DE)],
    land: Color(0xFF0E7C8C),
    accent: Colors.white,
  ),
  DestinationCover(
    country: 'Egypt',
    flagEmoji: '🇪🇬',
    landmark: 'Pyramids of Giza',
    scene: LandscapeScene.desert,
    sky: [Color(0xFFFFE1A8), Color(0xFFFFB871)],
    land: Color(0xFFCB9A56),
    accent: Color(0xFF8A6532),
  ),
  DestinationCover(
    country: 'Peru',
    flagEmoji: '🇵🇪',
    landmark: 'Machu Picchu',
    scene: LandscapeScene.mountain,
    sky: [Color(0xFFCDE7D8), Color(0xFF8BB79B)],
    land: Color(0xFF3F5B47),
    accent: Color(0xFFE9DCC0),
  ),
];

const DestinationCover fallbackCover = DestinationCover(
  country: 'Other',
  flagEmoji: '🌍',
  landmark: 'Somewhere Beautiful',
  scene: LandscapeScene.countryside,
  sky: [Color(0xFFBFD9EA), Color(0xFF8FB9CE)],
  land: Color(0xFF4A6B57),
  accent: Color(0xFFEFE7D0),
);

/// Case-insensitive lookup by country name, e.g. as chosen in the trip
/// creation form. Returns null if [country] is null/blank so callers can
/// fall back to their own default (e.g. no cover at all vs. [fallbackCover]).
DestinationCover? destinationCoverFor(String? country) {
  if (country == null || country.trim().isEmpty) return null;
  final normalized = country.trim().toLowerCase();
  for (final cover in destinationCovers) {
    if (cover.country.toLowerCase() == normalized) return cover;
  }
  return fallbackCover;
}
