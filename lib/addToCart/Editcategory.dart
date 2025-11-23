import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:babyshophub/drawer.dart';
// import 'dart:html' as html;

class EditCardscreen extends StatefulWidget {
  final String id;
  final String name;
  final String description;
  final String ImageBase64;

  const EditCardscreen({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.ImageBase64,
  });

  @override
  State<EditCardscreen> createState() => _EditCardscreenState();
}

class _EditCardscreenState extends State<EditCardscreen> {
  late TextEditingController _nameController;
  late TextEditingController _desController;
  String? _base64Image;

  final DatabaseReference ref = FirebaseDatabase.instance.ref("categories");

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _desController = TextEditingController(text: widget.description);
    _base64Image = widget.ImageBase64;
  }

  // Future<void> _pickimg() async {
  //   final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  //   uploadInput.accept = "image/*";
  //   uploadInput.click();

  //   uploadInput.onChange.listen((event) {
  //     final file = uploadInput.files?.first;
  //     if (file != null) {
  //       final reader = html.FileReader();
  //       reader.readAsDataUrl(file);
  //       reader.onLoadEnd.listen((event) {
  //         setState(() {
  //           _base64Image = reader.result.toString().split(',').last;
  //         });
  //       });
  //     }
  //   });
  // }

  Future<void> _updateData() async {
    if (_nameController.text.isEmpty || _desController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter name and description")),
      );
      return;
    }

    try {
      await ref.child(widget.id).update({
        "id": widget.id,
        "name": _nameController.text,
        "description": _desController.text,
        "ImageBase64": _base64Image ?? "",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Category updated successfully")),
      );

      Navigator.pop(context, true); // Go back after update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Category"),
        backgroundColor: Colors.amberAccent,
      ),
      drawer: MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text("Edit Category", style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _desController,
              decoration: InputDecoration(
                labelText: 'Category Description',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                ),
              ),
            ),
            SizedBox(height: 20),
            _base64Image != null && _base64Image!.isNotEmpty
                ? Image.memory(base64Decode(_base64Image!), height: 120, width: 120, fit: BoxFit.cover)
                : Icon(Icons.image, size: 100),
            SizedBox(height: 10),
            OutlinedButton.icon(
              icon: Icon(Icons.image),
              // onPressed: _pickimg,
              onPressed:null,
              label: Text('Change Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateData,
              child: Text("Update Category"),
            ),
          ],
        ),
      ),
    );
  }
}
