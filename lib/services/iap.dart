import 'dart:async';
import 'dart:math';

import 'package:in_app_purchase/in_app_purchase.dart' as store;

enum IapProductKind { consumable, nonConsumable }

enum IapPurchaseStatus { approved, pending, failed, cancelled }

enum IapErrorCode {
  userCancelled,
  alreadyOwned,
  billingUnavailable,
  network,
  developer,
  unknown,
}

class IapProduct {
  const IapProduct({
    required this.key,
    required this.productId,
    required this.purchaseOptionId,
    required this.label,
    required this.deliveredCoins,
    required this.kind,
  });

  final String key;
  final String productId;
  final String purchaseOptionId;
  final String label;
  final int deliveredCoins;
  final IapProductKind kind;

  bool get removesAds => productId == IapProducts.removeAdsId;
}

class IapProducts {
  const IapProducts._();

  static const String smallId = '100_coins';
  static const String mediumId = '500_coins';
  static const String largeId = '1200_coins';
  static const String removeAdsId = 'ads_remove';

  static const small = IapProduct(
    key: 'small',
    productId: smallId,
    purchaseOptionId: '100-coins-buy',
    label: '100 Coins',
    deliveredCoins: 100,
    kind: IapProductKind.consumable,
  );

  static const medium = IapProduct(
    key: 'medium',
    productId: mediumId,
    purchaseOptionId: '500-coins-buy',
    label: '500 Coins',
    deliveredCoins: 550,
    kind: IapProductKind.consumable,
  );

  static const large = IapProduct(
    key: 'large',
    productId: largeId,
    purchaseOptionId: '1200-coins-buy',
    label: '1200 Coins',
    deliveredCoins: 1400,
    kind: IapProductKind.consumable,
  );

  static const removeAds = IapProduct(
    key: 'removeads',
    productId: removeAdsId,
    purchaseOptionId: 'ads-remove-buy',
    label: 'Remove Ads',
    deliveredCoins: 0,
    kind: IapProductKind.nonConsumable,
  );

  static const all = [small, medium, large, removeAds];

  static IapProduct? byProductId(String productId) {
    for (final product in all) {
      if (product.productId == productId) return product;
    }
    return null;
  }
}

class IapPurchase {
  const IapPurchase({
    required this.productId,
    required this.status,
    this.transactionId = '',
    this.purchaseId = '',
    this.purchaseDate,
  });

  final String productId;
  final IapPurchaseStatus status;
  final String transactionId;
  final String purchaseId;
  final DateTime? purchaseDate;

  bool get isApproved => status == IapPurchaseStatus.approved;

  String get transactionKey {
    final tx = transactionId.isNotEmpty
        ? transactionId
        : purchaseId.isNotEmpty
            ? purchaseId
            : purchaseDate?.millisecondsSinceEpoch.toString() ?? 'unknown';
    return '$productId:$tx';
  }
}

abstract class IapPurchaseAdapter {
  Future<void> buyProduct(IapProduct product);
  Future<void> completePurchase(IapPurchase purchase);
  Future<List<IapPurchase>> restorePurchases();
}

class IapException implements Exception {
  const IapException(this.code, [this.message = 'IAP error']);

  final IapErrorCode code;
  final String message;

  @override
  String toString() => message;
}

class IapUnavailableException extends IapException {
  const IapUnavailableException([String message = 'IAP adapter unavailable'])
      : super(IapErrorCode.billingUnavailable, message);
}

class DevIapPurchaseAdapter implements IapPurchaseAdapter {
  const DevIapPurchaseAdapter({
    required this.isNativeRelease,
    this.restoredPurchases = const [],
  });

  final bool isNativeRelease;
  final List<IapPurchase> restoredPurchases;

  void _guardNativeRelease() {
    if (isNativeRelease) {
      throw const IapUnavailableException(
        'Simulated purchases are disabled on native release',
      );
    }
  }

  @override
  Future<void> buyProduct(IapProduct product) async {
    _guardNativeRelease();
  }

