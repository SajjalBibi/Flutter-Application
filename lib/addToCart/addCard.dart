import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
// Step 1: Firestore package ko import karein
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:babyshophub/drawer.dart';


class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _nameController = TextEditingController();
  final _desController = TextEditingController();
  final _priceController = TextEditingController();
  String? _base64Image;
  String? _fileName;

  // Step 2: Selected category ko store karne ke liye naya variable banayein
  String? _selectedCategory;

  /// Pick image
  Future<void> _pickimg() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      setState(() {
        _base64Image = base64Encode(bytes);
        _fileName = result.files.single.name;
      });
    } else if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
        _fileName = result.files.single.name;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image selected")),
      );
    }
  }

  /// Insert data into Firebase
  Future<void> _insertData() async {
    // Step 4: Validation mein category ko bhi check karein
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _base64Image == null ||
        _selectedCategory == null) { // <-- Naya check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select a category")),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    
    // Note: Aap "categories" node mein data save kar rahe hain.
    final ref = FirebaseDatabase.instance.ref("categories").push();
    await ref.set({
      "id": ref.key,
      "name": _nameController.text.trim(),
      "description": _desController.text.trim(),
      "price": price,
      "ImageBase64": _base64Image,
      "category": _selectedCategory, // <-- Nayi field: category save karein
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully")),
      );
      
      // Fields aur dropdown ko reset karein
      _nameController.clear();
      _desController.clear();
      _priceController.clear();
      setState(() {
        _base64Image = null;
        _fileName = null;
        _selectedCategory = null; // <-- Naya reset
      });
      
      // Page par rehne ke liye Navigator ko comment kar dein ya hata dein
      // Navigator.pushReplacementNamed(context, "/ListCrud");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product"),
        backgroundColor: Colors.amberAccent,
      ),
      drawer: MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Add New Product",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _desController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Step 3: Yahan category dropdown add karein
              StreamBuilder<QuerySnapshot>(
                // Firestore ke 'Categories' collection se data fetch karein
                stream: FirebaseFirestore.instance.collection('Categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  // Dropdown ke liye items banayein
                  final categoryItems = snapshot.data!.docs.map((doc) {
                    final categoryName = (doc.data() as Map<String, dynamic>)['name'] as String;
                    return DropdownMenuItem<String>(
                      value: categoryName,
                      child: Text(categoryName),
                    );
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categoryItems,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Category",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null ? 'Please select a category' : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: Text(_fileName ?? 'Upload Image'),
                onPressed: _pickimg,
              ),

              if (_base64Image != null) ...[
                const SizedBox(height: 10),
                Image.memory(
                  base64Decode(_base64Image!),
                  height: 100,
                ),
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _insertData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Add Product"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}