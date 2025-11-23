import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:babyshophub/addToCart/Editcategory.dart';
import 'package:babyshophub/drawer.dart';

class Listfetchcrud extends StatefulWidget {
  const Listfetchcrud({super.key});

  @override
  State<Listfetchcrud> createState() => _ListfetchcrudState();
}

class _ListfetchcrudState extends State<Listfetchcrud> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref("categories");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List Of CRUD"),
        backgroundColor: Colors.amberAccent,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/AddCrud");
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      drawer: MyDrawer(),
      body: StreamBuilder(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
            final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );

            final categories = data.values.toList();
            final keys = data.keys.toList();

            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = Map<String, dynamic>.from(categories[index]);
                final id = keys[index];

                // ✅ Safely handle missing fields
                final name = cat["name"] ?? "Unnamed";
                final description = cat["description"] ?? "No description";
                final price = cat["price"]?.toString() ?? "N/A"; // 👈 Added price
                final imageBase64 = cat["ImageBase64"] ?? "";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: imageBase64.isNotEmpty
                        ? Image.memory(
                            base64Decode(imageBase64),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image, size: 50),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(description),
                        const SizedBox(height: 4),
                        Text(
                          "Price: ₹$price",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🗑️ Delete Button
                        IconButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Category"),
                                content: const Text(
                                    "Are you sure you want to delete this category?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.child(id).remove();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Category deleted successfully")),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),

                        // ✏️ Edit Button
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCardscreen(
                                  id: id,
                                  name: name,
                                  description: description,
                                  ImageBase64: imageBase64,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // Default message if no data
          return const Center(
            child: Text(
              "No Categories Found...",
              style: TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
