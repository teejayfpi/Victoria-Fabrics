import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:cloud_functions/cloud_functions.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../data/mappers/place_order_payload.dart';
import '../domain/entities/cart_item.dart';
import '../domain/entities/category.dart';
import '../domain/entities/order.dart';
import '../domain/entities/product.dart';
import '../domain/entities/ticket.dart';
import '../data/datasources/mock_data_source.dart';

/// Low-level Firestore access. Prefer the repositories in
/// `lib/data/repositories/` — they add error mapping and validation.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(AppConfig.productsCollection);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(AppConfig.ordersCollection);
  CollectionReference<Map<String, dynamic>> get _tickets =>
      _db.collection(AppConfig.ticketsCollection);
  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(AppConfig.categoriesCollection);

  // ─── Products ─────────────────────────────────────────────────────

  Stream<List<Product>> productsStream() {
    return _products.snapshots().map((snap) => snap.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> addProduct(Product product) async {
    await _products.doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final data = product.toMap()..remove('createdAt');
    await _products.doc(product.id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.id, doc.data()!);
  }

  // ─── Categories ───────────────────────────────────────────────────

  Stream<List<Category>> categoriesStream() {
    return _categories
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Category.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addCategory(Category category) async {
    await _categories.doc(category.id).set({
      ...category.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(Category category) async {
    await _categories.doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }

  /// Seeds the category collection from the bundled defaults the first time
  /// the app runs against an empty database.
  Future<void> seedCategoriesIfEmpty() async {
    final markerRef = _db.collection('_meta').doc('category_seed');
    final existing = await _categories.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final marker = await markerRef.get();
    if (marker.exists) return;

    final batch = _db.batch();
    for (final category in MockDataSource.categories) {
      batch.set(_categories.doc(category.id), {
        ...category.toMap(),
        'createdAt': Timestamp.now(),
      });
    }
    batch.set(markerRef, {'seededAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  // ─── Orders ───────────────────────────────────────────────────────

  /// All orders (admin view). Bounded so a growing store does not stream the
  /// entire history to every client; paginate from the UI when needed.
  Stream<List<Map<String, dynamic>>> ordersStream({int limit = 100}) {
    return _orders
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                <String, dynamic>{...doc.data(), 'firestoreId': doc.id})
            .toList());
  }

  /// Per-user orders (customer view).
  Stream<List<Order>> userOrdersStream(String uid) {
    return _orders
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Order.fromMap(doc.id, doc.data())).toList());
  }

  /// Places an order through the `placeOrder` Cloud Function.
  ///
  /// The server owns price, stock and total integrity — the client only sends
  /// intent. [expectedTotal] is passed so the function can detect a stale cart.
  /// Returns the new order's document id.
  Future<String> createOrder({
    required List<CartItem> items,
    required double expectedTotal,
    required DeliveryType deliveryType,
    String? deliveryAddress,
    String? pickupLocation,
    required String customerName,
    required String customerPhone,
  }) async {
    if (items.isEmpty) {
      throw StateError('Cannot create an order with no items');
    }

    final callable = FirebaseFunctions.instance.httpsCallable('placeOrder');
    final response = await callable.call<Map<String, dynamic>>(
      buildPlaceOrderPayload(
        items: items,
        expectedTotal: expectedTotal,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        pickupLocation: pickupLocation,
        customerName: customerName,
        customerPhone: customerPhone,
      ),
    );

    final data = response.data;
    final orderId = data['orderId'] as String?;
    if (orderId == null) {
      throw StateError('Order was not confirmed by the server');
    }

    AppLogger.info('Order created', tag: 'firestore', context: {
      'orderId': orderId,
    });
    return orderId;
  }

  Future<void> updateOrderStatus(String firestoreId, String status) async {
    await _orders.doc(firestoreId).update({'status': status});
  }

  // ─── Support Tickets ──────────────────────────────────────────────

  Stream<List<SupportTicket>> ticketsStream({int limit = 200}) {
    return _tickets
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportTicket.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> submitTicket(SupportTicket ticket) async {
    await _tickets.doc(ticket.id).set(ticket.toMap());
  }

  Future<void> updateTicketStatus(String id, String status) async {
    await _tickets.doc(id).update({'status': status});
  }

  // ─── Seed ─────────────────────────────────────────────────────────

  /// Seeds the catalogue on a brand-new store. Idempotent: guarded by a
  /// server-side marker document so concurrent app launches cannot double-seed.
  Future<void> seedProductsIfEmpty() async {
    final markerRef = _db.collection('_meta').doc('catalogue_seed');
    final existing = await _products.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final marker = await markerRef.get();
    if (marker.exists) return;

    final batch = _db.batch();
    for (final product in MockDataSource.products) {
      final data = product.toMap()..['createdAt'] = Timestamp.now();
      batch.set(_products.doc(product.id), data);
    }
    batch.set(markerRef, {'seededAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }
}
