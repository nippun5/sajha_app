import 'package:flutter/foundation.dart';

enum ListingType { buySell, room, job }

enum ListingStatus { active, sold, draft }

enum BusinessRequestStatus { pending, approved, declined }

extension ListingTypeLabel on ListingType {
  String get label {
    switch (this) {
      case ListingType.buySell:
        return 'Buy & Sell';
      case ListingType.room:
        return 'Room';
      case ListingType.job:
        return 'Job';
    }
  }
}

extension ListingStatusLabel on ListingStatus {
  String get label {
    switch (this) {
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.sold:
        return 'Closed';
      case ListingStatus.draft:
        return 'Draft';
    }
  }
}

extension BusinessStatusLabel on BusinessRequestStatus {
  String get label {
    switch (this) {
      case BusinessRequestStatus.pending:
        return 'Pending';
      case BusinessRequestStatus.approved:
        return 'Approved';
      case BusinessRequestStatus.declined:
        return 'Declined';
    }
  }
}

class ProfileListing {
  const ProfileListing({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.priceLabel,
    required this.location,
    required this.createdAt,
    this.description = '',
  });

  final String id;
  final String title;
  final ListingType type;
  final ListingStatus status;
  final String priceLabel;
  final String location;
  final DateTime createdAt;
  final String description;

