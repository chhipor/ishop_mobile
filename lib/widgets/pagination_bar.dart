import 'package:flutter/material.dart';

import '../app/theme.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  static List<int?> pageWindow(int page, int count) {
    if (count <= 7) return List.generate(count, (i) => i);
    final pages = <int>{
      0,
      count - 1,
      page - 1,
      page,
      page + 1,
    }.where((p) => p >= 0 && p < count).toList()..sort();
    final out = <int?>[];
    for (final p in pages) {
      if (out.isNotEmpty && p - out.last! > 1) out.add(null);
      out.add(p);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: 'Page ${page + 1} of $pageCount',
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 0 ? () => onChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          for (final p in pageWindow(page, pageCount))
            if (p == null)
              const ExcludeSemantics(
                child: SizedBox(
                  width: 24,
                  child: Text('…', textAlign: TextAlign.center),
                ),
              )
            else
              _PageButton(
                label: '${p + 1}',
                selected: p == page,
                onTap: () => onChanged(p),
                theme: theme,
              ),
          IconButton(
            tooltip: 'Next page',
            onPressed: page < pageCount - 1 ? () => onChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Page $label',
      excludeSemantics: true,
      child: Material(
        color: selected ? primary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? primary : AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: selected ? null : onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
