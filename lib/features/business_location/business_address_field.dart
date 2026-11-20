import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'business_location_service.dart';

/// Embeddable inside Post Business. Parent retains its existing address
/// controller; selecting a suggestion updates BOTH address and coordinates.
class BusinessAddressField extends StatefulWidget {
  const BusinessAddressField({
    super.key,
    required this.controller,
    required this.onSelected,
    required this.onChangedByUser,
    this.enabled = true,
    this.service = const GeoapifyBusinessLocationService(),
  });

  final TextEditingController controller;
  final ValueChanged<BusinessLocation> onSelected;
  final VoidCallback onChangedByUser;
  final bool enabled;
  final BusinessLocationService service;

  @override
  State<BusinessAddressField> createState() => _BusinessAddressFieldState();
}

class _BusinessAddressFieldState extends State<BusinessAddressField> {
  Timer? _debounce;
  int _requestNumber = 0;
  List<BusinessLocation> _suggestions = const [];
  bool _loading = false;
  String? _error;

  void _inputChanged(String query) {
    // This callback runs only for actual TextFormField edits, not for
    // programmatic changes to the shared controller after selecting a result.
    widget.onChangedByUser();
    _debounce?.cancel();
    final request = ++_requestNumber;
    setState(() {
      _suggestions = const [];
      _error = null;
      _loading = false;
    });
    if (query.trim().length < 3 || !widget.service.isConfigured) return;
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted || request != _requestNumber) return;
      setState(() => _loading = true);
      try {
        final places = await widget.service.autocomplete(query);
        if (!mounted || request != _requestNumber) return;
        setState(() {
          _suggestions = places;
          _loading = false;
        });
      } catch (e) {
        if (!mounted || request != _requestNumber) return;
        setState(() {
          _error = e.toString().replaceFirst('Bad state: ', '');
          _loading = false;
        });
      }
    });
  }

  void _choose(BusinessLocation location) {
    _debounce?.cancel();
    _requestNumber++;
    widget.controller.text = location.formattedAddress;
    widget.onSelected(location);
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = const [];
      _loading = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        onChanged: _inputChanged,
        maxLength: 250,
        decoration: InputDecoration(
          labelText: 'Search business address *',
          hintText: 'Enter a street, business or suburb',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : null,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            (value ?? '').trim().isEmpty ? 'Choose or enter an address' : null,
      ),
      if (!widget.service.isConfigured)
        const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
                'Add your free GEOAPIFY_API_KEY to enable live suggestions.',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      if (_error != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                Text(_error!, style: const TextStyle(color: AppColors.error))),
      if (_suggestions.isNotEmpty)
        Container(
          constraints: const BoxConstraints(maxHeight: 252),
          decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.location_on_outlined,
                    color: AppColors.coral),
                title: Text(suggestion.formattedAddress,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => _choose(suggestion),
              );
            },
          ),
        ),
      const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
              'Address data © OpenStreetMap contributors · Powered by Geoapify',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
    ]);
  }
}