  @override
  Future<void> completePurchase(IapPurchase purchase) async {
    _guardNativeRelease();
  }

  @override
  Future<List<IapPurchase>> restorePurchases() async {
    _guardNativeRelease();
    return restoredPurchases;
  }
}

class NativeIapPurchaseAdapter implements IapPurchaseAdapter {
  NativeIapPurchaseAdapter({
    store.InAppPurchase? inAppPurchase,
    this.restoreWait = const Duration(seconds: 2),
  }) : _iap = inAppPurchase ?? store.InAppPurchase.instance;

  final store.InAppPurchase _iap;
  final Duration restoreWait;
  final Map<String, store.ProductDetails> _products = {};
  final Map<String, store.PurchaseDetails> _detailsByTx = {};
  final StreamController<List<IapPurchase>> _purchaseUpdates =
      StreamController<List<IapPurchase>>.broadcast();

  StreamSubscription<List<store.PurchaseDetails>>? _subscription;
  Completer<List<IapPurchase>>? _restoreCompleter;
  Timer? _restoreTimer;
  List<IapPurchase> _restoreBuffer = [];

  Stream<List<IapPurchase>> get purchaseStream {
    _ensureListening();
    return _purchaseUpdates.stream;
  }

  Future<void> initialize() async {
    _ensureListening();
    await _ensureAvailable();
    await _queryProducts(IapProducts.all.map((p) => p.productId).toSet());
  }

  Future<void> dispose() async {
    _restoreTimer?.cancel();
    await _subscription?.cancel();
    await _purchaseUpdates.close();
  }