  ProfileListing copyWith({
    String? title,
    String? priceLabel,
    String? location,
    String? description,
    ListingStatus? status,
  }) {
    return ProfileListing(
      id: id,
      title: title ?? this.title,
      priceLabel: priceLabel ?? this.priceLabel,
      location: location ?? this.location,
      description: description ?? this.description,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class BusinessRequestPreview {
  const BusinessRequestPreview({
    required this.id,
    required this.businessName,
    required this.category,
    required this.location,
    required this.createdAt,
    required this.status,
    this.declineReason,
  });

  final String id;
  final String businessName;
  final String category;
  final String location;
  final DateTime createdAt;
  final BusinessRequestStatus status;
  final String? declineReason;
}

/// A deliberately IN-MEMORY, DEBUG-ONLY demo data source.
/// No account is authenticated, no listing is published, no administrator is
/// notified, and no payment is recorded by anything in this file.
/// Later replace this with user-scoped API repositories.
class ProfileDemoStore extends ChangeNotifier {
  ProfileDemoStore._();
  static final ProfileDemoStore instance = ProfileDemoStore._();

  bool _enabled = false;
  final List<ProfileListing> _myListings = [];
  final List<ProfileListing> _catalog = [];
  final Set<String> _savedIds = {};
  final List<BusinessRequestPreview> _requests = [];
  int _nextId = 1000;

  String _displayName = 'Demo Community Member';
  String _city = 'Demo City';
  bool _showContactOnListings = false;
  bool _allowWhatsapp = false;
  bool _emailUpdates = false;

  bool get previewEnabled => kDebugMode && _enabled;
  List<ProfileListing> get myListings => List.unmodifiable(_myListings);
  List<ProfileListing> get catalog => List.unmodifiable(_catalog);
  List<BusinessRequestPreview> get businessRequests =>
      List.unmodifiable(_requests);
  List<ProfileListing> get savedListings =>
      List.unmodifiable(_catalog.where((item) => _savedIds.contains(item.id)));
  bool isSaved(String id) => _savedIds.contains(id);

  String get displayName => _displayName;
  String get city => _city;
  bool get showContactOnListings => _showContactOnListings;
  bool get allowWhatsapp => _allowWhatsapp;
  bool get emailUpdates => _emailUpdates;

  String _newId(String prefix) => '$prefix-${_nextId++}';

  void enablePreview() {
    if (!kDebugMode || _enabled) return;
    _enabled = true;
    final now = DateTime.now();
    _myListings
      ..clear()
      ..addAll([
        ProfileListing(
          id: _newId('listing'),
          title: 'Demo bicycle',
          type: ListingType.buySell,
          status: ListingStatus.active,
          priceLabel: '\$120',
          location: 'Demo City',
          createdAt: now.subtract(const Duration(days: 2)),
          description: 'A sample listing for testing the Profile UI.',
        ),
        ProfileListing(
          id: _newId('listing'),
          title: 'Demo furnished room',
          type: ListingType.room,
          status: ListingStatus.draft,
          priceLabel: '\$190 / week',
          location: 'Demo Suburb',
          createdAt: now.subtract(const Duration(days: 6)),
        ),
        ProfileListing(
          id: _newId('listing'),
          title: 'Demo part-time helper',
          type: ListingType.job,
          status: ListingStatus.sold,
          priceLabel: '\$25 / hour',
          location: 'Demo City',
          createdAt: now.subtract(const Duration(days: 9)),
        ),
      ]);
    _catalog
      ..clear()
      ..addAll([
        ProfileListing(
          id: 'sample-market-1',
          title: 'Sample study desk',
          type: ListingType.buySell,
          status: ListingStatus.active,
          priceLabel: '\$65',
          location: 'Demo City',
          createdAt: now,
        ),
        ProfileListing(
          id: 'sample-market-2',
          title: 'Sample shared room',
          type: ListingType.room,
          status: ListingStatus.active,
          priceLabel: '\$170 / week',
          location: 'Demo Suburb',
          createdAt: now,
        ),
        ProfileListing(
          id: 'sample-market-3',
          title: 'Sample weekend job',
          type: ListingType.job,
          status: ListingStatus.active,
          priceLabel: '\$30 / hour',
          location: 'Demo City',
          createdAt: now,
        ),
      ]);
    _savedIds
      ..clear()
      ..add('sample-market-1');
    _requests
      ..clear()
      ..addAll([
        BusinessRequestPreview(
          id: _newId('business'),
          businessName: 'Demo Himalayan Cafe',
          category: 'Restaurant & cafe',
          location: 'Demo City',
          createdAt: now.subtract(const Duration(days: 1)),
          status: BusinessRequestStatus.pending,
        ),
        BusinessRequestPreview(
          id: _newId('business'),
          businessName: 'Demo Community Grocery',
          category: 'Grocery & retail',
          location: 'Demo City',
          createdAt: now.subtract(const Duration(days: 20)),
          status: BusinessRequestStatus.approved,
        ),
        BusinessRequestPreview(
          id: _newId('business'),
          businessName: 'Demo Repairs',
          category: 'Home services',
          location: 'Demo Suburb',
          createdAt: now.subtract(const Duration(days: 30)),
          status: BusinessRequestStatus.declined,
          declineReason: 'Example: More business details are required.',
        ),
      ]);
    notifyListeners();
  }

  void disablePreview() {
    if (!_enabled) return;
    _enabled = false;
    _myListings.clear();
    _catalog.clear();
    _savedIds.clear();
    _requests.clear();
    _displayName = 'Demo Community Member';
    _city = 'Demo City';
    _showContactOnListings = false;
    _allowWhatsapp = false;
    _emailUpdates = false;
    notifyListeners();
  }

  void addListing({
    required String title,
    required ListingType type,
    required String priceLabel,
    required String location,
    String description = '',
  }) {
    if (!previewEnabled) return;
    _myListings.insert(
        0,
        ProfileListing(
          id: _newId('listing'),
          title: title,
          type: type,
          status: ListingStatus.draft,
          priceLabel: priceLabel,
          location: location,
          description: description,
          createdAt: DateTime.now(),
        ));
    notifyListeners();
  }

  void editListing(String id,
      {required String title, required String priceLabel}) {
    if (!previewEnabled) return;
    final index = _myListings.indexWhere((l) => l.id == id);
    if (index == -1) return;
    _myListings[index] = _myListings[index].copyWith(
      title: title,
      priceLabel: priceLabel,
    );
    notifyListeners();
  }

  void setListingStatus(String id, ListingStatus status) {
    if (!previewEnabled) return;
    final index = _myListings.indexWhere((l) => l.id == id);
    if (index == -1) return;
    _myListings[index] = _myListings[index].copyWith(status: status);
    notifyListeners();
  }

  void removeListing(String id) {
    if (!previewEnabled) return;
    _myListings.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  void toggleSaved(String id) {
    if (!previewEnabled || !_catalog.any((l) => l.id == id)) return;
    if (!_savedIds.add(id)) _savedIds.remove(id);
    notifyListeners();
  }

  void addBusinessRequest({
    required String businessName,
    required String category,
    required String location,
  }) {
    if (!previewEnabled) return;
    _requests.insert(
        0,
        BusinessRequestPreview(
          id: _newId('business'),
          businessName: businessName,
          category: category,
          location: location,
          createdAt: DateTime.now(),
          status: BusinessRequestStatus.pending,
        ));
    notifyListeners();
  }

  void updateDemoPreferences({
    required String displayName,
    required String city,
    required bool showContactOnListings,
    required bool allowWhatsapp,
    required bool emailUpdates,
  }) {
    if (!previewEnabled) return;
    _displayName = displayName;
    _city = city;
    _showContactOnListings = showContactOnListings;
    _allowWhatsapp = allowWhatsapp;
    _emailUpdates = emailUpdates;
    notifyListeners();
  }
}
