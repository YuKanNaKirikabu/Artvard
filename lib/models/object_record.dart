class Person {
  final String name;
  final String? role;

  const Person({required this.name, this.role});

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      name: _stringOrNull(json['name']) ?? '',
      role: _stringOrNull(json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'role': role};
  }
}

class ObjectRecord {
  final int id;
  final String title;
  final String? dated;
  final String? primaryImageUrl;
  final String? baseImageUrl;
  final List<Person> people;
  final String? culture;
  final String? medium;
  final String? place;
  final String? classification;
  final String? description;
  final String? labelText;
  final String? creditLine;
  final List<String> imageUrls;
  final String? url;

  const ObjectRecord({
    required this.id,
    required this.title,
    this.dated,
    this.primaryImageUrl,
    this.baseImageUrl,
    this.people = const [],
    this.culture,
    this.medium,
    this.place,
    this.classification,
    this.description,
    this.labelText,
    this.creditLine,
    this.imageUrls = const [],
    this.url,
  });

  factory ObjectRecord.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final peopleJson = json['people'];
    final imageData = _imageDataFromJson(json['images']);
    final imageUrls = _collectImageUrls(json);
    final people = peopleJson is List
        ? peopleJson
              .whereType<Map<String, dynamic>>()
              .map(Person.fromJson)
              .where((person) => person.name.isNotEmpty)
              .toList()
        : <Person>[];

    final primaryImageUrl =
        _stringOrNull(json['primaryimageurl']) ?? imageData.primary;
    final baseImageUrl = _stringOrNull(json['baseimageurl']) ?? imageData.base;

    return ObjectRecord(
      id: idValue is int
          ? idValue
          : int.tryParse(idValue?.toString() ?? '') ?? 0,
      title: _stringOrNull(json['title']) ?? '',
      dated: _stringOrNull(json['dated']),
      primaryImageUrl: primaryImageUrl,
      baseImageUrl: baseImageUrl,
      people: people,
      culture: _stringOrNull(json['culture']),
      medium: _stringOrNull(json['medium']),
      place: _placeFromJson(json['place'], json['places']),
      classification: _stringOrNull(json['classification']),
      description: _stringOrNull(json['description']),
      labelText: _stringOrNull(json['labeltext']),
      creditLine: _stringOrNull(json['creditline']),
      imageUrls: imageUrls,
      url: _stringOrNull(json['url']),
    );
  }

  factory ObjectRecord.fromStorage(Map<String, dynamic> json) {
    final peopleJson = json['people'];
    final people = peopleJson is List
        ? peopleJson
              .whereType<Map<String, dynamic>>()
              .map(Person.fromJson)
              .where((person) => person.name.isNotEmpty)
              .toList()
        : <Person>[];

    return ObjectRecord(
      id: _intFromJson(json['id']) ?? 0,
      title: _stringOrNull(json['title']) ?? '',
      dated: _stringOrNull(json['dated']),
      primaryImageUrl: _stringOrNull(json['primaryimageurl']),
      baseImageUrl: _stringOrNull(json['baseimageurl']),
      people: people,
      culture: _stringOrNull(json['culture']),
      medium: _stringOrNull(json['medium']),
      place: _stringOrNull(json['place']),
      classification: _stringOrNull(json['classification']),
      description: _stringOrNull(json['description']),
      labelText: _stringOrNull(json['labeltext']),
      creditLine: _stringOrNull(json['creditline']),
      imageUrls: _listStringFromJson(json['imageUrls']),
      url: _stringOrNull(json['url']),
    );
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'title': title,
      'dated': dated,
      'primaryimageurl': primaryImageUrl,
      'baseimageurl': baseImageUrl,
      'people': people.map((person) => person.toJson()).toList(),
      'culture': culture,
      'medium': medium,
      'place': place,
      'classification': classification,
      'description': description,
      'labeltext': labelText,
      'creditline': creditLine,
      'imageUrls': imageUrls,
      'url': url,
    };
  }

  String get displayTitle => title.isNotEmpty ? title : 'Untitled';

  String? get previewImageUrl {
    final candidates = imageCandidates(targetSize: 320);
    return candidates.isEmpty ? null : candidates.first;
  }

  String? get detailImageUrl {
    final candidates = imageCandidates(targetSize: 1200);
    return candidates.isEmpty ? null : candidates.first;
  }

  String? get descriptionText =>
      _firstNonEmpty(description, labelText) ?? _stringOrNull(creditLine);

  List<String> imageCandidates({int targetSize = 800}) {
    final candidates = <String>[];

    void addCandidate(String? url) {
      final value = _normalizeUrl(url);
      if (value == null || candidates.contains(value)) return;
      candidates.add(value);
    }

    for (final url in imageUrls) {
      addCandidate(url);
    }

    final base = _normalizeUrl(baseImageUrl);
    final primary = _normalizeUrl(primaryImageUrl);

    if (base != null && _looksLikeIiifBase(base)) {
      addCandidate(_buildIiifUrl(base, targetSize));
    }

    addCandidate(primary);

    if (base != null && !_looksLikeIiifBase(base)) {
      addCandidate(base);
    }

    return candidates;
  }
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

