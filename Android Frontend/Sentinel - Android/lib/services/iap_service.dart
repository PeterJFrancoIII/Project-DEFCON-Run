import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();

  factory IAPService() {
    return _instance;
  }

  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = false;
  List<ProductDetails> _products = [];

  // Donation Tiers
  static const Map<String, String> _productIds = {
    '0.99': 'Sentinel_Donation_Button_0001',
    '2.99': 'Sentinel_Donation_Button_0003',
    '4.99':
        'Sentinel_Donation_Button_0005', // Corrected from user prompt implication
    '9.99': 'Sentinel_Donation_Button_0010',
    '19.99': 'Sentinel_Donation_Button_0020',
  };

  static Set<String> get _kIds => _productIds.values.toSet();

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (_available) {
      // Listen to purchase updates
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen((purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      }, onDone: () {
        _subscription?.cancel();
      }, onError: (error) {
        debugPrint("[IAP] Purchase Stream Error: $error");
      });

      // Load products
      await _loadProducts();
    } else {
      debugPrint("[IAP] Store not available");
    }
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("[IAP] Products not found: ${response.notFoundIDs}");
    }
    _products = response.productDetails;
    debugPrint("[IAP] Loaded ${_products.length} products");
  }

  Future<bool> purchaseDonation(String productId) async {
    if (!_available) {
      debugPrint("[IAP] Store unavailable, cannot purchase.");
      return false;
    }

    if (_products.isEmpty) {
      debugPrint("[IAP] No products loaded to purchase.");
      return false;
    }

    // Find the donation product, strictly
    ProductDetails? productToBuy;
    try {
      productToBuy = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => _products
            .firstWhere((p) => p.id == productId), // Retry strict match
      );
    } catch (_) {
      debugPrint("[IAP] Product $productId not found in loaded products.");
      return false;
    }

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productToBuy);

    try {
      await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
      return true;
    } catch (e) {
      debugPrint("[IAP] Buy error: $e");
      return false;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      debugPrint("[IAP] Purchase Pending...");
    } else {
      if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("[IAP] Purchase Error: ${purchaseDetails.error}");
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint("[IAP] Purchased successfully!");
        // deliverProduct(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
