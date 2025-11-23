import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:babyshophub/drawer.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("Users");
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  static const int _pageSize = 5;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final snapshot = await _dbRef.get();
    final List<Map<String, dynamic>> temp = [];
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        temp.add({
          'uid': key,
          'email': value['email'],
          'role': value['role'],
          'emailVerified': value['emailVerified'],
          'isBlocked': value['isBlocked'] ?? false,
        });
      });
    }
    setState(() {
      _users = temp;
      _filtered = temp;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _filtered = _users
          .where((u) =>
              u['email'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
      _currentPage = 0;
    });
  }

  Future<void> _deleteUser(String uid) async {
    await _dbRef.child(uid).remove();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("User deleted")));
    _fetchUsers();
  }

  Future<void> _updateRole(String uid, String newRole) async {
    await _dbRef.child(uid).update({'role': newRole});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Role updated")));
    _fetchUsers();
  }

  Future<void> _toggleBlock(String uid, bool currentStatus) async {
    await _dbRef.child(uid).update({'isBlocked': !currentStatus});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            currentStatus ? "User unblocked successfully" : "User blocked successfully"),
        backgroundColor: currentStatus ? Colors.green : Colors.red,
      ),
    );
    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    final currentPageData =
        _filtered.sublist(start, end > _filtered.length ? _filtered.length : end);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: const InputDecoration(
                labelText: "Filter by Email",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: currentPageData.length,
                itemBuilder: (context, index) {
                  final user = currentPageData[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        user['isBlocked']
                            ? Icons.block
                            : Icons.verified_user_outlined,
                        color:
                            user['isBlocked'] ? Colors.redAccent : Colors.green,
                      ),
                      title: Text(user['email']),
                      subtitle: Text(
                          "Role: ${user['role']} | Verified: ${user['emailVerified']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: !user['isBlocked'],
                            onChanged: (value) =>
                                _toggleBlock(user['uid'], user['isBlocked']),
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            inactiveTrackColor: Colors.redAccent.shade100,
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'Edit') {
                                _showEditDialog(user);
                              } else if (value == 'Delete') {
                                _deleteUser(user['uid']);
                              } else if (value == 'View') {
                                _showViewDialog(user);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: 'View', child: Text('View')),
                              PopupMenuItem(
                                  value: 'Edit', child: Text('Edit Role')),
                              PopupMenuItem(
                                  value: 'Delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  child: const Text("Previous"),
                ),
                Text(
                    "Page ${_currentPage + 1} of ${(_filtered.length / _pageSize).ceil()}"),
                TextButton(
                  onPressed: end < _filtered.length
                      ? () => setState(() => _currentPage++)
                      : null,
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("User Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("UID: ${user['uid']}"),
            Text("Email: ${user['email']}"),
            Text("Role: ${user['role']}"),
            Text("Verified: ${user['emailVerified']}"),
            Text("Blocked: ${user['isBlocked']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    String? _newRole = user['role'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit User Role"),
        content: DropdownButtonFormField<String>(
          value: _newRole,
          items: const [
            DropdownMenuItem(value: "Admin", child: Text("Admin")),
            DropdownMenuItem(value: "Seller", child: Text("Seller")),
            DropdownMenuItem(value: "User", child: Text("User")),
          ],
          onChanged: (value) => _newRole = value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newRole != null) {
                _updateRole(user['uid'], _newRole!);
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
