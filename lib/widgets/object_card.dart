import 'package:flutter/material.dart';

import '../models/object_record.dart';
import 'art_image.dart';

class ObjectCard extends StatelessWidget {
  final ObjectRecord record;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const ObjectCard({
    super.key,
    required this.record,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  static const double _thumbSize = 88;

  @override
  Widget build(BuildContext context) {
    final imageUrls = record.imageCandidates(targetSize: 320);
    final subtitle = _buildSubtitle(record);

    final iconColor = isFavorite
        ? Colors.amber
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArtImage(
                urls: imageUrls,
                width: _thumbSize,
                height: _thumbSize,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: onFavoriteToggle,
                    tooltip: isFavorite
                        ? 'Убрать из избранного'
                        : 'В избранное',
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(ObjectRecord record) {
    final date = record.dated?.trim();
    final extra = record.culture?.trim() ?? record.classification?.trim();

    if (date != null && date.isNotEmpty && extra != null && extra.isNotEmpty) {
      return '$date • $extra';
    }

    if (date != null && date.isNotEmpty) return date;
    if (extra != null && extra.isNotEmpty) return extra;
    return 'Date unknown';
  }
}
