import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Widgets/cover.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/noData_widget.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../l10n/app_localizations.dart';
import 'bloc/backup_bloc.dart';

class BackupView extends StatelessWidget {
  /// Outer padding for the whole backup widget. Defaults to [EdgeInsets.zero]
  /// so the widget can be embedded (e.g. on the Dashboard) without any
  /// extra margin of its own. Pass a non-zero value for standalone pages.
  final EdgeInsets padding;

  /// Whether the "Browse / Restore from file" button is shown.
  /// On the Dashboard you usually want this `false` — the file picker
  /// inside a cramped right rail is awkward.
  final bool showBrowse;

  const BackupView({
    super.key,
    this.padding = EdgeInsets.zero,
    this.showBrowse = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(padding: padding, showBrowse: showBrowse),
      tablet: _Tablet(padding: padding, showBrowse: showBrowse),
      desktop: _Desktop(padding: padding, showBrowse: showBrowse),
    );
  }
}

class _Mobile extends StatelessWidget {
  final EdgeInsets padding;
  final bool showBrowse;
  const _Mobile({required this.padding, required this.showBrowse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: _BackupContent(showBrowse: showBrowse),
    );
  }
}

class _Tablet extends StatelessWidget {
  final EdgeInsets padding;
  final bool showBrowse;
  const _Tablet({required this.padding, required this.showBrowse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: _BackupContent(showBrowse: showBrowse),
    );
  }
}

class _Desktop extends StatefulWidget {
  final EdgeInsets padding;
  final bool showBrowse;
  const _Desktop({required this.padding, required this.showBrowse});

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  @override
  void initState() {
    super.initState();
    context.read<BackupBloc>().add(LoadBackupsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: _BackupContent(showBrowse: widget.showBrowse),
    );
  }
}

