import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      // AppBar con un estilo moderno
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Gestionar Usuarios (Admin)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No hay usuarios registrados.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final data = docs[i].data()! as Map<String, dynamic>;
                final uid = data['uid'];
                final email = data['email'];
                final displayName = data['displayName'] ?? '';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            String? newName = await showDialog(
                              context: context,
                              builder: (_) {
                                final ctrl = TextEditingController(
                                  text: displayName,
                                );
                                return AlertDialog(
                                  title: const Text('Editar nombre'),
                                  content: TextField(
                                    controller: ctrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Nuevo nombre',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, ctrl.text),
                                      child: const Text('Guardar'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (newName != null && newName.trim().isNotEmpty) {
                              await authService.updateOtherUser(
                                  uid, newName.trim());
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await authService.deleteUser(uid);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