List<String> _listStringFromJson(dynamic value) {
  if (value is List) {
    return value
        .map((entry) => entry?.toString() ?? '')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
  return const [];
}

String? _placeFromJson(dynamic placeValue, dynamic placesValue) {
  final place = _placeNameFromValue(placeValue);
  if (place != null) return place;

  if (placesValue is List) {
    for (final entry in placesValue) {
      final name = _placeNameFromValue(entry);
      if (name != null) return name;
    }
  }

  return null;
}

String? _placeNameFromValue(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) {
    return _stringOrNull(value['name']);
  }
  return _stringOrNull(value);
}

String? _firstNonEmpty(String? first, String? second) {
  final firstValue = _stringOrNull(first);
  if (firstValue != null) return firstValue;
  return _stringOrNull(second);
}

List<String> _collectImageUrls(Map<String, dynamic> json) {
  final candidates = <String>[];

  void addCandidate(String? url) {
    final value = _normalizeUrl(url);
    if (value == null || candidates.contains(value)) return;
    candidates.add(value);
  }

  addCandidate(json['primaryimageurl']);
  addCandidate(json['baseimageurl']);

  final images = json['images'];
  if (images is List) {
    for (final entry in images) {
      if (entry is Map<String, dynamic>) {
        addCandidate(entry['primaryimageurl']);
        addCandidate(entry['imageurl']);
        addCandidate(entry['baseimageurl']);
        addCandidate(entry['iiifbaseuri']);
      }
    }
  }

  return candidates;
}

class _ImageData {
  final String? primary;
  final String? base;

  const _ImageData({this.primary, this.base});
}

_ImageData _imageDataFromJson(dynamic imagesJson) {
  if (imagesJson is List) {
    for (final entry in imagesJson) {
      if (entry is Map<String, dynamic>) {
        final base =
            _stringOrNull(entry['baseimageurl']) ??
            _stringOrNull(entry['iiifbaseuri']);
        final primary =
            _stringOrNull(entry['primaryimageurl']) ??
            _stringOrNull(entry['imageurl']);

        if (base != null || primary != null) {
          return _ImageData(primary: primary, base: base);
        }
      }
    }
  }

  return const _ImageData();
}

String? _normalizeUrl(String? url) {
  final value = _stringOrNull(url);
  if (value == null) return null;
  if (value.startsWith('http://')) {
    return value.replaceFirst('http://', 'https://');
  }
  return value;
}

bool _looksLikeIiifBase(String url) {
  return url.contains('/iiif/') &&
      !url.contains('/full/') &&
      !url.endsWith('.jpg') &&
      !url.endsWith('.jpeg') &&
      !url.endsWith('.png') &&
      !url.endsWith('.webp');
}

String _buildIiifUrl(String base, int targetSize) {
  return '$base/full/!$targetSize,$targetSize/0/default.jpg';
}
