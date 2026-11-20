import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../business_location/business_address_field.dart';
import '../business_location/business_location_picker.dart';
import '../business_location/business_location_service.dart';
import '../profile/data/profile_demo_store.dart';
import '../business_requests/data/business_submission.dart';
import '../../core/theme/app_colors.dart';

const _navy = AppColors.primary;
const _gold = AppColors.coral;
const _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

class _Hours {
  String mode = 'open';
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);
  int get startMinutes => start.hour * 60 + start.minute;
  int get endMinutes => end.hour * 60 + end.minute;
  String _time(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String get display => mode == 'closed'
      ? 'Closed'
      : mode == 'allDay'
          ? 'Open 24 hours'
          : '${_time(start)} – ${_time(end)}${endMinutes < startMinutes ? ' (next day)' : ''}';
  Map<String, dynamic> toJson() => {
        'mode': mode,
        if (mode == 'open') ...{
          'opens': _time(start),
          'closes': _time(end),
          'closesNextDay': endMinutes < startMinutes,
        }
      };
}

class PostBusinessScreen extends StatefulWidget {
  const PostBusinessScreen({super.key, this.initialRequest});

  /// Passed only for correcting an existing Declined business request.
  final BusinessRequestPreview? initialRequest;
  @override
  State<PostBusinessScreen> createState() => _PostBusinessScreenState();
}

