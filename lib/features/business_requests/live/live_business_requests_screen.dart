import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../profile/data/profile_demo_store.dart';
import '../../post_listing/post_business_screen.dart';
import '../data/business_submission.dart';
import 'live_business_api.dart';

/// Real owner-only requests. Does not use ProfileDemoStore for server state.
class LiveBusinessRequestsScreen extends StatefulWidget {
  const LiveBusinessRequestsScreen({super.key});
  @override
  State<LiveBusinessRequestsScreen> createState() =>
      _LiveBusinessRequestsScreenState();
}

class _LiveBusinessRequestsScreenState
    extends State<LiveBusinessRequestsScreen> {
  final _api = LiveBusinessApi();
  late Future<List<LiveBusinessRequest>> _future;
  String _filter = 'All';
  @override
  void initState() {
    super.initState();
    _future = _api.mine();
  }

  void _reload() => setState(() => _future = _api.mine());
  BusinessRequestPreview _editable(LiveBusinessRequest request) {
    final m = request.raw;
    final hours = Map<String, String>.from(m['openingHours'] as Map);
    final structured = Map<String, Map<String, dynamic>>.from(
        (m['openingHoursStructured'] as Map).map((key, value) =>
            MapEntry(key.toString(), Map<String, dynamic>.from(value as Map))));
    return BusinessRequestPreview(
      id: request.id,
      businessName: request.businessName,
      category: request.category,
      location: request.location,
      createdAt: request.submittedAt,
      status: BusinessRequestStatus.declined,
      declineReason: request.declineReason,
      revision: request.revision,
      submission: BusinessSubmission(
        name: request.businessName,
        category: request.category,
        phone: m['phone'] as String,
        website: m['website'] as String? ?? '',
        description: m['description'] as String,
        onlineOnly: m['onlineOnly'] == true,
        address: m['address'] as String? ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        placeId: m['placeId'] as String?,
        city: m['city'] as String?,
        state: m['state'] as String?,
        countryCode: m['countryCode'] as String?,
        bannerBytes: Uint8List(0),
        openingHours: hours,
        openingHoursStructured: structured,
      ),
    );
  }

  Future<void> _correct(LiveBusinessRequest r) async {
    final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => PostBusinessScreen(initialRequest: _editable(r))));
    if (changed == true && mounted) _reload();
  }

  void _details(LiveBusinessRequest r) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.businessName,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              FutureBuilder<Uint8List>(
                  future: _api.ownerBanner(r.id),
                  builder: (context, image) => image.hasData
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(image.data!,
                              height: 170, fit: BoxFit.cover))
                      : image.hasError
                          ? const SizedBox.shrink()
                          : const SizedBox(
                              height: 40,
                              child:
                                  Center(child: CircularProgressIndicator()))),
              const SizedBox(height: 12),
              Text('Status: ${r.status.toUpperCase()}'),
              Text('Category: ${r.category}'),
              Text('Location: ${r.location}'),
              Text('Revision: ${r.revision}'),
              Text('Contact: ${r.raw['phone']}'),
              Text('Description: ${r.raw['description']}'),
              const SizedBox(height: 12),
              const Text('Opening hours',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...Map<String, String>.from(r.raw['openingHours'] as Map)
                  .entries
                  .map((e) => Text('${e.key}: ${e.value}')),
              if (r.declineReason != null)
                Text('Decline reason: ${r.declineReason}',
                    style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              if (r.status == 'declined')
                FilledButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Correct and resubmit'),
                    onPressed: () {
                      Navigator.pop(context);
                      _correct(r);
                    }),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          )),
        )),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Business Requests'), actions: [
          IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh status'),
        ]),
        body: FutureBuilder<List<LiveBusinessRequest>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError)
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(snapshot.error.toString()),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ]),
              ));
            final data = snapshot.data ?? [];
            final shown = data
                .where((r) =>
                    _filter == 'All' ||
                    r.status.toLowerCase() == _filter.toLowerCase())
                .toList();
            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _future;
              },
              child: ListView(padding: const EdgeInsets.all(16), children: [
                const Text('Your submitted businesses',
                    style:
                        TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    'Only approved and active businesses appear publicly. Manual payment is arranged privately.'),
                const SizedBox(height: 16),
                Wrap(
                    spacing: 8,
                    children: ['All', 'Pending', 'Approved', 'Declined']
                        .map((f) => ChoiceChip(
                            label: Text(f),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f)))
                        .toList()),
                if (shown.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                          child: Text('No business requests in this status.'))),
                ...shown.map((r) => Card(
                        child: ListTile(
                      title: Text(r.businessName),
                      subtitle: Text(
                          '${r.category} · ${r.status.toUpperCase()} · ${r.location}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _details(r),
                    ))),
              ]),
            );
          },
        ),
      );
}
