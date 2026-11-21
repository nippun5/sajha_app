import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../business_location/business_location_service.dart';

/// Reuses the same Geoapify provider as Post Business. Selecting a suggestion
/// returns a formatted address AND coordinates; manually editing clears the pin.
class MarketplaceAddressField extends StatefulWidget {
  const MarketplaceAddressField({
    super.key,
    required this.controller,
    required this.onSelected,
    required this.onChangedByUser,
    this.label = 'Location *',
    this.hint = 'Start typing a city, street or suburb',
    this.requiredSelection = true,
    this.enabled = true,
    this.service = const GeoapifyBusinessLocationService(),
  });
  final TextEditingController controller;
  final ValueChanged<BusinessLocation> onSelected;
  final VoidCallback onChangedByUser;
  final String label;
  final String hint;
  final bool requiredSelection;
  final bool enabled;
  final BusinessLocationService service;

  @override
  State<MarketplaceAddressField> createState() => _MarketplaceAddressFieldState();
}

class _MarketplaceAddressFieldState extends State<MarketplaceAddressField> {
  Timer? _timer;
  int _seq = 0;
  List<BusinessLocation> _matches = const [];
  bool _loading = false;
  String? _error;
  BusinessLocation? _selected;

  void _typed(String query) {
    widget.onChangedByUser();
    _selected = null;
    _timer?.cancel();
    final request = ++_seq;
    setState(() { _matches = const []; _error = null; _loading = false; });
    if (query.trim().length < 3 || !widget.service.isConfigured) return;
    _timer = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted || _seq != request) return;
      setState(() => _loading = true);
      try {
        final values = await widget.service.autocomplete(query.trim());
        if (!mounted || _seq != request) return;
        setState(() { _matches = values; _loading = false; });
      } catch (_) {
        if (!mounted || _seq != request) return;
        setState(() {
          _matches = const [];
          _loading = false;
          _error = 'Address lookup unavailable. Try again.';
        });
      }
    });
  }

  void _choose(BusinessLocation location) {
    if (location.formattedAddress.length > 180) {
      setState(() => _error = 'Choose a shorter location (max 180 characters).');
      return;
    }
    _timer?.cancel();
    _seq++;
    _selected = location;
    widget.controller.text = location.formattedAddress;
    widget.onSelected(location);
    FocusScope.of(context).unfocus();
    setState(() { _matches = const []; _error = null; _loading = false; });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        onChanged: _typed,
        maxLength: 180,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: _loading
              ? const Padding(padding: EdgeInsets.all(14), child:
                  SizedBox(height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)))
              : (_selected == null ? null : const Icon(Icons.check_circle_outline,
                  color: AppColors.primary)),
          border: const OutlineInputBorder(),
        ),
        validator: (raw) {
          if (!widget.requiredSelection) return null;
          if ((raw ?? '').trim().isEmpty) return 'Location is required';
          if (_selected == null || raw!.trim() != _selected!.formattedAddress) {
            return 'Choose a location from the suggestions';
          }
          return null;
        },
      ),
      if (!widget.service.isConfigured)
        const Padding(padding: EdgeInsets.only(bottom: 8),
          child: Text('Set GEOAPIFY_API_KEY to enable address suggestions.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
      if (_error != null)
        Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Text(_error!, style: const TextStyle(color: AppColors.error))),
      if (_matches.isNotEmpty)
        Container(
          constraints: const BoxConstraints(maxHeight: 230),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined, color: AppColors.coral),
              title: Text(_matches[index].formattedAddress,
                maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => _choose(_matches[index]),
            ),
          ),
        ),
      const Padding(padding: EdgeInsets.only(top: 3, bottom: 10),
        child: Text('Address data © OpenStreetMap contributors · Powered by Geoapify',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
    ],
  );
}
