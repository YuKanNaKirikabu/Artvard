import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ArtImage extends StatefulWidget {
  final List<String> urls;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ArtImage({
    super.key,
    required this.urls,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<ArtImage> createState() => _ArtImageState();
}

class _ArtImageState extends State<ArtImage> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant ArtImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.urls, widget.urls)) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return _wrap(context, _fallback(context));
    }

    final url = widget.urls[_index];

    final image = CachedNetworkImage(
      imageUrl: url,
      fit: widget.fit,
      httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
      placeholder: (context, _) => _placeholder(context),
      errorWidget: (context, failedUrl, error) {
        debugPrint('Image load failed: $failedUrl; $error');
        if (_index < widget.urls.length - 1) {
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _index += 1;
              });
            }
          });
          return _placeholder(context);
        }
        return _fallback(context);
      },
    );

    return _wrap(context, image);
  }

  Widget _wrap(BuildContext context, Widget child) {
    final sized = (widget.width != null || widget.height != null)
        ? SizedBox(width: widget.width, height: widget.height, child: child)
        : SizedBox.expand(child: child);

    if (widget.borderRadius == null) {
      return sized;
    }

    return ClipRRect(borderRadius: widget.borderRadius!, child: sized);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, size: 28),
    );
  }
}
