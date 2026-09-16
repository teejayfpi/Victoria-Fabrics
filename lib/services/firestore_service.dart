import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../domain/entities/category.dart';
import '../domain/entities/order.dart';
import '../domain/entities/product.dart';
import '../domain/entities/ticket.dart';
import '../data/datasources/mock_data_source.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ─── Products ─────────────────────────────────────────────────────

  Stream<List<Product>> productsStream() {
    return _db
        .collection('products')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final data = product.toMap()..remove('createdAt');
    await _db.collection('products').doc(product.id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.id, doc.data()!);
  }

  // ─── Orders ───────────────────────────────────────────────────────

  /// All orders (admin view)
  Stream<List<Map<String, dynamic>>> ordersStream() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                <String, dynamic>{...doc.data(), 'firestoreId': doc.id})
            .toList());
  }

  /// Per-user orders (customer view)
  Stream<List<Order>> userOrdersStream(String uid) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Order.fromMap(doc.id, doc.data())).toList());
  }

  /// Create an order and return its Firestore document ID
  Future<String> createOrder(Map<String, dynamic> orderData) async {
    orderData['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _db.collection('orders').add(orderData);
    return ref.id;
  }

  Future<void> updateOrderStatus(String firestoreId, String status) async {
    await _db
        .collection('orders')
        .doc(firestoreId)
        .update({'status': status});
  }

  // ─── Support Tickets ──────────────────────────────────────────────

  Stream<List<SupportTicket>> ticketsStream() {
    return _db
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportTicket.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> submitTicket(SupportTicket ticket) async {
    await _db.collection('tickets').doc(ticket.id).set(ticket.toMap());
  }

  Future<void> updateTicketStatus(String id, String status) async {
    await _db.collection('tickets').doc(id).update({'status': status});
  }

  // ─── Categories ───────────────────────────────────────────────────

  Stream<List<Category>> categoriesStream() {
    return _db.collection('categories').snapshots().map((snap) {
      final categories =
          snap.docs.map((d) => Category.fromMap(d.id, d.data())).toList();
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    });
  }

  Future<void> addCategory(Category category) async {
    await _db.collection('categories').doc(category.id).set(category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    await _db
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  // ─── Users ────────────────────────────────────────────────────────

  /// Role recorded in the user's Firestore document, or null when the user
  /// has no document or no role set. Mirrors the `isAdmin()` helper in
  /// firestore.rules so client and server agree on who is an admin.
  Future<String?> getUserRole(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data()?['role'] as String?;
  }

  /// Creates the user document on first sign-in. The `role` field is
  /// deliberately omitted — customers must never be able to self-promote,
  /// and firestore.rules rejects a create that includes it.
  Future<void> ensureUserDocument({
    required String uid,
    required String name,
    String? email,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'name': name,
      if (email != null) 'email': email,
      'updatedAt': Timestamp.now(),
    });
  }

  // ─── Seed ──────────────────────────────────────────────────────────

  Future<void> seedProductsIfEmpty() async {
    await _seedCategoriesIfEmpty();

    final snap = await _db.collection('products').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final product in MockDataSource.products) {
      final data = product.toMap()
        ..['createdAt'] = Timestamp.now();
      batch.set(_db.collection('products').doc(product.id), data);
    }
    await batch.commit();
  }

  Future<void> _seedCategoriesIfEmpty() async {
    final snap = await _db.collection('categories').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final category in MockDataSource.categories) {
      batch.set(
        _db.collection('categories').doc(category.id),
        category.toMap(),
      );
    }
    await batch.commit();
  }
}
