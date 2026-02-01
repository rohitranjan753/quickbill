import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _firestoreService = FirestoreService();
  final _emailController = TextEditingController();
  UserRole _selectedRole = UserRole.guard;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showAddUserBottomSheet(String storeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add User to Store',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Gmail ID',
                hintText: 'user@gmail.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Role',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: const [
                DropdownMenuItem(
                  value: UserRole.storeAdmin,
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, 
                           size: 20, 
                           color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Store Admin'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: UserRole.guard,
                  child: Row(
                    children: [
                      Icon(Icons.security, 
                           size: 20, 
                           color: Color(0xFF3B82F6)),
                      SizedBox(width: 8),
                      Text('Guard'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addUser(storeId),
              icon: const Icon(Icons.person_add),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _addUser(String storeId) async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    try {
      await _firestoreService.addUserToStore(
        email: email,
        storeId: storeId,
        role: _selectedRole,
      );

      if (mounted) {
        Navigator.pop(context);
        _emailController.clear();
        _selectedRole = UserRole.guard; // Reset to default
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $email added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding user: $e')),
        );
      }
    }
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Email'),
              subtitle: Text(user.email),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<UserRole>(
              value: user.role,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.badge),
              ),
              items: const [
                DropdownMenuItem(
                  value: UserRole.storeAdmin,
                  child: Text('Store Admin'),
                ),
                DropdownMenuItem(
                  value: UserRole.guard,
                  child: Text('Guard'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _updateUserRole(user.uid, value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserRole(String userId, UserRole role) async {
    try {
      await _firestoreService.updateStoreUserRole(userId, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User role updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await _firestoreService.updateUserStatus(user.uid, !user.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isActive ? 'User deactivated' : 'User activated',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _removeUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Are you sure you want to remove ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.removeUserFromStore(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentUser = authState.user;
        final storeId = currentUser.storeId;

        if (storeId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Management')),
            body: const Center(
              child: Text('No store associated with your account'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('User Management'),
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddUserBottomSheet(storeId),
            icon: const Icon(Icons.person_add),
            label: const Text('Add User'),
            backgroundColor: const Color(0xFF10B981),
          ),
          body: StreamBuilder<List<UserModel>>(
            stream: _firestoreService.getStoreUsers(storeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add users to manage your store',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isCurrentUser = user.uid == currentUser.uid;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isActive
                            ? const Color(0xFF10B981)
                            : Colors.grey,
                        child: user.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  user.photoURL!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      Text(
                                    user.displayName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                            : Text(
                                user.displayName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: user.isActive ? null : Colors.grey,
                              ),
                            ),
                          ),
                          if (user.isPendingSync)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (isCurrentUser)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          const SizedBox(height: 4),
                          Text(
                            _getRoleDisplayName(user.role),
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        enabled: !isCurrentUser,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditUserDialog(user);
                          } else if (value == 'toggle') {
                            _toggleUserStatus(user);
                          } else if (value == 'remove') {
                            _removeUser(user);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Change Role'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  user.isActive
                                      ? Icons.block
                                      : Icons.check_circle,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.isActive ? 'Deactivate' : 'Activate',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.storeAdmin:
        return 'Store Admin';
      case UserRole.guard:
        return 'Guard';
      case UserRole.customer:
        return 'Customer';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.storeAdmin:
        return const Color(0xFF10B981);
      case UserRole.guard:
        return const Color(0xFF3B82F6);
      case UserRole.customer:
        return Colors.grey;
    }
  }
}
