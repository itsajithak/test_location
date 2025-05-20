part of 'location_bloc.dart';

@immutable
sealed class LocationEvent {}

final class LatLongFetchEvent extends LocationEvent {
  final List<Map<String, dynamic>> locationList;

  LatLongFetchEvent(this.locationList);
}
