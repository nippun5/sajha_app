import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../post_listing/post_business_screen.dart';
import 'data/profile_demo_store.dart';
import 'profile_widgets.dart';

/// Owner-facing request history. No admin/payment actions live here.
class BusinessRequestsScreen extends StatefulWidget {
  const BusinessRequestsScreen({super.key});

  @override
  State<BusinessRequestsScreen> createState() => _BusinessRequestsScreenState();
}

class _BusinessRequestsScreenState extends State<BusinessRequestsScreen> {
  final ProfileDemoStore _store = ProfileDemoStore.instance;
  String _filter = 'All';

  Future<void> _editDeclined(BusinessRequestPreview request) async {
    if (request.status != BusinessRequestStatus.declined ||
        request.submission == null ||
        !_store.previewEnabled) {
      return;
    }
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PostBusinessScreen(initialRequest: request),
    ));
  }

  void _showDetails(BusinessRequestPreview request) {
    final data = request.submission;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.83),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
            children: [
              Text(request.businessName,
                  style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerLeft,
                  child: ProfileBadge(
                      label: request.status.label,
                      color: colorForBusinessStatus(request.status))),
              const SizedBox(height: 16),
              _info('Request ID', request.id),
              _info('Category', request.category),
              _info('Location', request.location),
              _info('Original submission', displayDate(request.createdAt)),
              _info('Revision', '${request.revision}'),
              if (request.lastSubmittedAt != null)
                _info('Most recent submission',
                    displayDate(request.lastSubmittedAt!)),
              if (data != null) ...[
                if (data.bannerBytes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(data.bannerBytes,
                        height: 175,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                            height: 90,
                            child: Center(
                                child: Text('Banner preview unavailable')))),
                  ),
                ],
                const SizedBox(height: 14),
                _info('Contact number (private request)', data.phone),
                if (data.website.isNotEmpty) _info('Website', data.website),
                _info('Description', data.description),
                _info('Business type',
                    data.onlineOnly ? 'Online only' : 'Physical storefront'),
                if (!data.onlineOnly &&
                    data.latitude != null &&
                    data.longitude != null)
                  _info(
                      'Map pin',
                      '${data.latitude!.toStringAsFixed(6)}, '
                          '${data.longitude!.toStringAsFixed(6)}'),
                const SizedBox(height: 12),
                const Text('Opening hours',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                const SizedBox(height: 6),
                ...data.openingHours.entries
                    .map((entry) => _info(entry.key, entry.value)),
              ] else ...[
                const SizedBox(height: 12),
                const Text('This sample is a summary-only record from the '
                    'earlier Profile demo. New business submissions include '
                    'the complete form.'),
              ],
              const SizedBox(height: 14),
              Text(_statusDescription(request),
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.5)),
              if (request.declineReason != null) ...[
                const SizedBox(height: 12),
                Text('Decline reason: ${request.declineReason}',
                    style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 22),
              if (request.status == BusinessRequestStatus.declined &&
                  data != null &&
                  _store.previewEnabled)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _editDeclined(request);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Correct and resubmit'),
                ),
              OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ]),
      );

  String _statusDescription(BusinessRequestPreview request) {
    switch (request.status) {
      case BusinessRequestStatus.pending:
        return 'Awaiting administrator review. SaJHa may contact the owner '
            'using the submitted contact information. Demo only: this '
            'request has not reached an admin or been published.';
      case BusinessRequestStatus.approved:
        return 'Sample approved status. In production, only backend-approved '
            'businesses will appear in the public directory.';
      case BusinessRequestStatus.declined:
        return 'This request was declined in the example data. You may '
            'correct and resubmit its details when a full form is available.';
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
              message: 'Sign in to view your own submissions. '
                  'In debug mode, enable Profile demo mode to preview.',
            );
          }
          final requests = _store.businessRequests
              .where((request) =>
                  _filter == 'All' || request.status.label == _filter)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_store.previewEnabled) ...[
                const DemoBanner(),
                const SizedBox(height: 14),
              ],
              const Text('Business submissions',
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text(
                  'Only admin-approved businesses will be shown in '
                  'the public directory. Contact and payment discussions '
                  'take place separately from this preview.',
                  style:
                      TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 18),
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
                                    setState(() => _filter = filter),
                              ),
                            ))
                        .toList()),
              ),
              const SizedBox(height: 16),
              if (requests.isEmpty)
                const ProfileEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No matching requests',
                  message: 'Submitted business requests in this status '
                      'will appear here.',
                )
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
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${request.category} • ${request.location}'),
                            const SizedBox(height: 7),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: ProfileBadge(
                                    label: request.status.label,
                                    color: colorForBusinessStatus(
                                        request.status))),
                            if (request.revision > 1)
                              Text('Revision ${request.revision}',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showDetails(request),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
