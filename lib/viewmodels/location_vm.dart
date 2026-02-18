import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

final locationViewModelProvider =
    StateNotifierProvider<LocationViewModel, LocationState>((ref) {
  return LocationViewModel();
});

class LocationViewModel extends StateNotifier<LocationState> {
  LocationViewModel() : super(LocationState.initial());

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: '');

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location services are disabled. Please enable them.',
        );
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoading: false,
            error: 'Location permissions are denied.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location permissions are permanently denied. Please enable them in settings.',
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final addressParts = <String>[];
        
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          addressParts.add(placemark.postalCode!);
        }

        final locationText = addressParts.isNotEmpty
            ? addressParts.join(' - ')
            : 'Current Location';

        state = state.copyWith(
          isLoading: false,
          latitude: position.latitude,
          longitude: position.longitude,
          locationText: locationText,
          city: placemark.locality ?? '',
          postalCode: placemark.postalCode ?? '',
          error: '',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          latitude: position.latitude,
          longitude: position.longitude,
          locationText: 'Current Location',
          error: '',
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get location: ${e.toString()}',
      );
    }
  }

  void clearLocation() {
    state = LocationState.initial();
  }
}

class LocationState {
  final double? latitude;
  final double? longitude;
  final String locationText;
  final String city;
  final String postalCode;
  final bool isLoading;
  final String error;

  LocationState({
    this.latitude,
    this.longitude,
    required this.locationText,
    required this.city,
    required this.postalCode,
    required this.isLoading,
    required this.error,
  });

  factory LocationState.initial() => LocationState(
        latitude: null,
        longitude: null,
        locationText: '',
        city: '',
        postalCode: '',
        isLoading: false,
        error: '',
      );

  LocationState copyWith({
    double? latitude,
    double? longitude,
    String? locationText,
    String? city,
    String? postalCode,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationText: locationText ?? this.locationText,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