class _PostBusinessScreenState extends State<PostBusinessScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _custom = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _about = TextEditingController();
  final _hours = List.generate(7, (_) => _Hours());
  final _picker = ImagePicker();
  String? _category;
  Uint8List? _bytes;
  BusinessLocation? _location;
  bool _online = false;
  bool _busy = false;
  bool _picking = false;
  bool _submitted = false;
  bool _contactConsent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillDeclinedRequest();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _recoverImage();
    }
  }

  void _prefillDeclinedRequest() {
    final request = widget.initialRequest;
    if (request == null || request.status != BusinessRequestStatus.declined) {
      return;
    }
    final data = request.submission;
    if (data == null) return; // Legacy example without the full form.
    _name.text = data.name;
    const categories = [
      'Restaurant & cafe',
      'Grocery & retail',
      'Beauty & wellness',
      'Home services',
      'Professional services',
      'Education',
      'Travel & transport',
      'Technology',
    ];
    _category = categories.contains(data.category) ? data.category : 'Other';
    if (_category == 'Other') _custom.text = data.category;
    _address.text = data.address;
    _phone.text = data.phone;
    _website.text = data.website;
    _about.text = data.description;
    _online = data.onlineOnly;
    if (!data.onlineOnly && data.latitude != null && data.longitude != null) {
      _location = BusinessLocation(
        formattedAddress: data.address,
        latitude: data.latitude!,
        longitude: data.longitude!,
        placeId: data.placeId,
        city: data.city,
        state: data.state,
        countryCode: data.countryCode,
      );
    }
    if (data.bannerBytes.isNotEmpty) {
      _bytes = Uint8List.fromList(data.bannerBytes);
    }
    for (var i = 0; i < _days.length; i++) {
      final saved = data.openingHoursStructured[_days[i]];
      if (saved == null) continue;
      final mode = saved['mode'];
      if (mode == 'closed' || mode == 'allDay' || mode == 'open') {
        _hours[i].mode = mode as String;
      }
      _hours[i].start = _parseTime(saved['opens'], _hours[i].start);
      _hours[i].end = _parseTime(saved['closes'], _hours[i].end);
    }
  }

  TimeOfDay _parseTime(dynamic text, TimeOfDay fallback) {
    if (text is! String || !RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
      return fallback;
    }
    final pieces = text.split(':');
    final hour = int.tryParse(pieces[0]);
    final minute = int.tryParse(pieces[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return fallback;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _recoverImage() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.files?.isNotEmpty ?? false)
        await _setImage(response.files!.first);
    } catch (_) {
      if (mounted) setState(() => _error = 'Please select your banner again.');
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _custom,
      _address,
      _phone,
      _website,
      _about
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _setImage(XFile image) async {
    if (await image.length() > 10 * 1024 * 1024) {
      throw StateError('Choose a banner smaller than 10 MB.');
    }
    final bytes = await image.readAsBytes();
    if (mounted)
      setState(() {
        _bytes = bytes;
        _error = null;
      });
  }

  Future<void> _pickBanner() async {
    setState(() => _picking = true);
    try {
      final image = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 2400, imageQuality: 90);
      if (image != null) await _setImage(image);
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Could not load banner. Choose an image under 10 MB and allow photo access.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // Geoapify place search and map confirmation share the same location model.
  Future<void> _pickLocation() async {
    final picked = await Navigator.push<BusinessLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessLocationPicker(initial: _location),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _location = picked;
      _address.text = picked.formattedAddress;
    });
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
  String _normalizedWebsite() {
    final value = _website.text.trim();
    return value.isEmpty || value.contains('://') ? value : 'https://$value';
  }

  // Frontend preview only. This saves a full snapshot on THIS device.
  // It NEVER contacts an admin, verifies payment or publishes the business.
  Future<void> _continue() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    final valid = _form.currentState?.validate() ?? false;
    if (!valid ||
        _bytes == null ||
        (!_online && _location == null) ||
        _hours.any((h) => h.mode == 'open' && h.startMinutes == h.endMinutes)) {
      setState(() => _error =
          'Check all required fields, banner, location and opening hours.');
      return;
    }
    if (!_contactConsent) {
      setState(() => _error =
          'Please confirm the business contact and publication notice.');
      return;
    }
    final store = ProfileDemoStore.instance;
    if (!store.previewEnabled) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Frontend preview only'),
          content: const Text('Enable Profile demo mode to save a request '
              'locally. No real submissions are available before backend '
              'integration.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            )
          ],
        ),
      );
      return;
    }

    final snapshot = BusinessSubmission(
      name: _name.text.trim(),
      category: _category == 'Other' ? _custom.text.trim() : (_category ?? ''),
      phone: _phone.text.trim(),
      website: _normalizedWebsite(),
      description: _about.text.trim(),
      onlineOnly: _online,
      address: _online ? '' : _address.text.trim(),
      latitude: _online ? null : _location?.latitude,
      longitude: _online ? null : _location?.longitude,
      placeId: _online ? null : _location?.placeId,
      city: _online ? null : _location?.city,
      state: _online ? null : _location?.state,
      countryCode: _online ? null : _location?.countryCode,
      bannerBytes: _bytes!,
      openingHours: {
        for (var i = 0; i < _days.length; i++) _days[i]: _hours[i].display,
      },
      openingHoursStructured: {
        for (var i = 0; i < _days.length; i++) _days[i]: _hours[i].toJson(),
      },
    );
    final validationError = snapshot.validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    // Explicit review step: user sees what will be saved before submission.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.initialRequest == null
            ? 'Review business request'
            : 'Review corrected request'),
        content: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snapshot.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(snapshot.category),
                const SizedBox(height: 8),
                Text('Location: ${snapshot.locationLabel}'),
                Text('Contact: ${snapshot.phone}'),
                const SizedBox(height: 12),
                const Text('Submission will be Pending in your local demo '
                    'Profile. No admin is notified, no payment is processed '
                    'and nothing appears in the public directory.'),
              ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Go back')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save Pending preview')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _busy = true);
    try {
      final initial = widget.initialRequest;
      final request = initial == null
          ? store.submitBusinessRequest(snapshot)
          : store.resubmitDeclinedBusinessRequest(initial.id, snapshot);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.pending_actions, color: AppColors.primary),
          title: const Text('Saved as Pending (demo)'),
          content: Text('Request ${request.id} is in Profile → '
              'My Business Requests. This record exists only on this device '
              'until the app restarts or demo mode is turned off. '
              'It has NOT been sent to an admin.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            )
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save request: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String number, String title, String subtitle,
          List<Widget> children) =>
      Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE4E8EE))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$number  /  ${title.toUpperCase()}',
                style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: _navy)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Color(0xFF56657A))),
            const SizedBox(height: 22),
            ...children,
          ]));

  Widget _field(TextEditingController controller, String label,
          {bool required = false,
          int lines = 1,
          int? maxLength,
          TextInputType? keyboard,
          String? Function(String?)? validator}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: controller,
            minLines: lines,
            maxLines: lines,
            maxLength: maxLength,
            keyboardType: keyboard,
            validator: validator ?? (required ? _required : null),
            decoration: InputDecoration(
                labelText: '$label${required ? ' *' : ''}',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12))),
          ));

  Widget _hoursRow(int index) {
    final h = _hours[index];
    Future<void> pick(bool opening) async {
      final value = await showTimePicker(
          context: context, initialTime: opening ? h.start : h.end);
      if (mounted && value != null)
        setState(() {
          if (opening) {
            h.start = value;
          } else {
            h.end = value;
          }
        });
    }

    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(_days[index],
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            DropdownButton<String>(
                value: h.mode,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  DropdownMenuItem(value: 'allDay', child: Text('24 hours')),
                ],
                onChanged: (value) => setState(() => h.mode = value!))
          ]),
          if (h.mode == 'open') ...[
            Wrap(spacing: 12, runSpacing: 8, children: [
              OutlinedButton(
                  onPressed: () => pick(true),
                  child: Text('Opens  ${h.start.format(context)}')),
              OutlinedButton(
                  onPressed: () => pick(false),
                  child: Text('Closes  ${h.end.format(context)}')),
            ]),
            if (h.endMinutes < h.startMinutes)
              const Text('Closes the next day',
                  style: TextStyle(color: Color(0xFF56657A))),
            if (_submitted && h.endMinutes == h.startMinutes)
              const Text('Choose different times or select 24 hours.',
                  style: TextStyle(color: Colors.red)),
          ],
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final locked = _busy;
    return Theme(
      data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: _navy),
          scaffoldBackgroundColor: const Color(0xFFF3F5F8)),
      child: Scaffold(
        appBar: AppBar(
            title: Text(widget.initialRequest == null
                ? 'Post Business'
                : 'Correct Business Request'),
            actions: const [
              Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Chip(
                      backgroundColor: _gold,
                      label: Text('PRO',
                          style: TextStyle(fontWeight: FontWeight.w800))))
            ]),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Container(
                    padding: const EdgeInsets.all(28),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_navy, Color(0xFF294966)]),
                        borderRadius: BorderRadius.circular(24)),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, color: _gold, size: 30),
                          SizedBox(height: 22),
                          Text('Small business.\nBig possibilities.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15)),
                          SizedBox(height: 14),
                          Text(
                              'Introduce your business to the SaJHa community.\n'
                              'Our team will review your request.',
                              style: TextStyle(
                                  color: Color(0xFFD9E2EC), height: 1.6)),
                          SizedBox(height: 20),
                          Text('01  BUSINESS PROFILE     /     02  REVIEW',
                              style: TextStyle(
                                  color: _gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ])),
                AbsorbPointer(
                    absorbing: locked,
                    child: Column(children: [
                      _section('01', 'First impressions',
                          'Give your business a memorable introduction.', [
                        InkWell(
                            onTap: _picking ? null : _pickBanner,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                                height: 185,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF0F3F7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: _submitted && _bytes == null
                                            ? Colors.red
                                            : const Color(0xFFCBD4DF))),
                                clipBehavior: Clip.antiAlias,
                                child: _bytes == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                            const Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 38,
                                                color: _navy),
                                            const SizedBox(height: 10),
                                            Text(_picking
                                                ? 'Loading banner…'
                                                : 'Upload your banner *'),
                                            const Text(
                                                'Wide image recommended · Up to 10 MB'),
                                          ])
                                    : Image.memory(_bytes!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(
                                            child: Text(
                                                'Image unavailable. Tap to replace.'))))),
                        if (_bytes != null)
                          TextButton.icon(
                              onPressed: _picking ? null : _pickBanner,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Replace banner')),
                        const SizedBox(height: 22),
                        _field(_name, 'Business name',
                            required: true, maxLength: 100),
                        DropdownButtonFormField<String>(
                            value: _category,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Category *',
                                border: OutlineInputBorder()),
                            items: const [
                              'Restaurant & cafe',
                              'Grocery & retail',
                              'Beauty & wellness',
                              'Home services',
                              'Professional services',
                              'Education',
                              'Travel & transport',
                              'Technology',
                              'Other'
                            ]
                                .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c == 'Other'
                                        ? 'Other — enter your own'
                                        : c)))
                                .toList(),
                            validator: _required,
                            onChanged: (value) =>
                                setState(() => _category = value)),
                        if (_category == 'Other') ...[
                          const SizedBox(height: 16),
                          _field(_custom, 'Custom category',
                              required: true, maxLength: 60)
                        ],
                      ]),
                      _section(
                          '02',
                          'Where to find you',
                          'Pin your storefront or offer your services online.',
                          [
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Online-only business'),
                                subtitle:
                                    const Text('No physical location required'),
                                value: _online,
                                onChanged: (value) =>
                                    setState(() => _online = value)),
                            if (!_online) ...[
                              BusinessAddressField(
                                controller: _address,
                                onSelected: (place) => setState(() {
                                  _location = place;
                                }),
                                onChangedByUser: () => setState(() {
                                  // Never keep a pin from an earlier address.
                                  _location = null;
                                }),
                              ),
                              OutlinedButton.icon(
                                  onPressed: _pickLocation,
                                  icon: const Icon(Icons.map_outlined),
                                  label: Text(_location == null
                                      ? 'Choose precise location *'
                                      : 'Adjust map pin')),
                              if (_location != null)
                                Text(
                                    '${_location!.latitude.toStringAsFixed(6)}, ${_location!.longitude.toStringAsFixed(6)}'),
                              if (_submitted && _location == null)
                                const Text('Please choose a map pin.',
                                    style: TextStyle(color: Colors.red)),
                            ],
                          ]),
                      _section('03', 'Make connections',
                          'Help customers get in touch and learn your story.', [
                        _field(_phone, 'Contact number',
                            required: true,
                            keyboard: TextInputType.phone, validator: (value) {
                          if (_required(value) != null)
                            return 'Enter a contact number.';
                          final cleaned =
                              value!.replaceAll(RegExp(r'[\s().-]'), '');
                          return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned)
                              ? null
                              : 'Enter 7–15 digits, with an optional country code.';
                        }),
                        _field(_website, 'Website (optional)',
                            keyboard: TextInputType.url, validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return null;
                          final uri = Uri.tryParse(_normalizedWebsite());
                          return uri != null &&
                                  ['http', 'https'].contains(uri.scheme) &&
                                  uri.host.contains('.') &&
                                  uri.userInfo.isEmpty &&
                                  !uri.toString().contains(' ')
                              ? null
                              : 'Enter a valid website address.';
                        }),
                        _field(_about, 'About your business',
                            required: true, lines: 5, maxLength: 3000),
                      ]),
                      _section('04', 'Opening hours',
                          'Set each day in the business’s local time.', [
                        TextButton.icon(
                            onPressed: () => setState(() {
                                  for (final h in _hours.skip(1)) {
                                    h.mode = _hours.first.mode;
                                    h.start = _hours.first.start;
                                    h.end = _hours.first.end;
                                  }
                                }),
                            icon: const Icon(Icons.copy_all_outlined),
                            label: const Text('Apply Monday to every day')),
                        for (var i = 0; i < 7; i++) _hoursRow(i),
                      ]),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _contactConsent,
                        onChanged: (value) =>
                            setState(() => _contactConsent = value ?? false),
                        title: const Text('I confirm these business details '
                            'are accurate and may be reviewed by SaJHa.'),
                        subtitle: const Text('The submitted contact number '
                            'may be used by an administrator to contact me. '
                            'Once approved, business contact details will '
                            'be public in the directory.'),
                      ),
                    ])),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red))),
                FilledButton.icon(
                    onPressed:
                        kDebugMode && !_busy && !_picking ? _continue : null,
                    style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        padding: const EdgeInsets.all(20)),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_busy
                        ? 'Saving…'
                        : kDebugMode
                            ? 'Submit business request (preview)'
                            : 'Submission unavailable')),
                const SizedBox(height: 12),
                const Text(
                    'Submitting this form creates a local Pending preview only.\n'
                    'No payment or publication happens in the app.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
              ])),
        ))),
      ),
    );
  }
}
