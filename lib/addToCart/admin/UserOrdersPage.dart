import 'package:babyshophub/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});
  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _withinOneHour(Timestamp? ts) {
    if (ts == null) return false;
    final ordered = ts.toDate();
    final diff = DateTime.now().difference(ordered);
    return diff.inMinutes < 60;
  }

  Future<void> _cancelOrder(String orderId) async {
    final uid = _auth.currentUser!.uid;
    final orderRef = _firestore.collection('users').doc(uid).collection('orders').doc(orderId);

    try {
      await orderRef.update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': uid,
        'cancelledByName': 'user',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled by you')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    }
  }

  Future<void> _editOrderMeta(String orderId) async {
    final uid = _auth.currentUser!.uid;
    final orderRef = _firestore.collection('users').doc(uid).collection('orders').doc(orderId);

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final doc = await orderRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['userName'] ?? '';
      phoneController.text = data['userPhone'] ?? '';
      addressController.text = data['userAddress'] ?? '';
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit order details'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await orderRef.update({
                'userName': nameController.text,
                'userPhone': phoneController.text,
                'userAddress': addressController.text,
                'lastEditedAt': FieldValue.serverTimestamp(),
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please login to see your orders'));

    final ordersRef = _firestore.collection('users').doc(user.uid).collection('orders').orderBy('orderedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      drawer: const MyDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No orders yet'));

          return ListView(
            padding: const EdgeInsets.all(12),
            children: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final orderedAt = d['orderedAt'] as Timestamp?;
              final status = d['status'] ?? 'pending';
              final cancelledBy = d['cancelledByName'];
              final allowedEdit = _withinOneHour(orderedAt) && status != 'cancelled' && status != 'completed';
              final isCancelled = status == 'cancelled';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: isCancelled
                      ? const Icon(Icons.warning_amber_rounded, color: Colors.red)
                      : const Icon(Icons.shopping_bag, color: Colors.blueAccent),
                  title: Text('Order ID: ${doc.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $status',
                          style: TextStyle(color: isCancelled ? Colors.red : Colors.black)),
                      if (isCancelled)
                        Text(
                          'Cancelled by: ${cancelledBy ?? 'unknown'}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (orderedAt != null)
                        Text('Ordered: ${orderedAt.toDate()}'),
                      Text('Total: \$${(d['total'] ?? 0).toString()}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    children: [
                      if (allowedEdit)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editOrderMeta(doc.id),
                        ),
                      if (allowedEdit)
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cancel order'),
                                content: const Text('Are you sure you want to cancel this order?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
                                ],
                              ),
                            );
                            if (ok == true) _cancelOrder(doc.id);
                          },
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => OrderDetailsPage(orderDoc: doc.reference),
                    ));
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final DocumentReference orderDoc;
  const OrderDetailsPage({required this.orderDoc, super.key});

  @override
  Widget build(BuildContext context) {
    final itemsCol = orderDoc.collection('items');
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: StreamBuilder<QuerySnapshot>(
        stream: itemsCol.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No items'));
          return ListView(
            children: docs.map((d) {
              final m = d.data() as Map<String, dynamic>;
              return ListTile(
                leading: (m['image'] ?? '').toString().isNotEmpty
                    ? Image.network(m['image'], width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported),
                title: Text(m['name'] ?? ''),
                subtitle: Text('Qty: ${m['quantity'] ?? 1}  Price: \$${m['price'] ?? 0}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
