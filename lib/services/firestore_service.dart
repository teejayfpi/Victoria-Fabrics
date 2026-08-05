import 'package:cloud_firestore/cloud_firestore.dart';
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

  Stream<List<Map<String, dynamic>>> ordersStream() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => <String, dynamic>{...doc.data(), 'firestoreId': doc.id})
            .toList());
  }

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
        .map((snap) =>
            snap.docs.map((doc) => SupportTicket.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> submitTicket(SupportTicket ticket) async {
    await _db.collection('tickets').doc(ticket.id).set(ticket.toMap());
  }

  Future<void> updateTicketStatus(String id, String status) async {
    await _db.collection('tickets').doc(id).update({'status': status});
  }

  // ─── Seed ─────────────────────────────────────────────────────────

  /// Seeds Firestore with mock products the very first time the app runs.
  Future<void> seedProductsIfEmpty() async {
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
}
