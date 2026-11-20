import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../features/business_location/business_location_service.dart';
import '../models/business_model.dart';
import '../features/business_reviews/data/business_review_store.dart';
import '../features/business_reviews/widgets/business_reviews_section.dart';

class BusinessDetailPage extends StatelessWidget {
  const BusinessDetailPage({super.key, required this.business});
  final BusinessModel business;

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No compatible application found.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open this action.')));
      }
    }
  }

  Uri _mapUri() {
    final query = business.hasCoordinates
        ? '${business.latitude},${business.longitude}'
        : business.address;
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  Uri? _websiteUri() {
    final raw = business.website.trim();
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  void _share() {
    final buffer = StringBuffer()
      ..writeln(business.name)
      ..writeln(business.category)
      ..writeln(business.onlineOnly ? 'Online business' : business.address);
    if (business.phone.isNotEmpty) buffer.writeln('Phone: ${business.phone}');
    final website = _websiteUri();
    if (website != null) buffer.writeln(website.toString());
    buffer.writeln(
        'Found on SaJHa (preview; public business links coming later)');
    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final phone = business.phone.trim();
    final whatsappNumber = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappEnabled = phone.startsWith('+') && whatsappNumber.length >= 8;
    final website = _websiteUri();
    final apiKey = const GeoapifyBusinessLocationService().apiKey;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Business Details'), actions: [
        IconButton(
            onPressed: _share,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share business'),
      ]),
      body: ListView(children: [
        SizedBox(
            height: 235,
            width: double.infinity,
            child: Image.network(business.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.border,
                    child: Center(child: Icon(Icons.storefront, size: 54))))),
        Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (kDebugMode)
                const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Chip(label: Text('Sample business preview'))),
              Text(business.name,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(label: Text(business.category)),
                    AnimatedBuilder(
                      animation: BusinessReviewStore.instance,
                      builder: (context, _) {
                        final summary =
                            BusinessReviewStore.instance.summaryFor(business);
                        return Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.warning),
                          Text(
                              ' ${summary.count == 0 ? 'Unrated' : summary.average.toStringAsFixed(1)}  '
                              '(${summary.count} reviews)'),
                        ]);
                      },
                    ),
                  ]),
              const SizedBox(height: 12),
              Text(business.description, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 20),
              const Text('Contact & directions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (phone.isNotEmpty)
                  FilledButton.icon(
                      onPressed: () =>
                          _open(context, Uri(scheme: 'tel', path: phone)),
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('Call'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary)),
                if (phone.isNotEmpty)
                  OutlinedButton.icon(
                      onPressed: () =>
                          _open(context, Uri(scheme: 'sms', path: phone)),
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('SMS')),
                if (whatsappEnabled)
                  OutlinedButton.icon(
                      onPressed: () => _open(
                          context, Uri.https('wa.me', '/$whatsappNumber')),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('WhatsApp')),
                if (!business.onlineOnly)
                  OutlinedButton.icon(
                      onPressed: () => _open(context, _mapUri()),
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Directions')),
                if (website != null)
                  OutlinedButton.icon(
                      onPressed: () => _open(context, website),
                      icon: const Icon(Icons.language),
                      label: const Text('Website')),
                OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share')),
              ]),
              const SizedBox(height: 18),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      business.onlineOnly ? Icons.public : Icons.place,
                      color: AppColors.coral),
                  title: Text(business.onlineOnly
                      ? 'Online-only business'
                      : business.address),
                  subtitle: business.locationNote == null
                      ? null
                      : Text(business.locationNote!),
                  trailing: !business.onlineOnly
                      ? IconButton(
                          onPressed: () => _open(context, _mapUri()),
                          icon: const Icon(Icons.open_in_new))
                      : null),
              if (!business.onlineOnly &&
                  business.hasCoordinates &&
                  apiKey.isNotEmpty)
                SizedBox(
                    height: 190,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter:
                                LatLng(business.latitude!, business.longitude!),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag),
                          ),
                          children: [
                            TileLayer(
                                urlTemplate:
                                    'https://maps.geoapify.com/v1/tile/osm-bright/'
                                    '{z}/{x}/{y}.png?apiKey=$apiKey',
                                maxZoom: 19),
                            MarkerLayer(markers: [
                              Marker(
                                point: LatLng(
                                    business.latitude!, business.longitude!),
                                width: 48,
                                height: 48,
                                child: const Icon(Icons.location_pin,
                                    size: 44, color: AppColors.coral),
                              )
                            ]),
                          ],
                        ),
                        Positioned(
                            left: 5,
                            right: 5,
                            bottom: 5,
                            child: Container(
                                color: Colors.white.withOpacity(.9),
                                child: const Text(
                                    'Powered by Geoapify | © OpenStreetMap contributors | © OpenMapTiles',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 9)))),
                      ]),
                    )),
              if (business.openingHours.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Opening hours',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            children: business.openingHours.entries
                                .map((e) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Row(children: [
                                      Expanded(child: Text(e.key)),
                                      Flexible(
                                          child: Text(e.value,
                                              textAlign: TextAlign.right)),
                                    ])))
                                .toList()))),
              ],
              const SizedBox(height: 22),
              BusinessReviewsSection(business: business),
              const SizedBox(height: 36),
            ])),
      ]),
    );
  }
}
