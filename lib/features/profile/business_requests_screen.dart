import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import 'data/profile_demo_store.dart';
import 'profile_widgets.dart';

class BusinessRequestsScreen extends StatefulWidget {
  const BusinessRequestsScreen({super.key});

  @override
  State<BusinessRequestsScreen> createState() => _BusinessRequestsScreenState();
}

class _BusinessRequestsScreenState extends State<BusinessRequestsScreen> {
  final _store = ProfileDemoStore.instance;
  String _filter = 'All';

  Future<void> _createPendingPreview() async {
    final name = TextEditingController();
    final category = TextEditingController();
    final location = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('New demo request'),
          content: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This simulates a pending request on this device. '
                  'No administrator is contacted and no money is collected.'),
              const SizedBox(height: 12),
              TextField(
                  controller: name,
                  maxLength: 100,
                  decoration:
                      const InputDecoration(labelText: 'Business name')),
              TextField(
                  controller: category,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Category')),
              TextField(
                  controller: location,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Location')),
            ],
          )),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Add pending demo')),
          ],
        ),
      );
      if (confirmed == true) {
        if (name.text.trim().isEmpty ||
            category.text.trim().isEmpty ||
            location.text.trim().isEmpty) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fill out all three fields.')));
          return;
        }
        _store.addBusinessRequest(
          businessName: name.text.trim(),
          category: category.text.trim(),
          location: location.text.trim(),
        );
      }
    } finally {
      name.dispose();
      category.dispose();
      location.dispose();
    }
  }

  void _showDetails(BusinessRequestPreview request) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.businessName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 10),
              ProfileBadge(
                  label: request.status.label,
                  color: colorForBusinessStatus(request.status)),
              const SizedBox(height: 16),
              Text('Category: ${request.category}'),
              const SizedBox(height: 6),
              Text('Location: ${request.location}'),
              const SizedBox(height: 6),
              Text('Submitted: ${displayDate(request.createdAt)}'),
              const SizedBox(height: 16),
              Text(_statusDescription(request),
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.5)),
              if (request.declineReason != null) ...[
                const SizedBox(height: 12),
                Text('Reason: ${request.declineReason}',
                    style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'))),
            ],
          ),
        ),
      ),
    );
  }

  String _statusDescription(BusinessRequestPreview request) {
    switch (request.status) {
      case BusinessRequestStatus.pending:
        return 'Awaiting admin review. Under the proposed workflow, the '
            'administrator contacts the owner privately and publishes only '
            'after separate payment verification. This record is DEMO ONLY.';
      case BusinessRequestStatus.approved:
        return 'Sample approved status. In production, the backend will make '
            'an approved business visible in the public directory.';
      case BusinessRequestStatus.declined:
        return 'Sample declined status. In production, an administrator '
            'may provide a reason and the owner can request a revision.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Business Requests')),
      body: AnimatedBuilder(
        animation: Listenable.merge([_store, AuthSession.instance]),
        builder: (context, _) {
          final allowed = AuthSession.instance.isSignedIn ||
              (kDebugMode && _store.previewEnabled);
          if (!allowed) {
            return const ProfileEmptyState(
                icon: Icons.storefront_outlined,
                title: 'Your business requests',
                message: 'Sign in to follow your business submissions and '
                    'their review status.');
          }
          final requests = _store.businessRequests
              .where((request) =>
                  _filter == 'All' || request.status.label == _filter)
              .toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (_store.previewEnabled) ...[
              const DemoBanner(),
              const SizedBox(height: 14),
            ],
            const Text('Submission status',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text(
                'Your business appears in the directory only '
                'after admin approval. Listing requests are paid; '
                'no automatic payment is performed here.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 16),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: ['All', 'Pending', 'Approved', 'Declined']
                        .map((filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                  label: Text(filter),
                                  selected: _filter == filter,
                                  onSelected: (_) =>
                                      setState(() => _filter = filter)),
                            ))
                        .toList())),
            if (_store.previewEnabled) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _createPendingPreview,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add pending demo request'),
              ),
            ],
            const SizedBox(height: 12),
            if (requests.isEmpty)
              const ProfileEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No requests found',
                  message: 'Business requests in this status appear here.')
            else
              ...requests.map((request) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: const CircleAvatar(
                          backgroundColor: AppColors.border,
                          child: Icon(Icons.storefront_outlined,
                              color: AppColors.primary)),
                      title: Text(request.businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${request.category} • ${request.location}'),
                            const SizedBox(height: 6),
                            ProfileBadge(
                                label: request.status.label,
                                color: colorForBusinessStatus(request.status)),
                          ]),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDetails(request),
                    ),
                  )),
          ]);
        },
      ),
    );
  }
}
