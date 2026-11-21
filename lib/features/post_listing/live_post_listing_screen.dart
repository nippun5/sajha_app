import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../marketplace/live/live_marketplace_api.dart';

/// Live, text-only MVP posting form until proper image storage is connected.
/// The existing rich image forms are NOT silently submitted without their photos.
class LivePostListingScreen extends StatefulWidget {
  const LivePostListingScreen({super.key, required this.kind});
  final String kind; // product, room, job
  @override
  State<LivePostListingScreen> createState() => _LivePostListingScreenState();
}

class _LivePostListingScreenState extends State<LivePostListingScreen> {
  final _key = GlobalKey<FormState>();
  final _api = LiveMarketplaceApi();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _suburb = TextEditingController();
  final _company = TextEditingController();
  String _condition = 'good';
  String _jobType = 'partTime';
  bool _submitting = false;
  String? _requestKey;

  @override
  void initState() {
    super.initState();
    _phone.text = AuthSession.instance.account?.phone ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _location,
      _phone,
      _category,
      _price,
      _suburb,
      _company
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? text) =>
      text == null || text.trim().isEmpty ? 'Required' : null;
  String? _amount(String? raw) {
    final value = double.tryParse(raw?.trim() ?? '');
    if (value == null || value <= 0 || value > 1000000000)
      return 'Enter a positive amount';
    return null;
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    if (!AuthSession.instance.canPost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sign in and verify your phone before publishing.'),
      ));
      return;
    }
    if (_submitting) return;
    final price = double.parse(_price.text.trim());
    final details = switch (widget.kind) {
      'product' => <String, dynamic>{
          'price': price,
          'category': _category.text.trim(),
          'condition': _condition,
          'isNegotiable': false,
        },
      'room' => <String, dynamic>{
          'weeklyRent': price,
          'suburb': _suburb.text.trim(),
          'bedrooms': 1,
          'bathrooms': 1,
        },
      'job' => <String, dynamic>{
          'company': _company.text.trim(),
          'jobType': _jobType,
          'salaryMin': price,
          'salaryCycle': 'hourly',
        },
      _ => <String, dynamic>{},
    };
    _requestKey ??= 'flutter-${DateTime.now().microsecondsSinceEpoch}';
    setState(() => _submitting = true);
    try {
      final created = await _api.create({
        'kind': widget.kind,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'contactPhone': _phone.text.trim(),
        'location': _location.text.trim(),
        'details': details,
        'mediaIds': <String>[],
      }, _requestKey!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Published ${created.title} to the live marketplace.'),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Post ${widget.kind} (Live)')),
        body: Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Live listing · Stored in MySQL. Photos are not uploaded in this step. '
                          'Use this form only for listings you intend to publish without images. '
                          'Image uploads will be added next.',
                        ))),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _title,
                    validator: _required,
                    maxLength: 120,
                    decoration: const InputDecoration(labelText: 'Title *')),
                TextFormField(
                    controller: _description,
                    validator: _required,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 5000,
                    decoration:
                        const InputDecoration(labelText: 'Description *')),
                TextFormField(
                    controller: _location,
                    validator: _required,
                    maxLength: 180,
                    decoration: const InputDecoration(labelText: 'Location *')),
                TextFormField(
                    controller: _phone,
                    validator: (text) => RegExp(r'^\+[1-9][0-9]{6,14}$')
                            .hasMatch(text?.trim() ?? '')
                        ? null
                        : 'Use your verified phone in +countrycode format',
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Verified contact phone *')),
                if (widget.kind == 'product') ...[
                  TextFormField(
                      controller: _category,
                      validator: _required,
                      decoration:
                          const InputDecoration(labelText: 'Category *')),
                  DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: const InputDecoration(labelText: 'Condition'),
                    items: const [
                      DropdownMenuItem(value: 'newItem', child: Text('New')),
                      DropdownMenuItem(
                          value: 'likeNew', child: Text('Like New')),
                      DropdownMenuItem(value: 'good', child: Text('Good')),
                      DropdownMenuItem(value: 'fair', child: Text('Fair')),
                      DropdownMenuItem(value: 'used', child: Text('Used')),
                    ],
                    onChanged: (value) =>
                        setState(() => _condition = value ?? 'good'),
                  ),
                ],
                if (widget.kind == 'room')
                  TextFormField(
                      controller: _suburb,
                      validator: _required,
                      decoration: const InputDecoration(labelText: 'Suburb *')),
                if (widget.kind == 'job') ...[
                  TextFormField(
                      controller: _company,
                      validator: _required,
                      decoration:
                          const InputDecoration(labelText: 'Company *')),
                  DropdownButtonFormField<String>(
                    value: _jobType,
                    decoration: const InputDecoration(labelText: 'Job type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'fullTime', child: Text('Full Time')),
                      DropdownMenuItem(
                          value: 'partTime', child: Text('Part Time')),
                      DropdownMenuItem(value: 'casual', child: Text('Casual')),
                      DropdownMenuItem(
                          value: 'contract', child: Text('Contract')),
                      DropdownMenuItem(
                          value: 'internship', child: Text('Internship')),
                    ],
                    onChanged: (value) =>
                        setState(() => _jobType = value ?? 'partTime'),
                  ),
                ],
                TextFormField(
                    controller: _price,
                    validator: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: switch (widget.kind) {
                      'product' => 'Asking price (USD) *',
                      'room' => 'Weekly rent (USD) *',
                      _ => 'Starting hourly pay (USD) *',
                    })),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                      _submitting ? 'Publishing...' : 'Publish live listing'),
                ),
                const SizedBox(height: 10),
                const Text(
                    'The contact number must already be verified by Spring Boot.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            )),
      );
}
