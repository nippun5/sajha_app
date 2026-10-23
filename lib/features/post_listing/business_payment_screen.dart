import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'business_checkout_api.dart';

class BusinessPaymentScreen extends StatefulWidget {
  const BusinessPaymentScreen({super.key, required this.api,
    required this.draftId, required this.businessName});
  final BusinessCheckoutApi api;
  final String draftId;
  final String businessName;
  @override
  State<BusinessPaymentScreen> createState() => _BusinessPaymentScreenState();
}

class _BusinessPaymentScreenState extends State<BusinessPaymentScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _status;
  String? _method;
  String? _error;
  bool _loading = false;
  bool _launching = false;
  bool _opened = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _opened) _refresh();
  }
  Future<void> _refresh() async {
    if (_loading || _completed) return;
    setState(() { _loading = true; _error = null; });
    try {
      final status = await widget.api.status(widget.draftId);
      if (!mounted) return;
      if (status['status'] == 'published') {
        _completed = true;
        Navigator.pop(context, true);
        return;
      }
      final methods = List<String>.from(status['methods'] as List? ?? []);
      setState(() {
        _status = status;
        if (!methods.contains(_method)) _method = methods.isEmpty ? null : methods.first;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not check payment status. Please retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _pay() async {
    setState(() { _launching = true; _error = null; });
    try {
      final url = await widget.api.checkout(widget.draftId, _method!);
      _opened = true;
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw StateError('Checkout could not open');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open checkout. Your listing is saved; try again.');
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final methods = List<String>.from(_status?['methods'] as List? ?? []);
    final pending = _status?['status'] == 'paid_pending_publication';
    return Scaffold(
      appBar: AppBar(title: const Text('Activate your listing')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.workspace_premium, size: 64, color: Color(0xFFB58A32)),
        const SizedBox(height: 16),
        Text(widget.businessName, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Your business is ready for its next chapter.', textAlign: TextAlign.center),
        const SizedBox(height: 28),
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SAJHA BUSINESS • PRO', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(_status?['priceLabel'] as String? ?? 'Loading price…',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          Text(_status?['billingDescription'] as String? ?? 'Price and listing duration will appear here.'),
          const Divider(height: 32),
          const Text('✓  Business directory profile\n✓  Banner, contact details and website\n✓  Location and weekly opening hours',
            style: TextStyle(height: 1.9)),
        ]))),
        const SizedBox(height: 24),
        const Text('Payment method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        for (final method in methods)
          RadioListTile<String>(value: method, groupValue: _method,
            onChanged: _launching || _loading ? null : (value) => setState(() => _method = value),
            title: Text(method == 'paypal' ? 'PayPal' : method == 'card' ? 'Debit or credit card' : method),
            secondary: Icon(method == 'paypal' ? Icons.account_balance_wallet_outlined : Icons.credit_card)),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_opened || pending) Padding(padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(pending ? 'Payment received. Your listing is being published. Do not pay again.'
            : 'Complete checkout in your browser, then return here to check your listing.')),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading || _launching || _method == null || pending ? null : _pay,
          icon: const Icon(Icons.lock_outline),
          label: Text(_launching ? 'Opening checkout…' : _opened ? 'Resume secure checkout' : 'Continue to secure checkout')),
        TextButton(onPressed: _loading || _launching ? null : _refresh,
          child: const Text('Check payment status')),
        const Text('Your listing is published only after payment is verified. '
          'Closing checkout does not publish your business.', textAlign: TextAlign.center),
      ]),
    );
  }
}
