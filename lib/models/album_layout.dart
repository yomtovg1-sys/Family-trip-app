import 'package:flutter/material.dart';

/// The handful of clean, printable page layouts an album can use. Kept
/// small on purpose — a few good defaults rather than a full designer.
enum AlbumLayout { classic, grid, collage }

extension AlbumLayoutX on AlbumLayout {
  String get label {
    switch (this) {
      case AlbumLayout.classic:
        return 'Classic';
      case AlbumLayout.grid:
        return 'Grid';
      case AlbumLayout.collage:
        return 'Collage';
    }
  }

  String get description {
    switch (this) {
      case AlbumLayout.classic:
        return 'One full photo per page';
      case AlbumLayout.grid:
        return 'Four photos per page';
      case AlbumLayout.collage:
        return 'One large + two small per page';
    }
  }

  IconData get icon {
    switch (this) {
      case AlbumLayout.classic:
        return Icons.crop_square_rounded;
      case AlbumLayout.grid:
        return Icons.grid_view_rounded;
      case AlbumLayout.collage:
        return Icons.dashboard_customize_rounded;
    }
  }
}
