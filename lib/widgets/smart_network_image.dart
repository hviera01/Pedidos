import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/smart_image_url.dart';

class SmartNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const SmartNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SmartImageUrl.resolve(url),
      builder: (context, snap) {
        final resolved = snap.data ?? '';

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.panel2,
            borderRadius: borderRadius,
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: _image(resolved),
        );
      },
    );
  }

  Widget _image(String resolved) {
    if (resolved.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.image_rounded, color: AppTheme.muted),
      );
    }

    if (resolved.startsWith('data:image/')) {
      return Image.memory(
        UriData.parse(resolved).contentAsBytes(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _broken(),
      );
    }

    if (resolved.startsWith('assets/') || resolved.startsWith('img/')) {
      return Image.asset(
        resolved,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _broken(),
      );
    }

    return Image.network(
  resolved,
  width: width,
  height: height,
  fit: fit,
  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
  errorBuilder: (_, __, ___) => _broken(),
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;

    return const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  },
);
  }

  Widget _broken() {
    return const Center(
      child: Icon(Icons.broken_image_rounded, color: AppTheme.danger),
    );
  }
}