import 'dart:convert';
import 'dart:typed_data'; // for Uint8List
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File; // only for mobile/desktop
import 'package:babyshophub/drawer.dart';

class CategoriesAddScreen extends StatefulWidget {
  const CategoriesAddScreen({super.key});

  @override
  State<CategoriesAddScreen> createState() => _CategoriesAddScreenState();
}

class _CategoriesAddScreenState extends State<CategoriesAddScreen> {
  final _nameController = TextEditingController();
  final _desController = TextEditingController();

  String? _base64Image;
  Uint8List? _webImage; // for web
  File? _imgFile; // for mobile

  Future<void> _pickimg() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        // Web
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _base64Image = base64Encode(bytes);
        });
      } else {
        // Mobile/Desktop
        final bytes = await picked.readAsBytes();
        setState(() {
          _imgFile = File(picked.path);
          _base64Image = base64Encode(bytes);
        });
      }
    }
  }

  Future<void> _AddCategory() async {
    final name = _nameController.text.trim();
    final description = _desController.text.trim();

    if (name.isEmpty || description.isEmpty || _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All Fields are required")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('Categories').add({
        'name': name,
        'Description': description,
        'Image': _base64Image,
        'CreatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category Added Successfully...")));

      _nameController.clear();
      _desController.clear();
      setState(() {
        _imgFile = null;
        _webImage = null;
        _base64Image = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ERROR : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imagePreview;

    if (kIsWeb && _webImage != null) {
      imagePreview = Image.memory(_webImage!, height: 140, width: 140, fit: BoxFit.cover);
    } else if (!kIsWeb && _imgFile != null) {
      imagePreview = Image.file(_imgFile!, height: 140, width: 140, fit: BoxFit.cover);
    } else {
      imagePreview = const Icon(Icons.image, size: 100);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ADD NEW CATEGORY"),
        backgroundColor: Colors.amberAccent,
      ),
      drawer: MyDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          const SizedBox(height: 20),
          const Text("Add new Category"),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _desController,
            decoration: const InputDecoration(
              labelText: 'Category Description',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          imagePreview,
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.image),
            onPressed: _pickimg,
            label: const Text('Upload img'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _AddCategory, child: const Text("Add Category")),
        ]),
      ),
    );
  }
}
