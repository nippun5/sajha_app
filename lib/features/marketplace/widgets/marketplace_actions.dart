import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/marketplace_mock_store.dart';

abstract final class MarketplaceActions {
  static Future<void> share(BuildContext context, MarketItem item) async {
    // Deliberately no website URL yet: no live SaJHa public listing page
    // or verified app/universal links have been configured.
    final text = '${item.title}\n'
        '${item.priceLabel}\n'
        '${item.location}\n\n'
        '${item.description}\n\n'
        'Found on SaJHa — your community marketplace.'
        '${item.ownedByDemo ? '\n(Frontend demonstration only)' : ''}';
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        text,
        subject: 'SaJHa: ${item.title}',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing was unavailable: $e')),
        );
      }
    }
  }

  static Future<void> contact(BuildContext context, MarketItem item,
      {required bool sms}) async {
    if (item.contactPhone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No contact number was provided for this listing.'),
      ));
      return;
    }
    final message = 'Hi, I found "${item.title}" on SaJHa. '
        'Is it still available?';
    final uri = sms
        ? Uri(
            scheme: 'sms',
            path: item.contactPhone,
            queryParameters: {'body': message})
        : Uri(scheme: 'tel', path: item.contactPhone);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(sms ? 'No SMS app is available.' : 'Cannot open dialer.'),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contact action failed: $e')),
        );
      }
    }
  }
}
