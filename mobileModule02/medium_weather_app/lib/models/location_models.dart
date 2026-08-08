class LocationCoordinates {
  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  String get displayLabel =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationResult {
  const LocationResult._({
    this.coordinates,
    this.failure,
  });

  const LocationResult.success(LocationCoordinates coordinates)
      : this._(coordinates: coordinates);

  const LocationResult.failure(LocationFailure failure)
      : this._(failure: failure);

  final LocationCoordinates? coordinates;
  final LocationFailure? failure;

  bool get isSuccess => coordinates != null;
}
