import 'package:flutter/material.dart';

import '../../../models/job_model.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  int currentStep = 0;

  final _step0FormKey = GlobalKey<FormState>();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  // Step 0 – Job Info
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();

  JobType? selectedJobType;
  String? selectedSalaryCycle;
  bool isRemote = false;
  DateTime? closingDate;

  // Step 1 – Description & Requirements
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();

  // Step 2 – Employer Contact
  final _employerNameController = TextEditingController();
  final _employerPhoneController = TextEditingController();

  // ─────────────────────────────────────────────────────────────────────────────

  final List<String> salaryCycles = [
    'hourly',
    'weekly',
    'monthly',
    'yearly',
  ];

  String _salaryCycleLabel(String cycle) {
    switch (cycle) {
      case 'hourly':
        return 'Per Hour';
      case 'weekly':
        return 'Per Week';
      case 'monthly':
        return 'Per Month';
      case 'yearly':
        return 'Per Year';
      default:
        return cycle;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _employerNameController.dispose();
    _employerPhoneController.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  String? _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        if (!(_step0FormKey.currentState?.validate() ?? false)) {
          return 'Please fill in all required fields.';
        }
        if (selectedJobType == null) return 'Please select a job type.';
        if (selectedSalaryCycle == null) return 'Please select a salary cycle.';
        return null;
      case 1:
        if (!(_step1FormKey.currentState?.validate() ?? false)) {
          return 'Please fill in all required fields.';
        }
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

  Future<void> _pickClosingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => closingDate = picked);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  void _submitListing() {
    // TODO: wire up to your backend / state management
    // Example of building the JobModel:
    //
    // final job = JobModel(
    //   id: const Uuid().v4(),
    //   title: _titleController.text.trim(),
    //   company: _companyController.text.trim(),
    //   location: _locationController.text.trim(),
    //   salaryMin: double.tryParse(_salaryMinController.text.trim()),
    //   salaryMax: double.tryParse(_salaryMaxController.text.trim()),
    //   salaryCycle: selectedSalaryCycle!,
    //   jobType: selectedJobType!,
    //   description: _descriptionController.text.trim(),
    //   requirements: _requirementsController.text
    //       .split('\n')
    //       .map((e) => e.trim())
    //       .where((e) => e.isNotEmpty)
    //       .toList(),
    //   postedAt: DateTime.now(),
    //   closingDate: closingDate,
    //   isRemote: isRemote,
    //   employerName: _employerNameController.text.trim(),
    //   employerPhone: _employerPhoneController.text.trim(),
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job listing submitted successfully'),
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
        title: const Text('Post a Job'),
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

  // ── Step 0: Job Info ──────────────────────────────────────────────────────────

  Step _buildStep0() {
    return Step(
      title: const Text('Job Info'),
      isActive: currentStep >= 0,
      content: Form(
        key: _step0FormKey,
        child: Column(
          children: [
            // Job Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Job title is required' : null,
            ),
            const SizedBox(height: 15),

            // Company
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
            ),
            const SizedBox(height: 15),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Location is required' : null,
            ),
            const SizedBox(height: 15),

            // Job Type
            DropdownButtonFormField<JobType>(
              value: selectedJobType,
              decoration: const InputDecoration(
                labelText: 'Job Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: JobType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => setState(() => selectedJobType = v),
              validator: (v) => v == null ? 'Please select a job type' : null,
            ),
            const SizedBox(height: 15),

            // Salary Cycle
            DropdownButtonFormField<String>(
              value: selectedSalaryCycle,
              decoration: const InputDecoration(
                labelText: 'Salary Cycle *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat_outlined),
              ),
              items: salaryCycles
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(_salaryCycleLabel(e)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedSalaryCycle = v),
              validator: (v) => v == null ? 'Please select a salary cycle' : null,
            ),
            const SizedBox(height: 15),

            // Salary Min & Max (side by side)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salaryMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Salary',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        if (double.tryParse(v.trim()) == null) {
                          return 'Invalid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salaryMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Salary',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        if (double.tryParse(v.trim()) == null) {
                          return 'Invalid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Closing Date
            GestureDetector(
              onTap: _pickClosingDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Closing Date (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                    hintText: closingDate == null
                        ? 'Select a date'
                        : '${closingDate!.day}/${closingDate!.month}/${closingDate!.year}',
                  ),
                  controller: TextEditingController(
                    text: closingDate == null
                        ? ''
                        : '${closingDate!.day}/${closingDate!.month}/${closingDate!.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Remote toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remote Available'),
              secondary: const Icon(Icons.home_work_outlined),
              value: isRemote,
              onChanged: (v) => setState(() => isRemote = v),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Description & Requirements ───────────────────────────────────────

  Step _buildStep1() {
    return Step(
      title: const Text('Description'),
      isActive: currentStep >= 1,
      content: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Job Description *',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 15),

            // Requirements
            TextFormField(
              controller: _requirementsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Requirements *',
                hintText: 'Enter each requirement on a new line',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.checklist_outlined),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'At least one requirement is required'
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Enter each requirement on a new line.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Employer Contact ──────────────────────────────────────────────────

  Step _buildStep2() {
    return Step(
      title: const Text('Contact Info'),
      isActive: currentStep >= 2,
      content: Form(
        key: _step2FormKey,
        child: Column(
          children: [
            // Employer Name
            TextFormField(
              controller: _employerNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 15),

            // Employer Phone
            TextFormField(
              controller: _employerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
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
                      leading: CircleAvatar(
                        child: Text(
                          _companyController.text.isNotEmpty
                              ? _companyController.text[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        _titleController.text.isEmpty
                            ? 'Job Title'
                            : _titleController.text,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _companyController.text.isEmpty
                            ? 'Company'
                            : _companyController.text,
                      ),
                    ),
                    if (_locationController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _locationController.text,
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (isRemote) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.home_work_outlined, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Remote',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (selectedJobType != null)
                            Chip(
                              label: Text(selectedJobType!.label),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (selectedSalaryCycle != null &&
                              (_salaryMinController.text.isNotEmpty ||
                                  _salaryMaxController.text.isNotEmpty))
                            Chip(
                              label: Text(
                                '\$${_salaryMinController.text.isEmpty ? '?' : _salaryMinController.text}'
                                ' – '
                                '\$${_salaryMaxController.text.isEmpty ? '?' : _salaryMaxController.text}'
                                ' ${_salaryCycleLabel(selectedSalaryCycle!).toLowerCase()}',
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
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