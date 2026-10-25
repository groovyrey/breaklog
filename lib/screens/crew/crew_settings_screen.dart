import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';

class CrewSettingsScreen extends StatefulWidget {
  const CrewSettingsScreen({super.key, required this.crew});

  final Map<String, dynamic> crew;

  @override
  State<CrewSettingsScreen> createState() => _CrewSettingsScreenState();
}

class _CrewSettingsScreenState extends State<CrewSettingsScreen> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.crew['name'] ?? '');
  late final TextEditingController _bioCtrl =
      TextEditingController(text: widget.crew['bio'] ?? '');
  late bool _publicMembers =
      widget.crew['public_members'] == 1 || widget.crew['public_members'] == true;
  String? _photoBase64;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
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
              title: 'Crew settings',
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
                        Text(
                          'General',
                          style: context.appTextTheme.titleSmall
                              ?.copyWith(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (file == null) return;
                              final bytes = await file.readAsBytes();
                              setState(() {
                                _photoBase64 =
                                    'data:image/jpeg;base64,${base64Encode(bytes)}';
                              });
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppColors.surfaceVariant,
                                  backgroundImage: _photoBase64 != null
                                      ? MemoryImage(base64Decode(
                                          _photoBase64!.split(',').last))
                                      : (widget.crew['photo_url'] != null
                                          ? NetworkImage(widget.crew['photo_url'])
                                          : null),
                                  child: _photoBase64 == null &&
                                          widget.crew['photo_url'] == null
                                      ? const Icon(Icons.groups,
                                          size: 32,
                                          color: AppColors.onSurfaceVariant)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        size: 14, color: AppColors.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  BrkButton(
                    label: 'Save changes',
                    onPressed: () async {
                      try {
                        final state = context.read<AppState>();
                        final token = await state.auth.idToken();
                        if (token == null) return;
                        await state.api.updateCrew(
                          token,
                          widget.crew['crew_id'],
                          name: _nameCtrl.text,
                          bio: _bioCtrl.text,
                          photoUrl: _photoBase64,
                          publicMembers: _publicMembers,
                        );
                        if (mounted) {
                          showBrkToast(context, 'Crew updated');
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        if (mounted) {
                          showBrkToast(context, e.toString(),
                              icon: Icons.error_outline);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  BrkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danger zone',
                          style: context.appTextTheme.titleSmall
                              ?.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Disbanding will remove all members and delete the crew.',
                          style: context.appTextTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        BrkButton(
                          label: 'Disband crew',
                          variant: BrkButtonVariant.secondary,
                          onPressed: () async {
                            final confirm = await showBrkSheet<bool>(
                              context: context,
                              builder: (ctx) => BrkSheet(
                                title: 'Disband crew',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'This action cannot be undone.',
                                      style: context.appTextTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: BrkButton(
                                            label: 'Cancel',
                                            variant: BrkButtonVariant.secondary,
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: BrkButton(
                                            label: 'Disband',
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (confirm != true) return;
                            try {
                              final state = context.read<AppState>();
                              final token = await state.auth.idToken();
                              if (token == null) return;
                              await state.api.disbandCrew(
                                  token, widget.crew['crew_id']);
                              if (mounted) {
                                showBrkToast(context, 'Crew disbanded');
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            } catch (e) {
                              if (mounted) {
                                showBrkToast(context, e.toString(),
                                    icon: Icons.error_outline);
                              }
                            }
                          },
                        ),
                      ],
                    ),
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
