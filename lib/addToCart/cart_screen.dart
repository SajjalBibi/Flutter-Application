import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'checkout_page.dart';
import 'package:babyshophub/drawer.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  Future<void> _changeQuantity(String productId, int delta) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login')));
      return;
    }
    final docRef = _firestore.collection('users').doc(user!.uid).collection('cart').doc(productId);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final current = (snap.data()!['quantity'] ?? 0) as num;
        final newQty = current.toInt() + delta;
        if (newQty <= 0) tx.delete(docRef);
        else tx.update(docRef, {'quantity': newQty});
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteItem(String productId) async {
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user!.uid).collection('cart').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item removed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  double _calculateTotal(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final price = (data['price'] is num) ? (data['price'] as num).toDouble() : double.tryParse(data['price'].toString()) ?? 0.0;
      final qty = (data['quantity'] is num) ? (data['quantity'] as num).toInt() : int.tryParse(data['quantity'].toString()) ?? 1;
      total += price * qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: Text('Please login to see your cart')),
      );
    }

    final cartRef = _firestore.collection('users').doc(user!.uid).collection('cart');

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart'), backgroundColor: Colors.blueAccent),
      drawer: MyDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.orderBy('addedAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Your cart is empty'));

          final total = _calculateTotal(docs);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final price = (data['price'] is num) ? (data['price'] as num).toDouble() : double.tryParse(data['price'].toString()) ?? 0.0;
                    final qty = (data['quantity'] is num) ? (data['quantity'] as num).toInt() : int.tryParse(data['quantity'].toString()) ?? 1;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data['image'] != null && data['image'].toString().isNotEmpty
                              ? Image.network(data['image'], width: 60, height: 60, fit: BoxFit.cover)
                              : Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.image)),
                        ),
                        title: Text(data['name'] ?? ''),
                        subtitle: Text('\$${price.toStringAsFixed(2)} x $qty = \$${(price * qty).toStringAsFixed(2)}', style: const TextStyle(color: Colors.blueAccent)),
                        trailing: SizedBox(
                          width: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _changeQuantity(doc.id, -1)),
                              Text(qty.toString(), style: const TextStyle(fontSize: 16)),
                              IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => _changeQuantity(doc.id, 1)),
                              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteItem(doc.id)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Total + Checkout
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage()));
                      },
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
