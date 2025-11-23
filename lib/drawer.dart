import 'package:flutter/material.dart';

// 1. RENAMED the class to MyDrawer
class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String title,
      required Color color,
      required String route}) {
    return FadeTransition(
      opacity: _animation,
      child: ListTile(
        leading: Icon(icon, color: color, size: 26),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        onTap: () {
          // 2. ADDED THIS LINE: Close the drawer before navigating
          Navigator.of(context).pop();
          Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. This returns the actual Drawer widget, which is correct.
    // The key is *where* this MyDrawer widget is used.
    return Drawer(
      elevation: 8,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFDE1FF),
              Color(0xFFFFF5E1),
              Color(0xFFE1F5FE),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero, // Recommended to remove top padding
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 24), // Adjust padding for status bar
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shopping_bag_rounded,
                      color: Colors.white, size: 40),
                  SizedBox(width: 12),
                  Text(
                    "BabyShop Hub",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildDrawerItem(
                icon: Icons.credit_card,
                title: "Card",
                color: Colors.deepPurple,
                route: '/card'),
            _buildDrawerItem(
                icon: Icons.credit_card,
                title: "addCards",
                color: Colors.deepPurple,
                route: '/add'),
            _buildDrawerItem(
                icon: Icons.shopping_cart,
                title: "Checkout",
                color: Colors.pinkAccent,
                route: '/checkout'),
            _buildDrawerItem(
                icon: Icons.add_card,
                title: "Add Card",
                color: Colors.teal,
                route: '/addcard'),
            _buildDrawerItem(
                icon: Icons.login,
                title: "Login Screen",
                color: Colors.blueAccent,
                route: '/loginScreen'),
            _buildDrawerItem(
                icon: Icons.people,
                title: "Manage Users",
                color: Colors.orangeAccent,
                route: '/ManageUsers'),
            _buildDrawerItem(
                icon: Icons.dashboard,
                title: "Seller Dashboard",
                color: Colors.deepOrange,
                route: '/SellerDashboard'),
            _buildDrawerItem(
                icon: Icons.app_registration,
                title: "Register",
                color: Colors.indigo,
                route: '/register'),
            _buildDrawerItem(
                icon: Icons.person,
                title: "User Dashboard",
                color: Colors.purpleAccent,
                route: '/UserDashboard'),
            _buildDrawerItem(
                icon: Icons.list_alt,
                title: "List CRUD",
                color: Colors.yellow.shade800,
                route: '/ListCrud'),
            _buildDrawerItem(
                icon: Icons.category,
                title: "Add Category",
                color: Colors.cyan,
                route: '/addCategory'),
            _buildDrawerItem(
                icon: Icons.category_outlined,
                title: "List Category",
                color: Colors.green,
                route: '/listCategory'),
          _buildDrawerItem(
            icon: Icons.photo_library_outlined, // Khubsurat icon
            title: "Manage Gallery",
            color: Colors.orange, // Naya color
            route: '/manageGallery', // Jo route humne main.dart mein banaya
          ),
          _buildDrawerItem(
            icon: Icons.photo_library_outlined, // Khubsurat icon
            title: "user order history",
            color: Colors.orange, // Naya color
            route: '/userorderhistory', // Jo route humne main.dart mein banaya
          ),
          _buildDrawerItem(
            icon: Icons.photo_library_outlined, // Khubsurat icon
            title: "Manage order",
            color: Colors.orange, // Naya color
            route: '/admin_order', // Jo route humne main.dart mein banaya
          ),
          
          ],
          
        ),
        
        
      ),
    );
  }
}