class _BackupContent extends StatelessWidget {
  final bool showBrowse;
  const _BackupContent({required this.showBrowse});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, tr),
          const SizedBox(height: 10),
          _buildRecentBackupHeader(context, tr),
          Expanded(
            child: _buildBackupList(context, tr),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER SECTION
  // ============================================================
  Widget _buildHeader(BuildContext context, AppLocalizations tr) {
    return ZCover(
      radius: 7,
      color: Theme.of(context).colorScheme.primary.withAlpha(10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.databaseBackup.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              tr.downloadBackupMsg,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontSize: context.scaledFont(0.008),
              ),
            ),
            const SizedBox(height: 15),
            _buildActionButtons(context, tr),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS (Download & Browse) — Browse is optional
  // ============================================================
  Widget _buildActionButtons(BuildContext context, AppLocalizations tr) {
    return BlocConsumer<BackupBloc, BackupState>(
      listener: (context, state) {
        if (state is BackupDownloadSuccess) {
          ToastManager.show(
            title: tr.backup,
            context: context,
            message: 'Backup downloaded to: ${state.filePath}',
            type: ToastType.success,
          );
        }
        if (state is BackupError) {
          ToastManager.show(
            title: tr.errorTitle,
            context: context,
            message: state.message,
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is BackupLoading || state is BackupInProgress;

        return Row(
          spacing: 8,
          children: [
            ZOutlineButton(
              height: 45,
              isActive: true,
              onPressed: isLoading
                  ? null
                  : () {
                context.read<BackupBloc>().add(DownloadBackupEvent());
              },
              icon: Icons.cloud_download_outlined,
              label: isLoading
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                tr.downloadBackup,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (showBrowse)
              ZOutlineButton(
                height: 45,
                onPressed: isLoading
                    ? null
                    : () {
                  _showBrowseRestoreDialog(context);
                },
                icon: Icons.folder_outlined,
                label: Text(
                  tr.browse,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // RECENT BACKUP HEADER
  // ============================================================
  Widget _buildRecentBackupHeader(BuildContext context, AppLocalizations tr) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        spacing: 10,
        children: [
          Icon(
            Icons.access_time_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          Text(
            tr.recentBackup,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BACKUP LIST
  // ============================================================
  Widget _buildBackupList(BuildContext context, AppLocalizations tr) {
    return BlocConsumer<BackupBloc, BackupState>(
      listener: (context, state) {
        _handleStateChanges(context, state, tr);
      },
      builder: (context, state) {
        if (state is BackupLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BackupInProgress) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.creatingBackupMsg),
              ],
            ),
          );
        }

        if (state is RestoreAfterBackupProgress) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (state is BackupRestoreProgress) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (state is BackupsLoaded) {
          if (state.backups.isEmpty) {
            return Center(
              child: NoDataWidget(
                message: tr.noDataFound,
                onRefresh: () {
                  context.read<BackupBloc>().add(LoadBackupsEvent());
                },
              ),
            );
          }

          return ListView.builder(
            itemCount: state.backups.length,
            itemBuilder: (context, index) {
              final file = state.backups[index];
              return _buildBackupItem(context, file, tr);
            },
          );
        }

        if (state is BackupError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        return const Center(child: Text('No data available'));
      },
    );
  }

  // ============================================================
  // BACKUP ITEM
  // ============================================================
  Widget _buildBackupItem(
      BuildContext context, FileSystemEntity file, AppLocalizations tr) {
    final fileStat = file.statSync();
    final fileName = file.path.split(Platform.pathSeparator).last;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ZCover(
        radius: 5,
        color: Theme.of(context).colorScheme.surface,
        child: ListTile(
          leading: ZCover(
            color: Theme.of(context).colorScheme.primary.withAlpha(10),
            padding: const EdgeInsets.all(7),
            radius: 5,
            child: Icon(
              Icons.table_rows_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            fileName,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Size: ${_formatBytes(fileStat.size)}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                file.path,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.primary,
            ),
            onSelected: (value) {
              switch (value) {
                case 'restore':
                  _showRestoreDialog(context, file.path);
                  break;
                case 'rename':
                  _showRenameDialog(context, file.path);
                  break;
                case 'delete':
                  _showDeleteDialog(context, file.path);
                  break;
                case 'folder':
                  _openFolder(context, file.path);
                  break;
                case 'info':
                  _showFileInfo(context, file.path);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    const Icon(Icons.restore, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(tr.restoreBackup),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(tr.renameTitle),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'folder',
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_open,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text("showInFolder"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text("fileInfo"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(tr.delete),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATE CHANGE HANDLER
  // ============================================================
  void _handleStateChanges(
      BuildContext context, BackupState state, AppLocalizations tr) {
    if (state is BackupDownloadSuccess) {
      context.read<BackupBloc>().add(LoadBackupsEvent());
    }

    if (state is BackupDeleteSuccess) {
      ToastManager.show(
        title: tr.delete,
        context: context,
        message: "Backup file deleted",
        type: ToastType.success,
      );
      context.read<BackupBloc>().add(LoadBackupsEvent());
    }

    if (state is BackupRenameSuccess) {
      ToastManager.show(
        title: tr.renameTitle,
        context: context,
        message: tr.successMsg,
        type: ToastType.success,
      );
      context.read<BackupBloc>().add(LoadBackupsEvent());
    }

    if (state is BackupRestoreSuccess) {
      ToastManager.show(
        title: tr.restoreComplete,
        context: context,
        message: tr.restoreSuccessMsg,
        type: ToastType.success,
      );
      context.read<BackupBloc>().add(LoadBackupsEvent());
    }

    if (state is BackupError) {
      ToastManager.show(
        title: tr.errorTitle,
        context: context,
        message: state.message,
        type: ToastType.error,
      );
    }
  }

  // ============================================================
  // BROWSE & RESTORE DIALOG
  // ============================================================
  void _showBrowseRestoreDialog(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Row(
          children: [
            Icon(
              Icons.folder_open,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(tr.restoreBackup),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "sqlMessage",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: .1),
                border: Border.all(color: Colors.orange.withValues(alpha: .3)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.creatingBackupMsg,
                      style: TextStyle(fontSize: 15, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr.cancel),
          ),
          ZOutlineButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BackupBloc>().add(PickAndRestoreBackupEvent());
            },
            isActive: true,
            icon: Icons.folder_open,
            label: Text(tr.browse),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESTORE DIALOG
  // ============================================================
  void _showRestoreDialog(BuildContext context, String filePath) {
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Row(
          children: [
            const Icon(Icons.restore, color: Colors.orange),
            const SizedBox(width: 8),
            Text(tr.restoreBackup),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: .1),
                border: Border.all(color: Colors.orange.withValues(alpha: .3)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.creatingBackupMsg,
                      style: TextStyle(fontSize: 15, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ZCover(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بازگردانی از دیتابیس',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filePath.split(Platform.pathSeparator).last,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr.cancel),
          ),
          ZOutlineButton(
            isActive: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BackupBloc>().add(RestoreBackupEvent(filePath));
            },
            icon: Icons.restore,
            label: Text(tr.restoreBackup),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE DIALOG
  // ============================================================
  void _showDeleteDialog(BuildContext context, String filePath) {
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Text(tr.delete),
        content: const Text("deleteMessage"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr.cancel),
          ),
          ZOutlineButton(
            isActive: true,
            backgroundHover: Theme.of(context).colorScheme.error,
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BackupBloc>().add(DeleteBackupEvent(filePath));
            },
            label: Text(tr.delete),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RENAME DIALOG
  // ============================================================
  void _showRenameDialog(BuildContext context, String filePath) {
    final file = File(filePath);
    final currentName = file.path.split(Platform.pathSeparator).last;
    final textController = TextEditingController(text: currentName);
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Text(tr.renameTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZTextFieldEntitled(
              controller: textController,
              title: "fileInfo",
              onFieldSubmitted: (value) {
                if (value.isNotEmpty && value != currentName) {
                  final parentDir = file.parent.path;
                  final newPath = '$parentDir${Platform.pathSeparator}$value';
                  context
                      .read<BackupBloc>()
                      .add(RenameBackupEvent(filePath, newPath));
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr.cancel),
          ),
          ZOutlineButton(
            isActive: true,
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                final parentDir = file.parent.path;
                final newPath = '$parentDir${Platform.pathSeparator}$newName';
                context
                    .read<BackupBloc>()
                    .add(RenameBackupEvent(filePath, newPath));
                Navigator.pop(dialogContext);
              }
            },
            label: Text(tr.renameTitle),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPEN FOLDER
  // ============================================================
  Future<void> _openFolder(BuildContext context, String filePath) async {
    final file = File(filePath);
    final directory = file.parent.path;

    try {
      Uri uri;

      if (Platform.isAndroid) {
        uri = Uri.parse('file://$directory');
      } else if (Platform.isIOS) {
        if (context.mounted) {
          _showFolderLocation(context, filePath);
        }
        return;
      } else if (Platform.isWindows) {
        uri = Uri.parse('file:///${directory.replaceAll('\\', '/')}');
      } else if (Platform.isMacOS) {
        uri = Uri.parse('file://$directory');
      } else {
        uri = Uri.parse('file://$directory');
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showFolderLocation(context, filePath);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showFolderLocation(context, filePath);
      }
    }
  }

  // ============================================================
  // FOLDER LOCATION DIALOG
  // ============================================================
  void _showFolderLocation(BuildContext context, String filePath) {
    final file = File(filePath);
    final directory = file.parent.path;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: const Text('Folder Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backup file is located in:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                directory,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isIOS
                  ? 'iOS doesn\'t support opening folders directly. You can find the file in the above path.'
                  : 'You can find this file in the above folder.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (!Platform.isIOS) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openFolder(context, filePath);
              },
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // FILE INFO DIALOG
  // ============================================================
  void _showFileInfo(BuildContext context, String filePath) {
    final file = File(filePath);
    final stat = file.statSync();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${file.path.split('/').last}'),
            Text('Path: ${file.path}'),
            Text('Size: ${_formatBytes(stat.size)}'),
            Text('Created: ${_formatDate(stat.accessed)}'),
            Text('Modified: ${_formatDate(stat.modified)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1048576).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}