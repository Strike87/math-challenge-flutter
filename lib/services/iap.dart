import 'dart:math';

enum IapProductKind { consumable, nonConsumable }

enum IapPurchaseStatus { approved, pending, failed, cancelled }

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
  Future<void> restorePurchases();
}

class IapUnavailableException implements Exception {
  const IapUnavailableException([this.message = 'IAP adapter unavailable']);

  final String message;

  @override
  String toString() => message;
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
  Future<void> restorePurchases() {
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
