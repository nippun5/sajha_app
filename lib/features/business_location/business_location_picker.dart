import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import 'business_address_field.dart';
import 'business_location_service.dart';

/// A full-screen location confirmation page. The center pin stays fixed while
/// the map is dragged, which is more reliable than a draggable marker on mobile.
class BusinessLocationPicker extends StatefulWidget {
  const BusinessLocationPicker({
    super.key,
    this.initial,
    this.service = const GeoapifyBusinessLocationService(),
  });

  final BusinessLocation? initial;
  final BusinessLocationService service;

  @override
  State<BusinessLocationPicker> createState() => _BusinessLocationPickerState();
}

class _BusinessLocationPickerState extends State<BusinessLocationPicker> {
  final MapController _map = MapController();
  final TextEditingController _address = TextEditingController();
  late LatLng _point;
  BusinessLocation? _confirmedSearchResult;
  bool _mapReady = false;
  bool _picked = false;
  bool _moved = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _point = LatLng(initial?.latitude ?? -33.8688,
        initial?.longitude ?? 151.2093); // Initial view only, not a selection.
    _picked = initial != null;
    _confirmedSearchResult = initial;
    _address.text = initial?.formattedAddress ?? '';
  }

  @override
  void dispose() {
    _address.dispose();
    _map.dispose();
    super.dispose();
  }

  void _selectedSearchResult(BusinessLocation location) {
    final point = LatLng(location.latitude, location.longitude);
    setState(() {
      _point = point;
      _confirmedSearchResult = location;
      _moved = false;
      _picked = true;
    });
    if (_mapReady) _map.move(point, 17);
  }

  Future<String?> _askToConfirmAddress(String suggested) async {
    final input = TextEditingController(text: suggested);
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm storefront address'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('You adjusted the map pin. Check the address below '
                'before using this exact location.'),
            const SizedBox(height: 12),
            TextField(
                controller: input,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Address or landmark',
                    border: OutlineInputBorder())),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  final value = input.text.trim();
                  if (value.isNotEmpty) Navigator.pop(dialogContext, value);
                },
                child: const Text('Use this location')),
          ],
        ),
      );
    } finally {
      input.dispose();
    }
  }

  Future<void> _confirm() async {
    if (!_picked || _saving) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Search an address or move the map to choose a pin.')));
      return;
    }
    if (!_moved && _confirmedSearchResult != null) {
      Navigator.pop(context, _confirmedSearchResult);
      return;
    }
    setState(() => _saving = true);
    BusinessLocation? nearby;
    try {
      nearby = await widget.service.reverse(_point.latitude, _point.longitude);
    } catch (_) {
      // Manual address confirmation is still available if reverse search fails.
    }
    if (!mounted) return;
    setState(() => _saving = false);
    final address = await _askToConfirmAddress(nearby?.formattedAddress ?? '');
    if (!mounted || address == null) return;
    Navigator.pop(
        context,
        BusinessLocation(
          formattedAddress: address,
          latitude: _point.latitude,
          longitude: _point.longitude,
          city: nearby?.city,
          state: nearby?.state,
          countryCode: nearby?.countryCode,
          // No placeId: the owner moved the exact pin away from the matched place.
        ));
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final apiKey =
        service is GeoapifyBusinessLocationService ? service.apiKey : '';
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Choose business location')),
      body: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BusinessAddressField(
              controller: _address,
              service: service,
              onChangedByUser: () {
                setState(() {
                  _confirmedSearchResult = null;
                  _picked = false;
                });
              },
              onSelected: _selectedSearchResult,
            )),
        Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: !service.isConfigured
                      ? const Center(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                  'A free Geoapify API key is needed to load live map tiles.')))
                      : Stack(children: [
                          FlutterMap(
                            mapController: _map,
                            options: MapOptions(
                              initialCenter: _point,
                              initialZoom: widget.initial == null ? 10 : 16,
                              minZoom: 2,
                              maxZoom: 19,
                              onMapReady: () {
                                _mapReady = true;
                                if (_picked) _map.move(_point, 17);
                              },
                              onPositionChanged: (camera, hasGesture) {
                                if (!hasGesture) return;
                                // No reverse lookup on every camera movement (avoids
                                // unnecessary paid/free-tier API requests).
                                setState(() {
                                  _point = camera.center;
                                  _picked = true;
                                  _moved = true;
                                  _confirmedSearchResult = null;
                                });
                              },
                              onTap: (_, point) {
                                _map.move(point, _map.camera.zoom);
                                setState(() {
                                  _point = point;
                                  _picked = true;
                                  _moved = true;
                                  _confirmedSearchResult = null;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://maps.geoapify.com/v1/tile/osm-bright/'
                                    '{z}/{x}/{y}.png?apiKey=$apiKey',
                                maxZoom: 19,
                              ),
                            ],
                          ),
                          const Center(
                              child: IgnorePointer(
                                  child: Padding(
                                      padding: EdgeInsets.only(bottom: 34),
                                      child: Icon(Icons.location_pin,
                                          size: 48, color: AppColors.coral)))),
                          Positioned(
                              left: 8,
                              bottom: 8,
                              right: 8,
                              child: Container(
                                  color: Colors.white.withOpacity(0.9),
                                  padding: const EdgeInsets.all(4),
                                  child: const Text(
                                      'Powered by Geoapify | © OpenStreetMap contributors | © OpenMapTiles',
                                      style: TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center))),
                        ]))),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(children: [
              Text(
                  _picked
                      ? 'Pin: ${_point.latitude.toStringAsFixed(6)}, '
                          '${_point.longitude.toStringAsFixed(6)}'
                      : 'Search or move the map to choose a location',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _confirm,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_saving
                        ? 'Looking up address…'
                        : 'Confirm this location'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48)),
                  )),
            ])),
      ])),
    );
  }
}
