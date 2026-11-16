import 'package:flutter/foundation.dart';

import '../../../models/job_model.dart';
import '../../../models/product_model.dart';
import '../../../models/room_model.dart';
import '../../../shared/data/dummy_data.dart';
import '../../profile/data/profile_demo_store.dart';

/// The three marketplace types. Business requests intentionally use a
/// different review/approval workflow.
enum MarketKind { buySell, room, job }

enum MarketStatus { draft, active, closed }

extension MarketKindText on MarketKind {
  String get label => switch (this) {
        MarketKind.buySell => 'Buy & Sell',
        MarketKind.room => 'Rooms',
        MarketKind.job => 'Jobs',
      };
}

extension MarketStatusText on MarketStatus {
  String get label => switch (this) {
        MarketStatus.draft => 'Draft',
        MarketStatus.active => 'Active',
        MarketStatus.closed => 'Closed',
      };
}

/// One canonical UI listing record. IDs are type-qualified, so product "1"
/// and room "1" are different records and cannot share a bookmark by mistake.
@immutable
class MarketItem {
  const MarketItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.priceLabel,
    required this.category,
    required this.location,
    required this.description,
    required this.createdAt,
    this.imageUrl,
    this.contactName = '',
    this.contactPhone = '',
    this.details = const {},
    this.status = MarketStatus.active,
    this.ownedByDemo = false,
  });

  final String id;
  final MarketKind kind;
  final String title;
  final String priceLabel;
  final String category;
  final String location;
  final String description;
  final DateTime createdAt;
  final String? imageUrl;
  final String contactName;
  final String contactPhone;
  final Map<String, String> details;
  final MarketStatus status;
  final bool ownedByDemo;

  MarketItem copyWith(
      {String? title, String? priceLabel, MarketStatus? status}) {
    return MarketItem(
      id: id,
      kind: kind,
      title: title ?? this.title,
      priceLabel: priceLabel ?? this.priceLabel,
      category: category,
      location: location,
      description: description,
      createdAt: createdAt,
      imageUrl: imageUrl,
      contactName: contactName,
      contactPhone: contactPhone,
      details: details,
      status: status ?? this.status,
      ownedByDemo: ownedByDemo,
    );
  }
}

/// Single mock source for Browse, Saved, My Listings and Detail screens.
/// Public samples come from the real models already in the repository.
/// User-created drafts and bookmarks are DEBUG-ONLY and in-memory.
/// No server writes, identity verification or publication happens here.
class MarketplaceMockStore extends ChangeNotifier {
  MarketplaceMockStore._() {
    _loadSamples();
    ProfileDemoStore.instance.addListener(_onDemoChanged);
    _previewWasEnabled = ProfileDemoStore.instance.previewEnabled;
    if (_previewWasEnabled) _seedPersonalExamples();
  }

  static final MarketplaceMockStore instance = MarketplaceMockStore._();
  final List<MarketItem> _items = [];
  final Set<String> _savedIds = {};
  bool _previewWasEnabled = false;
  int _idSequence = 10000;

  bool get previewEnabled => ProfileDemoStore.instance.previewEnabled;

  List<MarketItem> get publicListings => List.unmodifiable(
        _items.where((e) =>
            e.status == MarketStatus.active &&
            (!e.ownedByDemo || previewEnabled)),
      );

  List<MarketItem> listingsFor(MarketKind kind) =>
      List.unmodifiable(publicListings.where((e) => e.kind == kind));

  List<MarketItem> get myListings => List.unmodifiable(
        previewEnabled ? _items.where((e) => e.ownedByDemo) : <MarketItem>[],
      );

  List<MarketItem> get savedListings => List.unmodifiable(
        previewEnabled
            ? publicListings.where((e) => _savedIds.contains(e.id))
            : <MarketItem>[],
      );

  bool isSaved(String id) => previewEnabled && _savedIds.contains(id);

  void _loadSamples() {
    for (final p in DummyData.buySellListings) {
      _items.add(_fromProduct(p));
    }
    for (final r in DummyData.roomListings) {
      _items.add(_fromRoom(r));
    }
    for (final j in DummyData.jobListings) {
      _items.add(_fromJob(j));
    }
  }

  MarketItem _fromProduct(ProductModel p) => MarketItem(
        id: 'product-${p.id}',
        kind: MarketKind.buySell,
        title: p.title,
        priceLabel: p.formattedPrice,
        category: p.category,
        location: p.location,
        description: p.description,
        imageUrl: p.imageUrls.isEmpty ? null : p.imageUrls.first,
        contactName: p.sellerName,
        contactPhone: p.sellerPhone,
        createdAt: p.postedAt,
        status: p.isAvailable ? MarketStatus.active : MarketStatus.closed,
        details: {'Condition': p.condition.label},
      );

