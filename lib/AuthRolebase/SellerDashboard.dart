// ✅ Import Packages
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 Firestore import
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'SignIn.dart';
import 'package:babyshophub/drawer.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  int _products = 0;
  int _users = 0;
  int _orders = 0;
  bool _isDark = false;

  // --- Image List for Slider ---
  final List<String> imageUrls = [
    "https://images.unsplash.com/photo-1556761175-4b46a572b786",
    "https://images.unsplash.com/photo-1506765515384-028b60a970df",
    "https://images.unsplash.com/photo-1519389950473-47ba0277781c",
    "https://images.unsplash.com/photo-1521791055366-0d553872125f",
    "https://images.unsplash.com/photo-1519125323398-675f0ddb6308",
    "https://images.unsplash.com/photo-1521737604893-d14cc237f11d",
  ];

  // --- Dummy Product List ---
  final List<Map<String, String>> products = [
    {
      "name": "Wireless Headphones",
      "price": "59.99",
      "image": "https://images.unsplash.com/photo-1517336714731-489689fd1ca8"
    },
    {
      "name": "Smart Watch",
      "price": "129.00",
      "image": "https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b"
    },
    {
      "name": "Gaming Laptop",
      "price": "999.99",
      "image": "https://images.unsplash.com/photo-1517336714731-489689fd1ca8"
    },
    {
      "name": "Bluetooth Speaker",
      "price": "79.99",
      "image": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e"
    },
  ];

  // ✅ Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignIn()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully")),
    );
  }

  @override
  void initState() {
    super.initState();
    _startCounting();
  }

  void _startCounting() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_products < 120) _products++;
        if (_users < 45) _users++;
        if (_orders < 78) _orders++;
      });
      if (_products >= 120 && _users >= 45 && _orders >= 78) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDark ? const Color(0xFF121212) : Colors.grey[100];
    final cardColor = _isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = _isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Seller Dashboard"),
        backgroundColor: _isDark ? Colors.grey[900] : Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(
              _isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: Colors.white,
            ),
            tooltip: _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              setState(() {
                _isDark = !_isDark;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
drawer: MyDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ✅ Image Slider
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                autoPlay: true,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
              items: imageUrls.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                );
              }).toList(),
            ),

            // ✅ Slider Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: imageUrls.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Colors.blueAccent
                        : Colors.grey.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ✅ Counters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 600;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCounterCard(Icons.shopping_bag, "Products", _products, textColor, cardColor),
                      _buildCounterCard(Icons.people, "Users", _users, textColor, cardColor),
                      _buildCounterCard(Icons.receipt_long, "Orders", _orders, textColor, cardColor),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Products
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Products",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Product Grid (No Overflow)
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = products[index];
                return _buildProductCard(item, textColor, cardColor);
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ✅ Counter Card
  Widget _buildCounterCard(IconData icon, String title, int count, Color textColor, Color cardColor) {
    return Card(
      color: cardColor,
      elevation: 4,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 200,
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 18, color: textColor)),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
              duration: const Duration(milliseconds: 400),
              child: Text(count.toString()),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Product Card + Firestore Add-to-Cart
  Widget _buildProductCard(Map<String, String> product, Color textColor, Color cardColor) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product["image"]!,
                height: 50,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Text(product["name"]!,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
            Text("\$${product["price"]}",
                style: const TextStyle(fontSize: 14, color: Colors.blueAccent)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await _addToCart(product);
              },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text("Add to Cart", style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Firestore Function: Add Product to Cart
  Future<void> _addToCart(Map<String, String> product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login first!")),
        );
        return;
      }

      final cartRef = _firestore
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(product["name"]);

      final doc = await cartRef.get();

      if (doc.exists) {
        // 🔹 If product already exists, show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${product["name"]} already in cart!")),
        );
      } else {
        // 🔹 Otherwise add product
        await cartRef.set({
          "name": product["name"],
          "price": double.parse(product["price"]!),
          "image": product["image"],
          "addedAt": Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${product["name"]} added to cart!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding to cart: $e")),
      );
    }
  }
}
