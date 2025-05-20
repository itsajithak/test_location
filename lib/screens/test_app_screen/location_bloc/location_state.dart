part of 'location_bloc.dart';

@immutable
sealed class LocationState {}

final class LocationInitial extends LocationState {}

final class FetchLocationState extends LocationState {
  final List<Map<String, dynamic>> locationList;

  FetchLocationState(this.locationList);
}
