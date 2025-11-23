import 'dart:async';
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:babyshophub/addToCart/cart_screen.dart';
import 'package:babyshophub/drawer.dart';
import 'package:babyshophub/app_colors.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';


// ✅ Shared Add to Cart function
Future<void> addToCart({
  required BuildContext context,
  required String productId,
  required Map<String, dynamic> productData,
  int qty = 1,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login to add to cart')),
    );
    return;
  }

  final cartDoc = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('cart')
      .doc(productId);

  try {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(cartDoc);
      if (snap.exists) {
        final cur = (snap.data()!['quantity'] ?? 0) as num;
        tx.update(cartDoc, {
          'quantity': cur.toInt() + qty,
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(cartDoc, {
          'name': productData['name'] ?? '',
          'price': productData['price'] ?? 0,
          'image': productData['image'] ?? '',
          'quantity': qty,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Add to cart failed: $e')));
  }
}


class HomePageAnimated extends StatefulWidget {
  const HomePageAnimated({super.key});

  @override
  State<HomePageAnimated> createState() => _HomePageAnimatedState();
}

class _HomePageAnimatedState extends State<HomePageAnimated> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref("categories");
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _cartTotalQty = 0;
  StreamSubscription<QuerySnapshot>? _cartSub;

  String? _selectedCategoryName;
  double _selectedMin = 0;
  double _selectedMax = 0;

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
        if (mounted) {
          setState(() {
            _cartTotalQty = total;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() => _cartTotalQty = 0);
      }
    }
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    super.dispose();
  }

  // 🎥 Video Slider
  Widget _buildVideoSlider() {
    final List<Map<String, String>> videoData = [
      {"url": "assets/paying.mp4", "text": "Explore New Arrivals"},
      {"url": "assets/toys.mp4", "text": "Joyful Toys for Everyone"},
      {"url": "assets/6953294-hd_1920_1080_25fps.mp4", "text": "Up to 50% OFF!"},
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 350.0,
        autoPlay: true,
        viewportFraction: 1.0,
        autoPlayInterval: const Duration(seconds: 10),
      ),
      items: videoData.map((data) {
        return VideoPlayerItem(
          key: ValueKey(data['url']!),
          videoUrl: data['url']!,
          text: data['text']!,
          isAsset: true,
        );
      }).toList(),
    );
  }

  // 🧸 Categories
  Widget _buildCategoryList() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No categories found"));

          final categories = snapshot.data!.docs;
          final totalItems = categories.length + 1;

          return CarouselSlider.builder(
            itemCount: totalItems,
            options: CarouselOptions(
              height: 100,
              viewportFraction: 0.10,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              enableInfiniteScroll: true,
            ),
            itemBuilder: (context, index, realIndex) {
              if (index == 0) {
                bool isSelected = _selectedCategoryName == null;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryName = null),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isSelected ? AppColors.babyPink : Colors.grey[300],
                        child: Icon(Icons.apps, color: isSelected ? Colors.black : Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text("All",
                          style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.babyPink : Colors.black)),
                    ],
                  ),
                );
              }

              final categoryDoc = categories[index - 1];
              final category = categoryDoc.data() as Map<String, dynamic>;
              final name = category['name'] ?? 'No Name';
              final imageBase64 = category['Image'] as String?;
              bool isSelected = _selectedCategoryName == name;

              Widget imageWidget;
              if (imageBase64 != null && imageBase64.isNotEmpty) {
                try {
                  imageWidget = ClipOval(
                    child: Image.memory(base64Decode(imageBase64),
                        width: 60, height: 60, fit: BoxFit.cover),
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
                        border: isSelected ? Border.all(color: AppColors.babyPink, width: 2) : null,
                      ),
                      child: CircleAvatar(radius: 30, backgroundColor: Colors.grey[200], child: imageWidget),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.babyPink : Colors.black),
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

  // 🩵 Product Section
  Widget _buildProductSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return const Center(child: Text('No products found'));
          }

          final map = Map<String, dynamic>.from(snap.data!.snapshot.value as Map<dynamic, dynamic>);
          var products = map.entries
              .map((e) => MapEntry(e.key, Map<String, dynamic>.from(e.value)))
              .toList();

          if (_selectedCategoryName != null) {
            products = products.where((p) {
              final categoryName = p.value['category'] ?? '';
              return categoryName == _selectedCategoryName;
            }).toList();
          }

          if (products.isEmpty) {
            return const Center(child: Text('No products found for this category'));
          }

          final prices = products.map((p) {
            return (p.value['price'] is num)
                ? (p.value['price'] as num).toDouble()
                : double.tryParse((p.value['price'] ?? '').toString()) ?? 0.0;
          }).toList();

          double minPrice = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : 0;
          double maxPrice = prices.isNotEmpty ? prices.reduce((a, b) => a > b ? a : b) : 1000;

          if (_selectedMin == 0 && _selectedMax == 0 && prices.isNotEmpty) {
            _selectedMin = minPrice;
            _selectedMax = maxPrice;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Featured Products", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (prices.isNotEmpty && maxPrice > minPrice)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Filter by Price Range", style: TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: RangeValues(_selectedMin, _selectedMax),
                      min: minPrice,
                      max: maxPrice,
                      divisions: (maxPrice - minPrice).toInt() < 10 ? null : 10,
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

              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.99,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final entry = filteredProducts[index];
                  final product = entry.value;

                  final name = product['name'] ?? 'No name';
                  final price = (product['price'] is num)
                      ? (product['price'] as num).toDouble()
                      : double.tryParse((product['price'] ?? '').toString()) ?? 0.0;

                  Widget imageWidget;
                  if (product.containsKey('ImageBase64') &&
                      (product['ImageBase64'] ?? '').toString().isNotEmpty) {
                    try {
                      final bytes = base64Decode(product['ImageBase64']);
                      imageWidget = Image.memory(bytes,
                          width: double.infinity, height: 250, fit: BoxFit.cover);
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

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: imageWidget),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('\$${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('Add to Cart'),
                                  onPressed: () => addToCart(
                                    context: context,
                                    productId: entry.key,
                                    productData: {
                                      'name': name,
                                      'price': price,
                                      'image': product['image'] ?? '',
                                    },
                                    qty: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // 📷 Gallery Section
  Widget _buildGallerySection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Our Happy Moments",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('galleryItems').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No items in gallery."));
              }

              final items = snapshot.data!.docs;

              return StaggeredGrid.count(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(items.length, (index) {
                  final doc = items[index];
                  final imageUrl = doc['imageUrl'] as String;
                  final crossAxisCellCount =
                      (index % 5 == 0 || index % 5 == 3) ? 2 : 1;
                  final mainAxisCellCount =
                      (index % 5 == 0 || index % 5 == 3) ? 2 : 1;

                  return StaggeredGridTile.count(
                    crossAxisCellCount: crossAxisCellCount,
                    mainAxisCellCount: mainAxisCellCount,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GalleryDetailPage(imageUrl: imageUrl),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🌈 Hero Section
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 83, 174, 210), Color.fromARGB(255, 224, 139, 193)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Discover the Joy of Shopping for Your Little Ones 💕",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  "Find adorable clothes, toys, and more — crafted with love and care.",
                  style: TextStyle(color: Colors.white, fontSize: 26),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Image(
            image: AssetImage('assets/logo.png'),
            width: 605,
            height: 320,
            fit: BoxFit.fitWidth,
          ),
        ],
      ),
    );
  }

  // 🏗️ Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavender,
      appBar: AppBar(
        backgroundColor: AppColors.babyPink,
        title: const Text("Welcome to BabyShop"),
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
      drawer: const MyDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildVideoSlider()),
          SliverToBoxAdapter(child: _buildCategoryList()),
          const SliverToBoxAdapter(
              child: Divider(thickness: 2, indent: 20, endIndent: 20)),
          SliverToBoxAdapter(child: _buildProductSection()), // ✅ Added here
          SliverToBoxAdapter(child: _buildGallerySection()),
          SliverToBoxAdapter(child: _buildHeroSection()),
        ],
      ),
    );
  }
}

// 🎬 Video Player Widget
class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final String text;
  final bool isAsset;

  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.text,
    this.isAsset = false,
  });

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.isAsset
        ? VideoPlayerController.asset(widget.videoUrl)
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.setLooping(true);
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        else
          const Center(child: CircularProgressIndicator()),
        Container(color: Colors.black.withOpacity(0.3)),
        AnimatedTextKit(
          repeatForever: true,
          animatedTexts: [
            FadeAnimatedText(
              widget.text,
              duration: const Duration(seconds: 4),
              textStyle: const TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 8, color: Colors.black, offset: Offset(2, 2))
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 🖼️ Gallery Detail View
class GalleryDetailPage extends StatelessWidget {
  final String imageUrl;
  const GalleryDetailPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: PhotoView(imageProvider: NetworkImage(imageUrl)),
      ),
    );
  }
}
