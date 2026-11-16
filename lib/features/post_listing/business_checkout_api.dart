import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Configure once after login. Tokens are read again for every request.
/// The server owns pricing, payment verification, and publication.
class BusinessCheckoutApi {
  static BusinessCheckoutApi? instance;
  BusinessCheckoutApi({required this.baseUrl, required this.accessToken});
  final Uri baseUrl;
  final Future<String> Function() accessToken;

  Uri _url(String path) {
    if (baseUrl.scheme != 'https') {
      throw StateError('Business checkout requires HTTPS.');
    }
    return baseUrl.resolve(path);
  }

  Future<Map<String, String>> _headers() async => {
        'Authorization': 'Bearer ${await accessToken()}',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Request failed (${response.statusCode}). Please try again.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createDraft(
    Map<String, dynamic> business,
    XFile banner,
    String requestId,
  ) async {
    final request = http.MultipartRequest('POST', _url('business/drafts'));
    request.headers.addAll(await _headers());
    request.headers['Idempotency-Key'] = requestId;
    request.fields['business'] = jsonEncode(business);
    request.files.add(http.MultipartFile.fromBytes(
      'banner',
      await banner.readAsBytes(),
      filename: banner.name,
    ));
    final response = await request.send().timeout(const Duration(seconds: 45));
    return _decode(await http.Response.fromStream(response));
  }

  Future<Map<String, dynamic>> status(String draftId) async => _decode(
        await http
            .get(_url('business/drafts/${Uri.encodeComponent(draftId)}'),
                headers: await _headers())
            .timeout(const Duration(seconds: 25)),
      );

  Future<Uri> checkout(String draftId, String method) async {
    final result = _decode(await http
        .post(
          _url('business/checkout'),
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({'draftId': draftId, 'method': method}),
        )
        .timeout(const Duration(seconds: 25)));
    final uri = Uri.parse(result['checkoutUrl'] as String);
    if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw StateError('Invalid checkout address.');
    }
    return uri;
  }
}

class DummyBusinessCheckoutApi extends BusinessCheckoutApi {
  DummyBusinessCheckoutApi()
      : super(
          baseUrl: Uri.parse('https://example.com/api/'),
          accessToken: () async => 'dummy_demo_token',
        );

  bool _checkoutStarted = false;

  @override
  Future<Map<String, dynamic>> createDraft(
    Map<String, dynamic> business,
    XFile banner,
    String requestId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'draftId': 'demo_draft_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'pending_payment',
      'business': business,
    };
  }

  @override
  Future<Map<String, dynamic>> status(String draftId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Returnscommon pricing/status fields for demo purposes.
    // Once checkout() is called once, you can flip status to 'paid'/'published' if needed.
    return {
      'draftId': draftId,
      'status': _checkoutStarted ? 'paid' : 'pending_payment',
      'paid': _checkoutStarted,
      'published': _checkoutStarted,
      'amount': 49.99,
      'price': '\$49.99',
      'currency': 'USD',
      'methods': ['card', 'stripe', 'paypal'],
    };
  }

  @override
  Future<Uri> checkout(String draftId, String method) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _checkoutStarted = true;
    return Uri.parse(
        'https://example.com/demo-checkout?draftId=$draftId&method=$method');
  }
}
