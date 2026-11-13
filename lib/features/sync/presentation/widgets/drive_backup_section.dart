import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/backup_coordinator.dart';
import '../../../../core/services/drive_backup_service.dart';
import '../../../../core/services/local_backup_service.dart';
import '../../../../core/shared_widgets/app_alerts.dart';
import '../../../../core/shared_widgets/app_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/backup_formatters.dart';
import '../backup_restore_flow.dart';
import 'settings_group.dart';

/// Sección "Google Drive" de Gestión de datos. Todo es manual: iniciar sesión
/// y subir la copia (sobrescribe la anterior). Restaurar está en "Restaurar
/// copia", junto a las copias del móvil.
class DriveBackupSection extends StatefulWidget {
  const DriveBackupSection({
    super.key,
    this.enabled = true,
    this.firstInColumn = false,
  });

  final bool enabled;

  /// Primera sección de su columna (en tablet): sin hueco arriba.
  final bool firstInColumn;

  @override
  State<DriveBackupSection> createState() => _DriveBackupSectionState();
}

class _DriveBackupSectionState extends State<DriveBackupSection> {
  final _service = DriveBackupService();
  bool _busy = false;
  bool _uploading = false;
  bool _unsaved = false;

  @override
  void initState() {
    super.initState();
    BackupCoordinator.revision.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    BackupCoordinator.revision.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final signature = await LocalBackupService.currentSignature();
      if (!mounted) return;
      setState(() {
        // Rojo cuando hay cambios que no están en la última copia de Drive
        _unsaved =
            signature != null && signature != AppPreferences.lastDriveSignature;
      });
    } catch (e) {
      debugPrint('No se pudo leer el estado de Drive: $e');
    }
  }

  void _showError(Object error) => showDriveError(context, error);

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await DriveBackupService.signIn();
    } catch (e) {
      _showError(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _signOut() async {
    await DriveBackupService.signOut();
    if (mounted) setState(() {});
  }

  Future<void> _upload() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _uploading = true;
    });
    try {
      await _service.upload();
      if (mounted) AppAlerts.showSuccess(context, context.l10n.driveUploadDone);
    } catch (e) {
      _showError(e);
    }
    await BackupCoordinator.refresh();
    if (mounted) {
      setState(() {
        _busy = false;
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final canAct = widget.enabled && !_busy;
    final email = AppPreferences.driveEmail;
    final lastUpload = AppPreferences.lastDriveBackupAt;

    final List<Widget> rows;
    if (email == null) {
      rows = [
        SettingsRow(
          icon: Icons.add_to_drive_outlined,
          title: l10n.driveSignIn,
          subtitle: l10n.driveSignInSubtitle,
          loading: _busy,
          onTap: canAct ? _signIn : null,
        ),
      ];
    } else {
      rows = [
        // Cuenta conectada, con su inicial y "Cerrar sesión"
        Padding(
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
        ),
        // En amarillo cuando hay cambios que no están en la copia de Drive
        // (el rojo queda solo para borrar)
        SettingsRow(
          icon: Icons.cloud_upload_outlined,
          title: l10n.driveUploadTitle,
          subtitle: _unsaved
              ? l10n.driveUnsavedWarning
              : lastUpload == null
              ? l10n.driveNeverUploaded
              : l10n.driveLastUpload(
                  formatBackupDate(
                    context,
                    DateTime.fromMillisecondsSinceEpoch(lastUpload),
                  ),
                ),
          subtitleColor: _unsaved ? AppColors.warning : null,
          iconColor: _unsaved ? AppColors.warning : null,
          loading: _uploading,
          onTap: canAct ? _upload : null,
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataSectionLabel(l10n.driveSectionTitle, first: widget.firstInColumn),
        SettingsGroup(children: rows),
      ],
    );
  }
}
