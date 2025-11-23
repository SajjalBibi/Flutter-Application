import 'dart:typed_data';
import 'dart:convert'; // ✅ Base64 ke liye isay add karein
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // ❌ Iski zaroorat nahi
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;
  const EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _dbRef = FirebaseDatabase.instance.ref().child('Users');

  // ❌ Storage reference ki zaroorat nahi
  // final _storageRef = FirebaseStorage.instance.ref().child('profile_pictures');

  String? _currentImageBase64; // URL ki jagah Base64 string
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final snapshot = await _dbRef.child(widget.userId).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      _nameController.text = data['name'] ?? '';
      if (mounted) {
        setState(() {
          // ✅ Database se Base64 string load karein
          _currentImageBase64 = data['profileImageBase64'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // Quality kam kar di
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _pickedImage = file;
          _imageBytes = bytes;
        });
      }
    }
  }

  // ✅ YEH FUNCTION MUKAMMAL BADAL GAYA HAI
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      String? imageToSave = _currentImageBase64;

      // Agar new image select ki hai to usko Base64 mein convert karein
      if (_pickedImage != null && _imageBytes != null) {
        imageToSave = base64Encode(_imageBytes!);
      }

      // User ka data Realtime Database mein update karein
      await _dbRef.child(widget.userId).update({
        'name': _nameController.text.trim(),
        'profileImageBase64': imageToSave, // ✅ Yahan Base64 string save karein
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.purpleAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    // ✅ IMAGE DISPLAY KARNE KA TAREEQA BADAL GAYA HAI
                    backgroundImage: _imageBytes != null
                        ? MemoryImage(_imageBytes!) // Picked image (temporary display)
                        : (_currentImageBase64 != null && _currentImageBase64!.isNotEmpty
                            // Decode Base64 string back to image
                            ? MemoryImage(base64Decode(_currentImageBase64!))
                            : const AssetImage('assets/profile.jpg'))
                        as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}