import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PageFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title.trim().isNotEmpty || subtitle.trim().isNotEmpty || actions.isNotEmpty;

    if (!hasHeader) {
      return Container(
        color: AppTheme.bg,
        child: child,
      );
    }

    return Container(
      color: AppTheme.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              children: [
                if (title.trim().isNotEmpty || subtitle.trim().isNotEmpty)
                  SizedBox(
                    width: 520,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.trim().isNotEmpty)
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        if (subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (actions.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: actions,
                  ),
              ],
            ),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    );
  }
}