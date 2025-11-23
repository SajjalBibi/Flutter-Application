// File: AccountPage.dart

import 'dart:convert'; // ✅ Base64 ke liye isay add karein
import 'dart:typed_data'; // ✅ Uint8List ke liye isay add karein
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:babyshophub/UserProfile/EditProfilePage.dart';

class AccountPage extends StatefulWidget {
  final String userId;
  const AccountPage({super.key, required this.userId});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _db = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? userData;
  Uint8List? _profileImageBytes; // ✅ Image bytes store karne ke liye variable

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    final snapshot = await _db.child("Users/${widget.userId}").get();
    if (snapshot.exists) {
      setState(() {
        userData = Map<String, dynamic>.from(snapshot.value as Map);
        userData!['email'] = FirebaseAuth.instance.currentUser?.email ?? "No Email";
        
        // ✅ Base64 string ko decode karke image bytes banayein
        final imageBase64 = userData!['profileImageBase64'];
        if (imageBase64 != null && imageBase64.isNotEmpty) {
          _profileImageBytes = base64Decode(imageBase64);
        } else {
          _profileImageBytes = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Account"),
        backgroundColor: Colors.purpleAccent,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // ✅ IMAGE DISPLAY KARNE KA SAHI TAREEQA
              CircleAvatar(
                radius: 55,
                backgroundImage: _profileImageBytes != null
                    ? MemoryImage(_profileImageBytes!) // Base64 se image dikhayein
                    : const AssetImage('assets/profile.jpg') as ImageProvider,
              ),
              
              const SizedBox(height: 14),
              Text(userData!['name'] ?? "No Name",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(userData!['email'],
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: Colors.purple),
                      title: const Text("Edit Profile"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(userId: widget.userId),
                          ),
                        ).then((_) => _loadUserData());
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined, color: Colors.purple),
                      title: const Text("Settings"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: Colors.purple),
                      title: const Text("Help & Support"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.feedback_outlined, color: Colors.purple),
                      title: const Text("Feedback"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text("Logout",
                          style: TextStyle(color: Colors.redAccent)),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}