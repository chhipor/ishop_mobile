import 'package:flutter/material.dart';

import 'product_placeholder.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    required this.seed,
    required this.name,
    this.size = PlaceholderSize.card,
    this.borderRadius,
    this.padding,
  });

  final String? url;

  final String seed;
  final String name;
  final PlaceholderSize size;
  final BorderRadius? borderRadius;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final placeholder = ProductPlaceholder(
      seed: seed,
      name: name,
      size: size,
      borderRadius: borderRadius,
    );
    final src = url?.trim();
    if (src == null || src.isEmpty) return placeholder;

    final defaultPadding = switch (size) {
      PlaceholderSize.avatar => const EdgeInsets.all(2),
      PlaceholderSize.card => const EdgeInsets.all(10),
      PlaceholderSize.hero => const EdgeInsets.all(16),
    };

    return Semantics(
      image: true,
      label: name,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: padding ?? defaultPadding,
            child: Image.network(
              src,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              excludeFromSemantics: true,
              frameBuilder: (context, child, frame, wasSync) {
                if (wasSync) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: child,
                );
              },
              errorBuilder: (context, error, stack) => placeholder,
            ),
          ),
        ),
      ),
    );
  }
}
