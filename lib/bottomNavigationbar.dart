// In BottomNavigationScreen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:babyshophub/AuthRolebase/SignUp.dart'; // Import SignUp page
import 'package:babyshophub/UserProfile/AccountPage.dart'; // Import AccountPage

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  late AnimationController _bottomLineController;
  late Animation<double> _bottomLineAnimation;

  @override
  void initState() {
    super.initState();

    // Glow animation for Sell button
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Bottom navigation line animation (only once)
    _bottomLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _bottomLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bottomLineController, curve: Curves.easeOutExpo),
    );

    // Run bottom line animation once
    _bottomLineController.forward();
    Timer(const Duration(seconds: 3), () {
      _bottomLineController.reverse();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bottomLineController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ✅ Pages are now built dynamically based on auth state
  List<Widget> _buildPages(User? user) {
    return [
      const Center(
          child: Text('🏠 Home',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      const Center(
          child: Text('💬 Chat',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      const Center(
          child: Text('➕ Sell',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      const Center(
          child: Text('📦 My Ads',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      // ✅ DYNAMIC ACCOUNT/SIGN-UP PAGE
      // Yahan par humne `SignIn()` ko `SignUp()` se badal diya hai
      user != null ? AccountPage(userId: user.uid) : const SignUp(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      const Color(0xFFD4B5FF), // Lavender
      const Color(0xFF9AD3FF), // Sky Blue
      const Color(0xFFFFB3E0), // Pink
    ];

    return Scaffold(
      // Use a StreamBuilder to listen to authentication changes
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final pages = _buildPages(user);

          // Show a loading indicator while connecting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: pages[_selectedIndex],
          );
        },
      ),

      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom Navigation Container with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.75),
              showUnselectedLabels: true,
              selectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox.shrink(),
                  label: '', // Placeholder for Sell
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront_outlined),
                  activeIcon: Icon(Icons.storefront_rounded),
                  label: 'My Ads',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Account',
                ),
              ],
            ),
          ),

          /// ✨ Animated Line on Top of Bottom Navigation Bar (Runs Once)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _bottomLineAnimation,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 3,
                    width:
                        MediaQuery.of(context).size.width * _bottomLineAnimation.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purpleAccent.shade100,
                          Colors.lightBlueAccent.shade100,
                          Colors.pinkAccent.shade100,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// Floating SELL Button
          Positioned(
            top: -28,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.pinkAccent.shade100,
                              Colors.lightBlueAccent.shade100
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.5),
                                blurRadius: 8 + _animation.value,
                                spreadRadius: _animation.value,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purpleAccent.shade100,
                                  Colors.lightBlueAccent.shade100,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sell",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedIndex == 2
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}