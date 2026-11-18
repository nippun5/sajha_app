import 'package:flutter_test/flutter_test.dart';
import 'package:sajha_app/features/business_location/business_location_service.dart';
import 'package:sajha_app/models/business_model.dart';

void main() {
  test('Geoapify address maps to one location with its coordinates', () {
    final location = BusinessLocation.fromGeoapify({
      'formatted': '123 Main Street, Dallas, TX, USA',
      'lat': 32.783,
      'lon': -96.804,
      'place_id': 'test-place-id',
      'city': 'Dallas',
      'state': 'Texas',
      'country_code': 'us',
    });
    expect(location, isNotNull);
    expect(location!.latitude, 32.783);
    expect(location.longitude, -96.804);
    expect(location.formattedAddress, contains('Dallas'));
    expect(location.placeId, 'test-place-id');
  });

  test('Missing or invalid coordinates cannot be selected', () {
    expect(BusinessLocation.fromGeoapify({
      'formatted': 'Missing coordinates'
    }), isNull);
    expect(BusinessLocation.fromGeoapify({
      'formatted': 'Invalid', 'lat': 95, 'lon': 0,
    }), isNull);
    expect(BusinessLocation.fromGeoapify({
      'formatted': '', 'lat': 32, 'lon': -96,
    }), isNull);
  });

  test('Existing BusinessModel constructors still work unchanged', () {
    final business = BusinessModel(
      id: 'demo', name: 'Demo', imageUrl: '', description: '',
      address: 'Demo', phone: '', website: '', category: 'Other',
      rating: 0, reviewCount: 0, openingHours: {},
    );
    expect(business.hasCoordinates, isFalse);
    expect(business.onlineOnly, isFalse);
  });

  test('BusinessModel with a real pinned location supports map actions', () {
    final business = BusinessModel(
      id: 'demo2', name: 'Demo', imageUrl: '', description: '',
      address: 'Dallas, TX', phone: '', website: '', category: 'Other',
      rating: 0, reviewCount: 0, openingHours: {},
      latitude: 32.78, longitude: -96.8, city: 'Dallas',
    );
    expect(business.hasCoordinates, isTrue);
  });
}
