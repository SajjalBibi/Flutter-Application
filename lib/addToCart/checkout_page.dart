// checkout_page.dart
// ------------------
// Checkout page: moves order to both user and global orders collection.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:babyshophub/drawer.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _phoneC = TextEditingController();
  final TextEditingController _addressC = TextEditingController();

  User? get user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    final u = _auth.currentUser;
    if (u != null) {
      _nameC.text = u.displayName ?? '';
      _phoneC.text = u.phoneNumber ?? '';
      _addressC.text = '';
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    super.dispose();
  }

  double _calculateTotal(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final price = (data['price'] is num)
          ? (data['price'] as num).toDouble()
          : double.tryParse(data['price'].toString()) ?? 0.0;
      final qty = (data['quantity'] is num)
          ? (data['quantity'] as num).toInt()
          : int.tryParse(data['quantity'].toString()) ?? 1;
      total += price * qty;
    }
    return total;
  }

  Future<void> _placeOrder(List<QueryDocumentSnapshot> cartDocs) async {
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login')));
      return;
    }
    if (cartDocs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    try {
      final batch = _firestore.batch();
      final userOrdersRef =
          _firestore.collection('users').doc(user!.uid).collection('orders');
      final orderDocRef = userOrdersRef.doc();
      final globalOrderRef =
          _firestore.collection('orders').doc(orderDocRef.id);

      double total = _calculateTotal(cartDocs);

      final orderData = {
        'orderedAt': FieldValue.serverTimestamp(),
        'total': total,
        'itemCount': cartDocs.length,
        'userName': _nameC.text,
        'userPhone': _phoneC.text,
        'userAddress': _addressC.text,
        'userEmail': user!.email ?? '',
        'status': 'pending',
        'userId': user!.uid,
      };

      // set order meta
      batch.set(orderDocRef, orderData);
      batch.set(globalOrderRef, orderData);

      // items
      for (var doc in cartDocs) {
        final d = doc.data() as Map<String, dynamic>;
        final userItemRef = orderDocRef.collection('items').doc(doc.id);
        final adminItemRef = globalOrderRef.collection('items').doc(doc.id);
        final itemData = {
          'productId': doc.id,
          'name': d['name'],
          'price': d['price'],
          'image': d['image'] ?? '',
          'quantity': d['quantity'] ?? 1,
        };

        batch.set(userItemRef, itemData);
        batch.set(adminItemRef, itemData);

        // delete from cart
        final cartRef = _firestore
            .collection('users')
            .doc(user!.uid)
            .collection('cart')
            .doc(doc.id);
        batch.delete(cartRef);
      }

      await batch.commit();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order placed'),
          content: Text(
              'Your order has been placed successfully. Total: \$${total.toStringAsFixed(2)}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
    }
  }

  Future<void> _changeQuantity(String productId, int delta) async {
    if (user == null) return;
    final docRef = _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(productId);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final cur = (snap.data()!['quantity'] ?? 0) as num;
        final newQty = cur.toInt() + delta;
        if (newQty <= 0) {
          tx.delete(docRef);
        } else {
          tx.update(docRef, {'quantity': newQty});
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Please login')),
      );
    }

    final cartRef =
        _firestore.collection('users').doc(user!.uid).collection('cart');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: MyDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.orderBy('addedAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          final total = _calculateTotal(docs);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  docs.isEmpty
                      ? const Center(child: Text('Your cart is empty'))
                      : Column(
                          children: docs.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            final price = (d['price'] is num)
                                ? (d['price'] as num).toDouble()
                                : double.tryParse(d['price'].toString()) ?? 0.0;
                            final qty = (d['quantity'] is num)
                                ? (d['quantity'] as num).toInt()
                                : int.tryParse(d['quantity'].toString()) ?? 1;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: d['image'] != null &&
                                        d['image'].toString().isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          d['image'],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300]),
                                title: Text(d['name'] ?? ''),
                                subtitle: Text(
                                    '\$${price.toStringAsFixed(2)} x $qty = \$${(price * qty).toStringAsFixed(2)}'),
                                trailing: SizedBox(
                                  width: 120,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _changeQuantity(doc.id, -1),
                                      ),
                                      Text(qty.toString()),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.green),
                                        onPressed: () =>
                                            _changeQuantity(doc.id, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameC,
                          decoration:
                              const InputDecoration(labelText: 'Full name'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter name'
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneC,
                          decoration:
                              const InputDecoration(labelText: 'Phone'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter phone'
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressC,
                          decoration: const InputDecoration(
                              labelText: 'Delivery address'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter address'
                                  : null,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _placeOrder(docs),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child:
                              Text('Place Order', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
