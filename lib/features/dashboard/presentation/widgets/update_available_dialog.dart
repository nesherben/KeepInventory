import 'package:flutter/material.dart';
import 'package:keepinventory/l10n/app_localizations_ext.dart';

typedef UpdateDownloadCallback = Future<bool> Function(
  String url,
  ValueChanged<double> onProgress,
);

class UpdateAvailableDialog extends StatefulWidget {
  const UpdateAvailableDialog({
    super.key,
    required this.version,
    required this.notes,
    required this.url,
    required this.download,
    required this.onDownloadFailure,
  });

  final String version;
  final String notes;
  final String url;
  final UpdateDownloadCallback download;
  final VoidCallback onDownloadFailure;

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  double _progress = 0;
  bool _isDownloading = false;

  Future<void> _downloadUpdate() async {
    setState(() => _isDownloading = true);
    final success = await widget.download(widget.url, (progress) {
      if (mounted) setState(() => _progress = progress);
    });

    if (!mounted) return;
    Navigator.pop(context);
    if (!success) widget.onDownloadFailure();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(context.l10n.updateAvailableTitle(widget.version)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.updateAvailableBody,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(
                widget.notes,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.l10n.updateDownloading(
                  (_progress * 100).toStringAsFixed(0),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.later),
          ),
          ElevatedButton(
            onPressed: _downloadUpdate,
            child: Text(context.l10n.updateNow),
          ),
        ],
      ],
    );
  }
}