  MarketItem _fromRoom(RoomModel r) {
    final title = r.title.toLowerCase();
    final category = title.contains('master')
        ? 'Master Room'
        : title.contains('apartment')
            ? 'Apartment'
            : title.contains('granny')
                ? 'Granny Flat'
                : 'Single Room';
    return MarketItem(
      id: 'room-${r.id}',
      kind: MarketKind.room,
      title: r.title,
      priceLabel: '\$${r.weeklyRent.toStringAsFixed(0)}/week',
      category: category,
      location: r.locationDisplay,
      description: r.description,
      imageUrl: r.imageUrl,
      contactName: r.ownerName,
      contactPhone: r.ownerPhone,
      createdAt: r.postedAt,
      details: {
        'Bedrooms': '${r.bedrooms}',
        'Bathrooms': '${r.bathrooms}',
        'Furnished': r.furnished ? 'Yes' : 'No',
        'Bills included': r.billsIncluded ? 'Yes' : 'No',
      },
    );
  }

  MarketItem _fromJob(JobModel j) => MarketItem(
        id: 'job-${j.id}',
        kind: MarketKind.job,
        title: j.title,
        priceLabel: j.salaryDisplay,
        category: j.jobType.label,
        location: j.location,
        description: j.description,
        imageUrl: j.companyLogoUrl,
        contactName: j.employerName ?? j.company,
        contactPhone: j.employerPhone ?? '',
        createdAt: j.postedAt,
        details: {
          'Company': j.company,
          'Type': j.jobType.label,
          'Remote': j.isRemote ? 'Yes' : 'No',
        },
      );

  void _onDemoChanged() {
    final current = previewEnabled;
    if (current && !_previewWasEnabled) {
      _seedPersonalExamples();
    } else if (!current && _previewWasEnabled) {
      _items.removeWhere((e) => e.ownedByDemo);
      _savedIds.clear();
    }
    _previewWasEnabled = current;
    notifyListeners();
  }

  void _seedPersonalExamples() {
    final now = DateTime.now();
    _items.insertAll(0, [
      MarketItem(
        id: 'demo-product-100',
        kind: MarketKind.buySell,
        title: 'Demo bicycle',
        priceLabel: '\$120',
        category: 'Sports',
        location: 'Demo City',
        description: 'A demonstration-only bicycle.',
        createdAt: now.subtract(const Duration(days: 2)),
        ownedByDemo: true,
      ),
      MarketItem(
        id: 'demo-room-101',
        kind: MarketKind.room,
        title: 'Demo furnished room',
        priceLabel: '\$190/week',
        category: 'Single Room',
        location: 'Demo Suburb',
        description: 'A demonstration-only room.',
        createdAt: now,
        status: MarketStatus.draft,
        ownedByDemo: true,
      ),
      MarketItem(
        id: 'demo-job-102',
        kind: MarketKind.job,
        title: 'Demo part-time helper',
        priceLabel: '\$25/hour',
        category: 'Part-time',
        location: 'Demo City',
        description: 'A demonstration-only position.',
        createdAt: now,
        status: MarketStatus.closed,
        ownedByDemo: true,
      ),
    ]);
    if (DummyData.buySellListings.isNotEmpty) {
      _savedIds.add('product-${DummyData.buySellListings.first.id}');
    }
  }

  /// Called by the three original posting forms AFTER their validation.
  /// Draft is visible only under Profile > My Listings in demo mode.
  bool addDraft({
    required MarketKind kind,
    required String title,
    required String priceLabel,
    required String category,
    required String location,
    required String description,
    String contactName = '',
    String contactPhone = '',
  }) {
    if (!previewEnabled) return false;
    _items.insert(
        0,
        MarketItem(
          id: 'demo-${kind.name}-${_idSequence++}',
          kind: kind,
          title: title,
          priceLabel: priceLabel,
          category: category,
          location: location,
          description: description,
          contactName: contactName,
          contactPhone: contactPhone,
          createdAt: DateTime.now(),
          status: MarketStatus.draft,
          ownedByDemo: true,
        ));
    notifyListeners();
    return true;
  }

  /// A demo user can edit ONLY their own local preview listing.
  bool updateMine(String id,
      {String? title, String? priceLabel, MarketStatus? status}) {
    if (!previewEnabled) return false;
    final i = _items.indexWhere((e) => e.id == id && e.ownedByDemo);
    if (i < 0) return false;
    _items[i] = _items[i].copyWith(
      title: title,
      priceLabel: priceLabel,
      status: status,
    );
    if (status == MarketStatus.closed || status == MarketStatus.draft) {
      _savedIds.remove(id);
    }
    notifyListeners();
    return true;
  }

  bool deleteMine(String id) {
    if (!previewEnabled) return false;
    final before = _items.length;
    _items.removeWhere((e) => e.id == id && e.ownedByDemo);
    if (before == _items.length) return false;
    _savedIds.remove(id);
    notifyListeners();
    return true;
  }

  bool toggleSaved(String id) {
    if (!previewEnabled || !publicListings.any((e) => e.id == id)) return false;
    if (!_savedIds.add(id)) _savedIds.remove(id);
    notifyListeners();
    return true;
  }
}