  @override
  Future<void> buyProduct(IapProduct product) async {
    _ensureListening();
    await _ensureAvailable();
    final details = await _productDetails(product.productId);
    final param = store.PurchaseParam(productDetails: details);
    final started = product.kind == IapProductKind.consumable
        ? await _iap.buyConsumable(purchaseParam: param)
        : await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      throw const IapException(
        IapErrorCode.unknown,
        'Purchase flow did not start',
      );
    }
  }

  @override
  Future<void> completePurchase(IapPurchase purchase) async {
    final details = _detailsByTx[purchase.transactionKey];
    if (details == null || !details.pendingCompletePurchase) return;
    await _iap.completePurchase(details);
  }

  @override
  Future<List<IapPurchase>> restorePurchases() async {
    _ensureListening();
    await _ensureAvailable();

    _restoreTimer?.cancel();
    _restoreBuffer = [];
    final completer = Completer<List<IapPurchase>>();
    _restoreCompleter = completer;
    _restoreTimer = Timer(restoreWait, _finishRestore);

    try {
      await _iap.restorePurchases();
    } catch (e) {
      _restoreTimer?.cancel();
      _restoreCompleter = null;
      _restoreBuffer = [];
      throw _mapException(e);
    }

    return completer.future;
  }

  void _ensureListening() {
    _subscription ??= _iap.purchaseStream.listen(_handleStorePurchases);
  }

  Future<void> _ensureAvailable() async {
    if (!await _iap.isAvailable()) {
      throw const IapUnavailableException();
    }
  }

  Future<store.ProductDetails> _productDetails(String productId) async {
    final cached = _products[productId];
    if (cached != null) return cached;
    await _queryProducts({productId});
    final details = _products[productId];
    if (details == null) {
      throw IapException(
        IapErrorCode.developer,
        'Missing Play product: $productId',
      );
    }
    return details;
  }

  Future<void> _queryProducts(Set<String> productIds) async {
    final response = await _iap.queryProductDetails(productIds);
    final error = response.error;
    if (error != null) throw _mapStoreError(error);
    for (final details in response.productDetails) {
      _products[details.id] = details;
    }
    if (response.notFoundIDs.isNotEmpty) {
      throw IapException(
        IapErrorCode.developer,
        'Missing Play products: ${response.notFoundIDs.join(', ')}',
      );
    }
  }

  void _handleStorePurchases(List<store.PurchaseDetails> detailsList) {
    final purchases = detailsList.map(_fromStorePurchase).toList();
    for (var i = 0; i < purchases.length; i++) {
      _detailsByTx[purchases[i].transactionKey] = detailsList[i];
    }

    if (_restoreCompleter != null &&
        detailsList.any((d) => d.status == store.PurchaseStatus.restored)) {
      _restoreBuffer.addAll(purchases);
      return;
    }

    if (purchases.isNotEmpty) _purchaseUpdates.add(purchases);
  }

  void _finishRestore() {
    final completer = _restoreCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(List<IapPurchase>.from(_restoreBuffer));
    }
    _restoreCompleter = null;
    _restoreBuffer = [];
  }

  IapPurchase _fromStorePurchase(store.PurchaseDetails details) {
    return IapPurchase(
      productId: details.productID,
      status: _mapStatus(details.status),
      transactionId: details.purchaseID ?? '',
      purchaseId: details.verificationData.serverVerificationData,
      purchaseDate: _parsePurchaseDate(details.transactionDate),
    );
  }

  IapPurchaseStatus _mapStatus(store.PurchaseStatus status) {
    switch (status) {
      case store.PurchaseStatus.purchased:
      case store.PurchaseStatus.restored:
        return IapPurchaseStatus.approved;
      case store.PurchaseStatus.pending:
        return IapPurchaseStatus.pending;
      case store.PurchaseStatus.canceled:
        return IapPurchaseStatus.cancelled;
      case store.PurchaseStatus.error:
        return IapPurchaseStatus.failed;
    }
  }

  DateTime? _parsePurchaseDate(String? value) {
    final millis = int.tryParse(value ?? '');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  IapException _mapStoreError(store.IAPError error) {
    final code = error.code.toLowerCase();
    if (code.contains('cancel')) {
      return IapException(IapErrorCode.userCancelled, error.message);
    }
    if (code.contains('network') || code.contains('service')) {
      return IapException(IapErrorCode.network, error.message);
    }
    if (code.contains('billing') || code.contains('unavailable')) {
      return IapException(IapErrorCode.billingUnavailable, error.message);
    }
    if (code.contains('developer') ||
        code.contains('not_found') ||
        code.contains('notfound')) {
      return IapException(IapErrorCode.developer, error.message);
    }
    return IapException(IapErrorCode.unknown, error.message);
  }

  IapException _mapException(Object error) {
    if (error is IapException) return error;
    if (error is store.InAppPurchaseException) {
      final code = error.code.toLowerCase();
      if (code.contains('network') || code.contains('service')) {
        return IapException(IapErrorCode.network, error.message ?? '$error');
      }
      if (code.contains('billing') || code.contains('unavailable')) {
        return IapException(
          IapErrorCode.billingUnavailable,
          error.message ?? '$error',
        );
      }
      return IapException(IapErrorCode.unknown, error.message ?? '$error');
    }
    return IapException(IapErrorCode.unknown, '$error');
  }
}

class UnavailableIapPurchaseAdapter implements IapPurchaseAdapter {
  const UnavailableIapPurchaseAdapter();

  @override
  Future<void> buyProduct(IapProduct product) {
    throw const IapUnavailableException();
  }

  @override
  Future<void> completePurchase(IapPurchase purchase) {
    throw const IapUnavailableException();
  }

  @override
  Future<List<IapPurchase>> restorePurchases() {
    throw const IapUnavailableException();
  }
}

class AdultGateChallenge {
  const AdultGateChallenge(this.left, this.right);

  final int left;
  final int right;

  int get answer => left + right;

  String get prompt => '$left + $right';

  bool accepts(String value) => int.tryParse(value.trim()) == answer;

  static AdultGateChallenge random([Random? rng]) {
    final r = rng ?? Random();
    return AdultGateChallenge(10 + r.nextInt(90), 10 + r.nextInt(90));
  }
}
