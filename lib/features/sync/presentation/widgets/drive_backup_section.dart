import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/drive_backup_service.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../backup_restore_flow.dart';
import 'settings_group.dart';

/// Conexión de la cuenta de Google usada por las copias de seguridad.
class DriveBackupSection extends StatefulWidget {
  const DriveBackupSection({
    super.key,
    this.enabled = true,
    this.firstInColumn = false,
  });

  final bool enabled;
  final bool firstInColumn;

  @override
  State<DriveBackupSection> createState() => _DriveBackupSectionState();
}

class _DriveBackupSectionState extends State<DriveBackupSection> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await DriveBackupService.signIn();
    } catch (error) {
      if (mounted) showDriveError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await DriveBackupService.signOut();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final canAct = widget.enabled && !_busy;
    final email = AppPreferences.driveEmail;

    final Widget row;
    if (email == null) {
      row = SettingsRow(
        icon: Icons.add_to_drive_outlined,
        title: l10n.driveSignIn,
        subtitle: l10n.driveSignInSubtitle,
        loading: _busy,
        onTap: canAct ? _signIn : null,
      );
    } else {
      row = Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primaryContainer,
              child: Text(
                email.characters.first.toUpperCase(),
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.driveConnectedAs,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.driveSignOut,
              icon: const Icon(Icons.logout),
              onPressed: canAct ? _signOut : null,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataSectionLabel(l10n.driveSectionTitle, first: widget.firstInColumn),
        SettingsGroup(children: [row]),
      ],
    );
  }
}
