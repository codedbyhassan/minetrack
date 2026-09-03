import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/services/supabase_service.dart';

final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authControllerProvider).currentUser;
  if (user == null) return null;

  final response = await SupabaseService.client
      .from('profiles')
      .select('id, full_name, email, role, created_at, updated_at')
      .eq('id', user.id)
      .maybeSingle();

  return response;
});

final organizationProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authControllerProvider).currentUser;
  if (user == null) return null;

  final membership = await SupabaseService.client
      .from('organization_members')
      .select('organization_id, role')
      .eq('user_id', user.id)
      .maybeSingle();

  if (membership == null) return null;

  final organization = await SupabaseService.client
      .from('organizations')
      .select('id, name, owner_id, created_at, updated_at')
      .eq('id', membership['organization_id'])
      .maybeSingle();

  if (organization == null) return null;
  return {...organization, 'membership_role': membership['role']};
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authControllerProvider).currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await SupabaseService.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      ref.invalidate(profileProvider);
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).currentUser;
    final profile = ref.watch(profileProvider);
    final organization = ref.watch(organizationProvider);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 38,
            child: Text(
              (user.email?.isNotEmpty == true ? user.email![0] : 'M').toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorCard(message: error.toString()),
            data: (data) {
              final name = (data?['full_name'] as String?)?.trim() ?? '';
              if (!_editing && _nameController.text.isEmpty) {
                _nameController.text = name;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Personal information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    enabled: _editing && !_saving,
                    decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: data?['email'] as String? ?? user.email ?? '',
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Role'),
                    subtitle: Text(data?['role'] as String? ?? 'administrator'),
                  ),
                  if (_editing)
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                      label: const Text('Save changes'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _editing = true),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit profile'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text('Organization', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          organization.when(
            loading: () => const Card(child: Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator())),
            error: (error, _) => _ErrorCard(message: error.toString()),
            data: (data) => Card(
              child: ListTile(
                leading: const Icon(Icons.business_outlined),
                title: Text(data?['name'] as String? ?? 'Organization unavailable'),
                subtitle: Text('Membership: ${data?['membership_role'] ?? 'unknown'}'),
              ),
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message),
        ),
      );
}
