import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEditGalleryItemScreen extends StatefulWidget {
  // Agar hum item edit kar rahe hain, to uska data yahan aayega
  final DocumentSnapshot? document;

  const AddEditGalleryItemScreen({super.key, this.document});

  @override
  State<AddEditGalleryItemScreen> createState() => _AddEditGalleryItemScreenState();
}

class _AddEditGalleryItemScreenState extends State<AddEditGalleryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageUrlController = TextEditingController();
  final _nameController = TextEditingController();
  
  // Dropdown ke liye values
  String? _selectedColor;
  String? _selectedSize;
  final List<String> _colors = ["Pink", "Blue", "Yellow", "Green", "White", "Black"];
  final List<String> _sizes = ["Portrait", "Landscape", "Square"];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Agar document hai (yani hum edit kar rahe hain), to form ko uske data se bhar do
    if (widget.document != null) {
      final data = widget.document!.data() as Map<String, dynamic>;
      _imageUrlController.text = data['imageUrl'] ?? '';
      _nameController.text = data['name'] ?? '';
      _selectedColor = data['color'];
      _selectedSize = data['size'];
    }
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    // Form ko validate karein
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final collection = FirebaseFirestore.instance.collection('galleryItems');
      final data = {
        'imageUrl': _imageUrlController.text,
        'name': _nameController.text,
        'color': _selectedColor,
        'size': _selectedSize,
      };

      try {
        if (widget.document == null) {
          // Naya item add karein
          await collection.add(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery item added successfully!')),
          );
        } else {
          // Existing item update karein
          await collection.doc(widget.document!.id).update(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery item updated successfully!')),
          );
        }
        Navigator.of(context).pop(); // Form save hone ke baad wapas pichli screen par jayein
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document == null ? 'Add Gallery Item' : 'Edit Gallery Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Image URL Preview
                if (_imageUrlController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrlController.text,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an image URL.';
                    if (!value.startsWith('http')) return 'Please enter a valid URL.';
                    return null;
                  },
                  onChanged: (value) => setState(() {}), // Taake image preview live update ho
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name / Caption'),
                   validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a name.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  decoration: const InputDecoration(labelText: 'Color'),
                  items: _colors.map((color) => DropdownMenuItem(
                    value: color,
                    child: Text(color),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedColor = value),
                   validator: (value) {
                    if (value == null) return 'Please select a color.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedSize,
                  decoration: const InputDecoration(labelText: 'Size / Orientation'),
                  items: _sizes.map((size) => DropdownMenuItem(
                    value: size,
                    child: Text(size),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedSize = value),
                  validator: (value) {
                    if (value == null) return 'Please select a size.';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveForm,
                      child: Text(widget.document == null ? 'Add Item' : 'Update Item'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}