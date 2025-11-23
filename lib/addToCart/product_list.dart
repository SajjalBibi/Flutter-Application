import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// NAYA IMPORT
import 'package:carousel_slider/carousel_slider.dart';
import 'cart_screen.dart';
import 'package:babyshophub/drawer.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref("categories");
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _cartTotalQty = 0;
  StreamSubscription<QuerySnapshot>? _cartSub;

  double _minPrice = 0;
  double _maxPrice = 1000;
  double _selectedMin = 0;
  double _selectedMax = 1000;

  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _listenCart();
  }

  void _listenCart() {
    _cartSub?.cancel();
    final user = _auth.currentUser;
    if (user != null) {
      _cartSub = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots()
          .listen((snap) {
        int total = 0;
        for (var d in snap.docs) {
          final q = (d.data()['quantity'] ?? 0) as num;
          total += q.toInt();
        }
        setState(() {
          _cartTotalQty = total;
        });
      });
    } else {
      setState(() => _cartTotalQty = 0);
    }
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    super.dispose();
  }

  Future<void> _addToCart({
    required String productId,
    required String name,
    required double price,
    required String image,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Login required'),
          content: const Text('Please login before adding items to cart.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(productId);

    try {
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        if (snapshot.exists) {
          final current = (snapshot.data()!['quantity'] ?? 0) as num;
          tx.update(docRef, {'quantity': current.toInt() + 1});
        } else {
          tx.set(docRef, {
            'productId': productId,
            'name': name,
            'price': price,
            'image': image,
            'quantity': 1,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$name added to cart')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Add to cart failed: $e')));
    }
  }

  Widget _buildProductCard({
    required String id,
    required Map<String, dynamic> product,
    required double cardWidth,
    required Color textColor,
  }) {
    Widget imageWidget;
    if (product.containsKey('ImageBase64') &&
        (product['ImageBase64'] ?? '').toString().isNotEmpty) {
      try {
        final bytes = base64Decode(product['ImageBase64']);
        imageWidget = Image.memory(bytes,
            width: double.infinity, height: 120, fit: BoxFit.cover);
      } catch (e) {
        imageWidget = Container(
          height: 120,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      }
    } else if (product.containsKey('image') &&
        (product['image'] ?? '').toString().isNotEmpty) {
      imageWidget = Image.network(product['image'],
          width: double.infinity, height: 120, fit: BoxFit.cover);
    } else {
      imageWidget = Container(
        height: 120,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image, size: 40)),
      );
    }

    final name = product['name'] ?? 'No name';
    final price = (product['price'] is num)
        ? (product['price'] as num).toDouble()
        : double.tryParse((product['price'] ?? '').toString()) ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageWidget),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.blueAccent)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Cart'),
                      onPressed: () => _addToCart(
                          productId: id,
                          name: name,
                          price: price,
                          image: product['image'] ?? ''),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Animated Carousel Category List
  Widget _buildCategoryList() {
    return Container(
      height: 120, // Thora sa height barha diya taake kat na jaye
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No categories found"));
          }

          final categories = snapshot.data!.docs;
          final totalItems = categories.length + 1; // +1 for "All" option

          return CarouselSlider.builder(
            itemCount: totalItems,
            options: CarouselOptions(
              height: 100, // Items ki height
              viewportFraction: 0.25, // Ek screen par kitne items dikhein (0.25 = 4 items)
              enableInfiniteScroll: true, // Ghoomta rahe
              autoPlay: true, // Khud chalta rahe
              autoPlayInterval: const Duration(seconds: 3), // Har 3 second baad move ho
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: false, // Beech wala item bara na ho (flat list look)
              padEnds: false, 
            ),
            itemBuilder: (context, index, realIndex) {
              if (index == 0) {
                // "All" Button
                bool isSelected = _selectedCategoryName == null;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryName = null),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isSelected ? Colors.amberAccent : Colors.grey[300],
                        child: Icon(Icons.apps, color: isSelected ? Colors.black : Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text("All", style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.amberAccent : null)),
                    ],
                  ),
                );
              }

              // Actual Category Items
              final categoryDoc = categories[index - 1];
              final category = categoryDoc.data() as Map<String, dynamic>;
              final name = category['name'] ?? 'No Name';
              final imageBase64 = category['Image'] as String?;
              bool isSelected = _selectedCategoryName == name;

              Widget imageWidget;
              if (imageBase64 != null && imageBase64.isNotEmpty) {
                try {
                  imageWidget = ClipOval(
                    child: Image.memory(base64Decode(imageBase64), width: 60, height: 60, fit: BoxFit.cover),
                  );
                } catch (e) {
                  imageWidget = const Icon(Icons.error, size: 30);
                }
              } else {
                imageWidget = const Icon(Icons.image, size: 30);
              }

              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryName = name),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.amberAccent, width: 2) : null,
                      ),
                      child: CircleAvatar(radius: 30, backgroundColor: Colors.grey[200], child: imageWidget),
                    ),
                    const SizedBox(height: 8),
                    Text(name, 
                      style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.amberAccent : null),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen()));
                },
              ),
              if (_cartTotalQty > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_cartTotalQty',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: MyDrawer(),
    //drawer add hoga yha
      body: Column(
        children: [
          // Animated Category List
          _buildCategoryList(),

          // Product List
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: ref.onValue,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.snapshot.value == null) {
                  return const Center(child: Text('No products found'));
                }

                final map = Map<String, dynamic>.from(
                    snap.data!.snapshot.value as Map<dynamic, dynamic>);
                var products = map.entries
                    .map((e) => MapEntry(e.key, Map<String, dynamic>.from(e.value)))
                    .toList();

                // Filter by Category
                if (_selectedCategoryName != null) {
                  products = products.where((p) {
                    final categoryName = p.value['category'] ?? '';
                    return categoryName == _selectedCategoryName;
                  }).toList();
                }

                // Price Filter Logic
                final prices = products.map((p) => (p.value['price'] is num)
                        ? (p.value['price'] as num).toDouble()
                        : double.tryParse((p.value['price'] ?? '').toString()) ?? 0.0).toList();
                if (prices.isNotEmpty) {
                  final minP = prices.reduce((a, b) => a < b ? a : b);
                  final maxP = prices.reduce((a, b) => a > b ? a : b);
                  if (_minPrice != minP || _maxPrice != maxP) {
                    Future.microtask(() {
                      if (mounted) {
                        setState(() {
                          _minPrice = minP;
                          _maxPrice = maxP;
                          _selectedMin = minP;
                          _selectedMax = maxP;
                        });
                      }
                    });
                  }
                }

                final filteredProducts = products.where((p) {
                  final price = (p.value['price'] is num)
                      ? (p.value['price'] as num).toDouble()
                      : double.tryParse((p.value['price'] ?? '').toString()) ?? 0.0;
                  return price >= _selectedMin && price <= _selectedMax;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('No products found for this filter'));
                }

                return Column(
                  children: [
                    // Price Range Filter
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text("Filter by Price Range", style: TextStyle(fontWeight: FontWeight.bold)),
                          if(prices.isNotEmpty && _maxPrice > _minPrice)
                          RangeSlider(
                            values: RangeValues(_selectedMin, _selectedMax),
                            min: _minPrice,
                            max: _maxPrice,
                            divisions: (_maxPrice - _minPrice).toInt() < 10 ? null : 10,
                            labels: RangeLabels(
                              "\$${_selectedMin.toStringAsFixed(0)}",
                              "\$${_selectedMax.toStringAsFixed(0)}",
                            ),
                            onChanged: (values) {
                              setState(() {
                                _selectedMin = values.start;
                                _selectedMax = values.end;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Product Grid
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          int crossAxisCount = (width / 200).floor().clamp(1, 5);
                          final cardWidth = (width - ((crossAxisCount + 1) * 12)) / crossAxisCount;

                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: (cardWidth / 260),
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final entry = filteredProducts[index];
                                return _buildProductCard(
                                  id: entry.key,
                                  product: entry.value,
                                  cardWidth: cardWidth,
                                  textColor: textColor,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}