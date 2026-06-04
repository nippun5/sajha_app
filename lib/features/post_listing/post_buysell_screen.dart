import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PostBuySellScreen extends StatefulWidget {
  const PostBuySellScreen({super.key});

  @override
  State<PostBuySellScreen> createState() => _PostBuySellScreenState();
}

class _PostBuySellScreenState extends State<PostBuySellScreen> {
  int currentStep = 0;

  final _step0FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? selectedCategory;
  String? selectedCondition;

  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];

  final List<String> categories = [
    'Electronics',
    'Furniture',
    'Vehicles',
    'Books',
    'Clothing',
    'Sports',
    'Others',
  ];

  final List<String> conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Used',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  String? _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        if (!(_step0FormKey.currentState?.validate() ?? false)) {
          return 'Please fill in all required fields.';
        }
        if (selectedCategory == null) return 'Please select a category.';
        if (selectedCondition == null) return 'Please select a condition.';
        return null;
      case 1:
        if (_images.isEmpty) return 'Please add at least one photo.';
        return null;
      case 2:
        if (!(_step2FormKey.currentState?.validate() ?? false)) {
          return 'Please enter a description.';
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

  // ── Image picking ────────────────────────────────────────────────────────────

  Future<void> pickFromGallery() async {
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

  Future<void> takePhoto() async {
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listing submitted successfully'),
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
        title: const Text('Post Product'),
      ),
      body: Stepper(
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
    );
  }

  // ── Step 0: Product Info ─────────────────────────────────────────────────────

  Step _buildStep0() {
    return Step(
      title: const Text('Product Info'),
      isActive: currentStep >= 0,
      content: Form(
        key: _step0FormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
              validator: (v) => v == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition *',
                border: OutlineInputBorder(),
              ),
              items: conditions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCondition = v),
              validator: (v) => v == null ? 'Please select a condition' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price *',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Location is required'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Photos ───────────────────────────────────────────────────────────

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
                  onPressed: takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: pickFromGallery,
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

  // ── Step 2: Description ──────────────────────────────────────────────────────

  Step _buildStep2() {
    return Step(
      title: const Text('Description'),
      isActive: currentStep >= 2,
      content: Form(
        key: _step2FormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(
                  _titleController.text.isEmpty
                      ? 'Product Title'
                      : _titleController.text,
                ),
                subtitle: Text('\$${_priceController.text}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}