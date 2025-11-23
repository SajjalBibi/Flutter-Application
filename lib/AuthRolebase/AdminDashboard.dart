// admin_dashboard_full.dart
// Fixed Flutter Admin Panel

import 'dart:async';
import 'package:babyshophub/AuthRolebase/ManageUsers.dart';
import 'package:babyshophub/addToCart/admin/AdminOrdersPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}

// ----------------- Global helper for user stats -----------------
Stream<Map<String, int>> getUserStats() {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');
  return _usersRef.onValue.map((event) {
    int total = 0, admins = 0, sellers = 0, users = 0, blocked = 0, verified = 0;
    if (event.snapshot.exists) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      data.forEach((key, v) {
        total++;
        final user = Map<String, dynamic>.from(v as Map);
        final role = (user['role'] ?? 'User').toString();
        final isBlocked = (user['isBlocked'] ?? false) as bool;
        final emailVerified = (user['emailVerified'] ?? false) as bool;
        if (role == 'Admin') admins++;
        if (role == 'Seller') sellers++;
        if (role == 'User') users++;
        if (isBlocked) blocked++;
        if (emailVerified) verified++;
      });
    }
    return {
      'total': total,
      'admins': admins,
      'sellers': sellers,
      'users': users,
      'blocked': blocked,
      'verified': verified,
      'unverified': total - verified,
    };
  });
}

// ------------------ Main App ------------------
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BabyShopHub Admin',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 2,
          iconTheme: IconThemeData(color: Color(0xFF424242)),
        ),
      ),
      home: const AdminDashboard(),
    );
  }
}

// ------------------ Admin Dashboard ------------------
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');
  final _firestore = FirebaseFirestore.instance;
  String _currentPage = 'Dashboard';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Stream<Map<String, int>> getOrderStats() {
    return _firestore.collectionGroup('orders').snapshots().map((snap) {
      int total = snap.docs.length;
      int completed = 0, processing = 0, pending = 0, cancelled = 0;
      for (var d in snap.docs) {
        final s = (d.data() as Map<String, dynamic>)['status'] ?? 'pending';
        switch (s.toString().toLowerCase()) {
          case 'completed':
            completed++;
            break;
          case 'processing':
            processing++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          default:
            pending++;
        }
      }
      return {'total': total, 'completed': completed, 'processing': processing, 'pending': pending, 'cancelled': cancelled};
    });
  }

  Widget statsCard(String title, int value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget rolePieChart(Map<String, int> stats) {
    final admins = stats['admins']!.toDouble();
    final sellers = stats['sellers']!.toDouble();
    final users = stats['users']!.toDouble();
    final total = admins + sellers + users;
    if (total == 0) return const SizedBox(height: 160, child: Center(child: Text('No users yet')));
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(value: admins, color: Colors.purple, title: 'Admins'),
            PieChartSectionData(value: sellers, color: Colors.orange, title: 'Sellers'),
            PieChartSectionData(value: users, color: Colors.green, title: 'Users'),
          ],
        ),
      ),
    );
  }

  Widget blockedBarChart(Map<String, int> stats) {
    final blocked = stats['blocked']!.toDouble();
    final active = (stats['total']! - stats['blocked']!).toDouble();
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: blocked, width: 18, color: Colors.red)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: active, width: 18, color: Colors.blue)]),
          ],
          titlesData: FlTitlesData(show: true, bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
            if (v.toInt() == 0) return const Text('Blocked');
            return const Text('Active');
          }))),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(padding: const EdgeInsets.all(16), color: const Color(0xFF26C6DA), child: Row(children: [
            const CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF26C6DA))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('admin@babyshop.com', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))
            ]))
          ])),
          ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'), selected: _currentPage == 'Dashboard', onTap: () => setState(() => _currentPage = 'Dashboard')),
          ListTile(leading: const Icon(Icons.list_alt), title: const Text('Orders'), selected: _currentPage == 'Orders', onTap: () => setState(() => _currentPage = 'Orders')),
          ListTile(leading: const Icon(Icons.people), title: const Text('Manage Users'), selected: _currentPage == 'Users', onTap: () => setState(() => _currentPage = 'Users')),
          const Spacer(),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () {/* implement logout */}),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_currentPage) {
      case 'Orders':
        content = AdminOrdersPage();
        break;
      case 'Users':
        content = const ManageUsers();
        break;
      default:
        content = _buildDashboardContent();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel - $_currentPage', style: GoogleFonts.poppins(color: const Color(0xFF424242)))),
      drawer: _buildDrawer(),
      body: FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: Padding(padding: const EdgeInsets.all(16), child: content))),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFF4DD0E1), Color(0xFF26C6DA)]), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))]),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome Back, Admin!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Overview of users and orders', style: GoogleFonts.poppins(color: Colors.white70))
            ])),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.child_care_rounded, size: 60, color: Colors.white))
          ])),
        const SizedBox(height: 18),
        StreamBuilder<Map<String, int>>(stream: getUserStats(), builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final stats = snap.data!;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 12, runSpacing: 12, children: [
              statsCard('Total Users', stats['total']!, Colors.blue),
              statsCard('Admins', stats['admins']!, Colors.purple),
              statsCard('Sellers', stats['sellers']!, Colors.orange),
              statsCard('Users', stats['users']!, Colors.green),
              statsCard('Blocked', stats['blocked']!, Colors.red),
              statsCard('Verified', stats['verified']!, Colors.teal),
            ]),
            const SizedBox(height: 18),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Role Distribution', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), rolePieChart(stats)])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Status Overview', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), blockedBarChart(stats)])),
            ])
          ]);
        }),
        const SizedBox(height: 18),
        StreamBuilder<Map<String, int>>(stream: getOrderStats(), builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final o = snap.data!;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Orders Summary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 12, children: [
              statsCard('Total Orders', o['total']!, Colors.blue),
              statsCard('Completed', o['completed']!, Colors.green),
              statsCard('Processing', o['processing']!, Colors.orange),
              statsCard('Pending', o['pending']!, Colors.amber),
              statsCard('Cancelled', o['cancelled']!, Colors.red),
            ]),
          ]);
        }),
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ------------------ ManageUsers and AdminOrders code remains unchanged ------------------
// Copy your previous code for ManageUsers and AdminOrders here
