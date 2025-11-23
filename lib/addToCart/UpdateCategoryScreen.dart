import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:babyshophub/drawer.dart';

class UpdateCategoryScreen extends StatefulWidget {
  final String docId;
  final String name;
  final String description;
  final String image;

  const UpdateCategoryScreen({
    super.key,
    required this.docId,
    required this.name,
    required this.description,
    required this.image,
  });

  @override
  State<UpdateCategoryScreen> createState() => _UpdateCategoryScreenState();
}

class _UpdateCategoryScreenState extends State<UpdateCategoryScreen> {
  late TextEditingController _nameController;
  late TextEditingController _desController;

  String? _base64Image;
  Uint8List? _webImage; // for Web
  File? _imgFile; // for Mobile

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _desController = TextEditingController(text: widget.description);
    _base64Image = widget.image; // already stored image
  }

  Future<void> _pickimg() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _base64Image = base64Encode(bytes);
        });
      } else {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imgFile = File(picked.path);
          _base64Image = base64Encode(bytes);
        });
      }
    }
  }

  Future<void> _updateCategory() async {
    final name = _nameController.text.trim();
    final description = _desController.text.trim();

    if (name.isEmpty || description.isEmpty || _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All Fields are required")));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('Categories')
          .doc(widget.docId)
          .update({
        'name': name,
        'Description': description,
        'Image': _base64Image,
        'UpdatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category Updated Successfully...")));

      Navigator.pop(context); // go back after update
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("ERROR : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imagePreview;

    if (_webImage != null) {
      imagePreview =
          Image.memory(_webImage!, height: 140, width: 140, fit: BoxFit.cover);
    } else if (!kIsWeb && _imgFile != null) {
      imagePreview =
          Image.file(_imgFile!, height: 140, width: 140, fit: BoxFit.cover);
    } else if (_base64Image != null) {
      imagePreview = Image.memory(base64Decode(_base64Image!),
          height: 140, width: 140, fit: BoxFit.cover);
    } else {
      imagePreview = const Icon(Icons.image, size: 100);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Category"),
        backgroundColor: Colors.amberAccent,
      ),
      drawer: MyDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          const SizedBox(height: 20),
          const Text("Update Category"),
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
            label: const Text('Change Image'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _updateCategory,
              child: const Text("Update Category")),
        ]),
      ),
    );
  }
}
