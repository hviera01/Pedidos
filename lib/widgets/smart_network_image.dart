import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/smart_image_url.dart';

class SmartNetworkImage extends StatefulWidget {
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
  State<SmartNetworkImage> createState() => _SmartNetworkImageState();
}

class _SmartNetworkImageState extends State<SmartNetworkImage> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = SmartImageUrl.resolve(widget.url);
  }

  @override
  void didUpdateWidget(SmartNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _future = SmartImageUrl.resolve(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppTheme.panel2,
            borderRadius: widget.borderRadius,
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: snap.connectionState != ConnectionState.done
              ? _spinner()
              : _image(snap.data ?? ''),
        );
      },
    );
  }

  Widget _spinner() {
    return const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
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
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _broken(),
      );
    }

    if (resolved.startsWith('assets/') || resolved.startsWith('img/')) {
      return Image.asset(
        resolved,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _broken(),
      );
    }

    return Image.network(
      resolved,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _broken(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _spinner();
      },
    );
  }

  Widget _broken() {
    return const Center(
      child: Icon(Icons.broken_image_rounded, color: AppTheme.danger),
    );
  }
}