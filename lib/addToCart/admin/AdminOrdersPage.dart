import 'package:babyshophub/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatelessWidget {
  AdminOrdersPage({super.key});
  final _firestore = FirebaseFirestore.instance;

  Future<void> _setStatus(DocumentReference orderRef, String status) async {
    try {
      final data = {
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'cancelled') {
        data['cancelledByName'] = 'admin';
        data['cancelledAt'] = FieldValue.serverTimestamp();
      }

      // ✅ Update the order in admin view (main document)
      await orderRef.update(data);

      // ✅ Mirror update to user's orders collection
      final userUid = orderRef.parent.parent?.id; // Extract UID
      if (userUid != null) {
        final userOrderRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userUid)
            .collection('orders')
            .doc(orderRef.id);

        await userOrderRef.update(data);
      }

      debugPrint('✅ Order status updated for both admin and user.');
    } catch (e) {
      debugPrint('❌ Status update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _firestore.collectionGroup('orders');

    return Scaffold(
      appBar: AppBar(title: const Text('All Orders (Admin)')),
      drawer: const MyDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: orders.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: docs.map((doc) {
              final rawData = doc.data();
              if (rawData == null) {
                return Card(
                  color: Colors.red[100],
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading:
                        const Icon(Icons.error_outline, color: Colors.red),
                    title: Text('Invalid Order: ${doc.id}'),
                    subtitle: const Text(
                        'This order document is empty or invalid.'),
                  ),
                );
              }

              final d = rawData as Map<String, dynamic>;

              final userName = d['userName'] ?? 'Unknown';
              final userEmail = d['userEmail'] ?? '';
              final userPhone = d['userPhone'] ?? '';
              final userAddress = d['userAddress'] ?? '';

              final total = d['total'] ?? 0;
              final itemCount = d['itemCount'] ?? 0;
              final status = d['status'] ?? 'pending';
              final isCancelled = status == 'cancelled';
              final cancelledBy = d['cancelledByName'];

              String ownerUid = 'unknown';
              try {
                ownerUid = doc.reference.parent.parent?.id ?? 'unknown';
              } catch (e) {
                debugPrint('Owner UID fetch failed: $e');
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: isCancelled
                      ? const Icon(Icons.warning_amber_rounded,
                          color: Colors.red)
                      : const Icon(Icons.shopping_bag,
                          color: Colors.blueAccent),
                  title: Text('Order by $userName'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: $userEmail'),
                      Text('Phone: $userPhone'),
                      Text('User UID: $ownerUid'),
                      Text('Status: $status',
                          style: TextStyle(
                              color:
                                  isCancelled ? Colors.red : Colors.black)),
                      if (isCancelled)
                        Text('Cancelled by: ${cancelledBy ?? 'unknown'}',
                            style: const TextStyle(color: Colors.red)),
                      Text('Total Items: $itemCount'),
                      Text('Total Price: \$${total.toString()}'),
                      Text('Address: $userAddress'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      await _setStatus(doc.reference, value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order set to $value')),
                      );
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'pending', child: Text('Pending')),
                      PopupMenuItem(
                          value: 'processing', child: Text('Processing')),
                      PopupMenuItem(
                          value: 'completed', child: Text('Completed')),
                      PopupMenuItem(
                          value: 'cancelled', child: Text('Cancel Order')),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          AdminOrderDetailPage(orderRef: doc.reference),
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

class AdminOrderDetailPage extends StatelessWidget {
  final DocumentReference orderRef;
  const AdminOrderDetailPage({required this.orderRef, super.key});

  @override
  Widget build(BuildContext context) {
    final itemsCol = orderRef.collection('items');

    return Scaffold(
      appBar: AppBar(title: const Text('Order Items (Admin)')),
      body: StreamBuilder<QuerySnapshot>(
        stream: itemsCol.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No items in this order'));
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: docs.map((d) {
              final m = d.data() as Map<String, dynamic>? ?? {};
              return ListTile(
                leading: (m['image'] ?? '').toString().isNotEmpty
                    ? Image.network(
                        m['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(m['name'] ?? ''),
                subtitle: Text(
                  'Qty: ${m['quantity'] ?? 1}  |  Price: \$${m['price'] ?? 0}',
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
