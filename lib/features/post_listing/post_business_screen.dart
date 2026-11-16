import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'business_checkout_api.dart';
import 'business_payment_screen.dart';

const _navy = Color(0xFF14283F);
const _gold = Color(0xFFE7C477);
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
  const PostBusinessScreen({super.key});
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
  final _requestId = List.generate(24,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
  String? _category;
  XFile? _banner;
  Uint8List? _bytes;
  LatLng? _location;
  bool _online = false;
  bool _busy = false;
  bool _picking = false;
  bool _submitted = false;
  String? _draftId;
  String? _error;
  bool _published = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      _recoverImage();
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
        _banner = image;
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

  Future<void> _pickLocation() async {
    final location = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
            builder: (_) => _BusinessMapPicker(initial: _location)));
    if (mounted && location != null) setState(() => _location = location);
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
  String _normalizedWebsite() {
    final value = _website.text.trim();
    return value.isEmpty || value.contains('://') ? value : 'https://$value';
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    final valid = _form.currentState!.validate();
    if (!valid ||
        _banner == null ||
        (!_online && _location == null) ||
        _hours.any((h) => h.mode == 'open' && h.startMinutes == h.endMinutes)) {
      setState(() => _error =
          'Check the required fields, banner, map location and opening hours.');
      return;
    }
    // final api = BusinessCheckoutApi.instance;
    final api = BusinessCheckoutApi.instance ?? DummyBusinessCheckoutApi();
    // if (api == null) {
    //   setState(() => _error = 'Business payments are not available yet. Please try again later.');
    //   return;
    // }
    setState(() => _busy = true);
    try {
      if (_draftId == null) {
        final draft = await api.createDraft({
          'name': _name.text.trim(),
          'category': _category == 'Other' ? _custom.text.trim() : _category,
          'onlineOnly': _online,
          'address': _online ? '' : _address.text.trim(),
          'latitude': _online ? null : _location?.latitude,
          'longitude': _online ? null : _location?.longitude,
          'phone': _phone.text.trim(),
          'website': _normalizedWebsite(),
          'description': _about.text.trim(),
          'openingHours': {
            for (var i = 0; i < 7; i++) _days[i]: _hours[i].display
          },
          'openingHoursStructured': {
            for (var i = 0; i < 7; i++) _days[i]: _hours[i].toJson()
          },
        }, _banner!, _requestId);
        _draftId = draft['draftId'] as String;
      }
      if (!mounted) return;
      final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => BusinessPaymentScreen(
                  api: api,
                  draftId: _draftId!,
                  businessName: _name.text.trim())));
      if (!mounted) return;
      if (result == true) {
        _published = true;
        await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green, size: 48),
                    title: const Text('Your business is live!'),
                    content: const Text(
                        'Your Pro listing is now in the Business Directory.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Done'))
                    ]));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Could not save your listing. Check your connection and retry.');
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
    final locked = _busy || _draftId != null;
    return Theme(
      data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: _navy),
          scaffoldBackgroundColor: const Color(0xFFF3F5F8)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Business studio'), actions: const [
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
                              'Introduce your business to the Sajha community.\n'
                              'Build your profile, then choose how to pay.',
                              style: TextStyle(
                                  color: Color(0xFFD9E2EC), height: 1.6)),
                          SizedBox(height: 20),
                          Text('01  BUSINESS PROFILE     /     02  PAYMENT',
                              style: TextStyle(
                                  color: _gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ])),
                if (_draftId != null)
                  const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                          'Your profile is saved for checkout. Continue below to resume payment.')),
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
                                        color: _submitted && _banner == null
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
                              _field(
                                  _address, 'Street address / location label',
                                  required: true, maxLength: 250),
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
                    ])),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red))),
                FilledButton.icon(
                    onPressed:
                        _busy || _picking || _published ? null : _continue,
                    style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        padding: const EdgeInsets.all(20)),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_busy
                        ? 'Please wait…'
                        : _draftId == null
                            ? 'Continue to payment'
                            : 'Resume payment')),
                const SizedBox(height: 12),
                const Text(
                    'Pro is a paid listing. Review the price before paying.\n'
                    'Your business will not be published until payment is confirmed.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
              ])),
        ))),
      ),
    );
  }
}

class _BusinessMapPicker extends StatefulWidget {
  const _BusinessMapPicker({this.initial});
  final LatLng? initial;
  @override
  State<_BusinessMapPicker> createState() => _BusinessMapPickerState();
}

class _BusinessMapPickerState extends State<_BusinessMapPicker> {
  LatLng? _pin;
  @override
  void initState() {
    super.initState();
    _pin = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pin your business')),
        body: Column(children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Zoom to your business and tap the map. Drag the pin to fine-tune.')),
          Expanded(
              child: GoogleMap(
            initialCameraPosition: CameraPosition(
                target: _pin ?? const LatLng(39.5, -98.35),
                zoom: _pin == null ? 3 : 17),
            onTap: (point) => setState(() => _pin = point),
            markers: {
              if (_pin != null)
                Marker(
                    markerId: const MarkerId('business'),
                    position: _pin!,
                    draggable: true,
                    onDragEnd: (point) => setState(() => _pin = point))
            },
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          )),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: _pin == null
                              ? null
                              : () => Navigator.pop(context, _pin),
                          child: const Text('Use this location'))))),
        ]),
      );
}
