class Place {
  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.region = '',
    this.country = '',
  });

  final String name;
  final String region;
  final String country;
  final double latitude;
  final double longitude;

  String get displayLabel {
    final lines = <String>[name];
    if (region.isNotEmpty) {
      lines.add(region);
    }
    if (country.isNotEmpty) {
      lines.add(country);
    }
    return lines.join('\n');
  }

  String get suggestionSubtitle {
    final parts = <String>[];
    if (region.isNotEmpty) {
      parts.add(region);
    }
    if (country.isNotEmpty) {
      parts.add(country);
    }
    return parts.join(', ');
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'] as String? ?? '',
      region: json['admin1'] as String? ?? '',
      country: json['country'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
