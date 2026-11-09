import 'package:flutter/material.dart';

import '../core/formatters.dart';

class ProductPlaceholder extends StatelessWidget {
  const ProductPlaceholder({
    super.key,
    required this.seed,
    required this.name,
    this.size = PlaceholderSize.card,
    this.borderRadius,
  });

  final String seed;
  final String name;
  final PlaceholderSize size;
  final BorderRadius? borderRadius;

  static const List<List<Color>> _palettes = [
    [Color(0xFF2563EB), Color(0xFF1E40AF)],
    [Color(0xFF0EA5E9), Color(0xFF0369A1)],
    [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    [Color(0xFF0D9488), Color(0xFF115E59)],
    [Color(0xFFDB2777), Color(0xFF9D174D)],
    [Color(0xFFEA580C), Color(0xFF9A3412)],
    [Color(0xFF4F46E5), Color(0xFF312E81)],
    [Color(0xFF334155), Color(0xFF0F172A)],
  ];

  static int _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('phone') || n.contains('galaxy')) return Icons.smartphone;
    if (n.contains('laptop') || n.contains('book') || n.contains('mac')) {
      return Icons.laptop_mac;
    }
    if (n.contains('tablet') || n.contains('pad')) return Icons.tablet_mac;
    if (n.contains('watch')) return Icons.watch;
    if (n.contains('head') || n.contains('ear') || n.contains('buds')) {
      return Icons.headphones;
    }
    if (n.contains('speaker')) return Icons.speaker;
    if (n.contains('tv') || n.contains('monitor') || n.contains('display')) {
      return Icons.tv;
    }
    if (n.contains('camera')) return Icons.photo_camera;
    if (n.contains('keyboard')) return Icons.keyboard;
    if (n.contains('mouse')) return Icons.mouse;
    if (n.contains('console') || n.contains('game')) {
      return Icons.sports_esports;
    }
    return Icons.devices_other;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[_hash(seed) % _palettes.length];
    final initials = Formatters.initials(name);
    final (double initialsSize, double iconSize) = switch (size) {
      PlaceholderSize.avatar => (15.0, 0.0),
      PlaceholderSize.card => (30.0, 18.0),
      PlaceholderSize.hero => (54.0, 28.0),
    };

    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: initialsSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (iconSize > 0)
              Positioned(
                right: 10,
                bottom: 10,
                child: Icon(
                  _iconFor(name),
                  color: Colors.white.withValues(alpha: 0.75),
                  size: iconSize,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum PlaceholderSize { avatar, card, hero }
