import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sajha_app/features/business_location/business_location_service.dart';
import 'package:sajha_app/features/marketplace/widgets/marketplace_address_field.dart';

class FakeAddresses implements BusinessLocationService {
  const FakeAddresses();
  @override bool get isConfigured => true;
  @override Future<List<BusinessLocation>> autocomplete(String text) async => [
    const BusinessLocation(formattedAddress: '123 Main Street, Springfield',
      latitude: 39.8, longitude: -89.6, city: 'Springfield', state: 'Illinois'),
  ];
  @override Future<BusinessLocation?> reverse(double lat, double lon) async => null;
}
void main() {
  testWidgets('selection passes both address and coordinates', (tester) async {
    final controller = TextEditingController();
    BusinessLocation? selected;
    var cleared = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Material(
      child: MarketplaceAddressField(
        controller: controller, service: const FakeAddresses(),
        onSelected: (value) => selected = value,
        onChangedByUser: () => cleared++,
      ),
    ))));
    await tester.enterText(find.byType(TextFormField), 'Springfield');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('123 Main Street, Springfield'));
    await tester.pumpAndSettle();
    expect(controller.text, '123 Main Street, Springfield');
    expect(selected?.latitude, 39.8);
    expect(selected?.longitude, -89.6);
    expect(cleared, 1);
    controller.dispose();
  });
}
