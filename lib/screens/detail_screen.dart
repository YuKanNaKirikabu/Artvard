import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/object_record.dart';
import '../widgets/art_image.dart';

class DetailScreen extends StatelessWidget {
  final ObjectRecord record;

  const DetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final detailsUrl =
        record.url ??
        'https://www.harvardartmuseums.org/collections/object/${record.id}';

    return Scaffold(
      appBar: AppBar(title: Text(record.displayTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(imageUrls: record.imageCandidates(targetSize: 1200)),
            const SizedBox(height: 16),
            Text(
              record.displayTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Author', value: _peopleLine(record.people)),
            _InfoRow(label: 'Dated', value: record.dated),
            _InfoRow(label: 'Culture', value: record.culture),
            _InfoRow(label: 'Medium', value: record.medium),
            const SizedBox(height: 16),
            _DescriptionBlock(text: record.descriptionText),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openInBrowser(context, detailsUrl),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Открыть в браузере'),
            ),
          ],
        ),
      ),
    );
  }

  String? _peopleLine(List<Person> people) {
    if (people.isEmpty) return null;
    return people
        .map(
          (person) => person.role != null
              ? '${person.name} (${person.role})'
              : person.name,
        )
        .join(', ');
  }

  Future<void> _openInBrowser(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open browser')));
    }
  }
}

class _HeroImage extends StatelessWidget {
  final List<String> imageUrls;

  const _HeroImage({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ArtImage(urls: imageUrls, borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textValue = (value == null || value!.trim().isEmpty)
        ? 'Not specified'
        : value!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Text(
              textValue,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  final String? text;

  const _DescriptionBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final description = (text == null || text!.trim().isEmpty)
        ? 'Описание отсутствует.'
        : text!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Описание', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
