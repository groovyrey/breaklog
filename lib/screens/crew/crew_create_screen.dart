import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';

class CrewCreateScreen extends StatefulWidget {
  const CrewCreateScreen({super.key});

  @override
  State<CrewCreateScreen> createState() => _CrewCreateScreenState();
}

class _CrewCreateScreenState extends State<CrewCreateScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _publicMembers = true;
  String? _photoBase64;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrkHeader(
              title: 'Create crew',
              leading: Icons.arrow_back,
              onLeading: () => Navigator.of(context).pop(),
              actions: const [TopBarActions()],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  BrkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: AppColors.surfaceVariant,
                                  backgroundImage: _photoBase64 != null
                                      ? MemoryImage(base64Decode(_photoBase64!.split(',').last))
                                      : null,
                                  child: _photoBase64 == null
                                      ? const Icon(Icons.groups,
                                          size: 40, color: AppColors.onSurfaceVariant)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        size: 16, color: AppColors.onBackground),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        BrkField(controller: _nameCtrl, hint: 'Crew name'),
                        const SizedBox(height: 12),
                        BrkField(controller: _bioCtrl, hint: 'Bio', maxLines: 4),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Allow non-members to view members',
                                style: context.appTextTheme.bodyMedium,
                              ),
                            ),
                            BrkSwitch(
                              value: _publicMembers,
                              onChanged: (v) => setState(() => _publicMembers = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  BrkButton(
                    label: _saving ? 'Creating...' : 'Create crew',
                    onPressed: _saving
                        ? null
                        : () async {
                            if (_nameCtrl.text.trim().isEmpty) {
                              showBrkToast(context, 'Name required',
                                  icon: Icons.error_outline);
                              return;
                            }
                            setState(() => _saving = true);
                            try {
                              final state = context.read<AppState>();
                              final token = await state.auth.idToken();
                              if (token == null) return;
                              await state.api.createCrew(
                                token,
                                name: _nameCtrl.text,
                                bio: _bioCtrl.text,
                                photoUrl: _photoBase64,
                                publicMembers: _publicMembers,
                              );
                              if (mounted) {
                                Navigator.of(context).pop(true);
                              }
                            } catch (e) {
                              if (mounted) {
                                showBrkToast(context, e.toString(),
                                    icon: Icons.error_outline);
                              }
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
