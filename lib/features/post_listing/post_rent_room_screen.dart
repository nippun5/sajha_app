import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PostRentRoomScreen extends StatefulWidget {
  const PostRentRoomScreen({super.key});

  @override
  State<PostRentRoomScreen> createState() => _PostRentRoomScreenState();
}

class _PostRentRoomScreenState extends State<PostRentRoomScreen> {
  int currentStep = 0;

  final _step0FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  // Step 0 – Room Info
  final _titleController = TextEditingController();
  final _weeklyRentController = TextEditingController();
  final _suburbController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  String? selectedPreferredGender;
  bool isFurnished = false;
  bool billsIncluded = false;
  DateTime? availableFrom;

  // Step 1 – Photos
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];

  // Step 2 – Description & Contact
  final _descriptionController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _amenitiesController = TextEditingController();

  // ─────────────────────────────────────────────────────────────────────────────

  final List<String> genderPreferences = [
    'Any',
    'Male',
    'Female',
    'Non-binary',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _weeklyRentController.dispose();
    _suburbController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _descriptionController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  String? _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        if (!(_step0FormKey.currentState?.validate() ?? false)) {
          return 'Please fill in all required fields.';
        }
        if (selectedPreferredGender == null) {
          return 'Please select a preferred gender.';
        }
        if (availableFrom == null) {
          return 'Please select an available from date.';
        }
        return null;
      case 1:
        if (_images.isEmpty) return 'Please add at least one photo.';
        return null;
      case 2:
        if (!(_step2FormKey.currentState?.validate() ?? false)) {
          return 'Please fill in all required fields.';
        }
        return null;
      default:
        return null;
    }
  }

  void _onStepContinue() {
    final error = _validateCurrentStep();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (currentStep < 2) {
      setState(() => currentStep++);
    } else {
      _submitListing();
    }
  }

  // ── Date picker ──────────────────────────────────────────────────────────────

  Future<void> _pickAvailableFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => availableFrom = picked);
    }
  }

  // ── Image picking ────────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage();
      if (files.isNotEmpty) {
        setState(() => _images.addAll(files.map((e) => File(e.path))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open gallery: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        setState(() => _images.add(File(file.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  void _submitListing() {
    // TODO: wire up to your backend / state management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room listing submitted successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Room'),
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: () {
            if (currentStep > 0) setState(() => currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(currentStep == 2 ? 'Submit' : 'Next'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            _buildStep0(),
            _buildStep1(),
            _buildStep2(),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Room Info ─────────────────────────────────────────────────────────

  Step _buildStep0() {
    return Step(
      title: const Text('Room Info'),
      isActive: currentStep >= 0,
      content: Form(
        key: _step0FormKey,
        child: Column(
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Listing Title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 15),

            // Weekly Rent
            TextFormField(
              controller: _weeklyRentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weekly Rent *',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Rent is required';
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Suburb
            TextFormField(
              controller: _suburbController,
              decoration: const InputDecoration(
                labelText: 'Suburb *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Suburb is required'
                  : null,
            ),
            const SizedBox(height: 15),

            // State & Postcode (side by side)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'State is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _postcodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Postcode *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Postcode is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Bedrooms & Bathrooms (side by side)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bedroomsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bedrooms *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bed_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return 'Enter a number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bathroomsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bathrooms *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bathtub_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return 'Enter a number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Preferred Gender
            DropdownButtonFormField<String>(
              value: selectedPreferredGender,
              decoration: const InputDecoration(
                labelText: 'Preferred Gender *',
                border: OutlineInputBorder(),
              ),
              items: genderPreferences
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedPreferredGender = v),
              validator: (v) =>
                  v == null ? 'Please select a preferred gender' : null,
            ),
            const SizedBox(height: 15),

            // Available From
            GestureDetector(
              onTap: _pickAvailableFrom,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Available From *',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                    hintText: availableFrom == null
                        ? 'Select a date'
                        : '${availableFrom!.day}/${availableFrom!.month}/${availableFrom!.year}',
                  ),
                  controller: TextEditingController(
                    text: availableFrom == null
                        ? ''
                        : '${availableFrom!.day}/${availableFrom!.month}/${availableFrom!.year}',
                  ),
                  validator: (_) => availableFrom == null
                      ? 'Please select an available from date'
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Furnished toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Furnished'),
              secondary: const Icon(Icons.weekend_outlined),
              value: isFurnished,
              onChanged: (v) => setState(() => isFurnished = v),
            ),

            // Bills Included toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bills Included'),
              secondary: const Icon(Icons.receipt_long_outlined),
              value: billsIncluded,
              onChanged: (v) => setState(() => billsIncluded = v),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Photos ────────────────────────────────────────────────────────────

  Step _buildStep1() {
    return Step(
      title: const Text('Photos'),
      isActive: currentStep >= 1,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (_images.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'At least one photo is required *',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (_, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Step 2: Description & Contact ────────────────────────────────────────────

  Step _buildStep2() {
    return Step(
      title: const Text('Details & Contact'),
      isActive: currentStep >= 2,
      content: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 15),

            // Amenities (comma-separated)
            TextFormField(
              controller: _amenitiesController,
              decoration: const InputDecoration(
                labelText: 'Amenities (comma-separated)',
                hintText: 'e.g. WiFi, Parking, Pool',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star_outline),
              ),
            ),
            const SizedBox(height: 15),

            // Owner Name
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 15),

            // Owner Phone
            TextFormField(
              controller: _ownerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Phone number is required'
                  : null,
            ),
            const SizedBox(height: 20),

            // Summary preview card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.home_work_outlined),
                      title: Text(
                        _titleController.text.isEmpty
                            ? 'Listing Title'
                            : _titleController.text,
                      ),
                      subtitle: Text(
                        '\$${_weeklyRentController.text.isEmpty ? '0' : _weeklyRentController.text} / week',
                      ),
                    ),
                    if (_suburbController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_suburbController.text}, ${_stateController.text} ${_postcodeController.text}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          if (isFurnished)
                            const Chip(label: Text('Furnished')),
                          if (billsIncluded)
                            const Chip(label: Text('Bills Included')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}