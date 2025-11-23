import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Babiyo color scheme
  final Color primaryColor = const Color(0xFFE0F7FA); // Light Cyan
  final Color accentColor = const Color(0xFF4DD0E1); // Medium Cyan
  final Color textColor = const Color(0xFF424242); // Dark Grey

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, const Color(0xFF26C6DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Baby-themed image
          Image.asset(
            'assets/baby_icon.png', // Make sure you have this image in your assets folder
            width: 60,
            height: 60,
          ),
          const SizedBox(width: 16),
          Text(
            "BabyShop Hub",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String route,
    int index = 0, // for staggered animation
  }) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.2, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _controller,
            curve: Interval(0.1 * index, 1.0, curve: Curves.easeOut))),
        child: ListTile(
          leading: Icon(icon, color: accentColor, size: 28),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          onTap: () {
            Navigator.of(context).pop(); // Close drawer first
            // Avoid pushing the same route again if already on it
            if (ModalRoute.of(context)?.settings.name != route) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 8,
      child: Container(
        color: primaryColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            const SizedBox(height: 20),
            _buildDrawerItem(icon: Icons.dashboard_rounded, title: "Dashboard", route: '/adminDashboard', index: 0),
            _buildDrawerItem(icon: Icons.people_alt_rounded, title: "Manage Users", route: '/ManageUsers', index: 1),
            _buildDrawerItem(icon: Icons.store_rounded, title: "Seller Dashboard", route: '/SellerDashboard', index: 2),
            _buildDrawerItem(icon: Icons.person_rounded, title: "User Dashboard", route: '/UserDashboard', index: 3),
            _buildDrawerItem(icon: Icons.list_alt_rounded, title: "Products CRUD", route: '/ListCrud', index: 4),
            _buildDrawerItem(icon: Icons.category_rounded, title: "Add Category", route: '/addCategory', index: 5),
            _buildDrawerItem(icon: Icons.view_list_rounded, title: "List Categories", route: '/listCategory', index: 6),
            _buildDrawerItem(icon: Icons.photo_library_rounded, title: "Manage Gallery", route: '/manageGallery', index: 7),
            _buildDrawerItem(icon: Icons.receipt_long_rounded, title: "Manage Orders", route: '/admin_order', index: 8),
            _buildDrawerItem(icon: Icons.history_rounded, title: "User Order History", route: '/userorderhistory', index: 9),
            const Divider(color: Colors.black12, indent: 20, endIndent: 20, height: 30),
             _buildDrawerItem(icon: Icons.credit_card, title: "Card", route: '/card', index: 10),
          ],
        ),
      ),
    );
  }
}