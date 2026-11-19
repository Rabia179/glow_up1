import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/google_drive_backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  final GoogleDriveBackupService? backupService;
  final VoidCallback? onDataRestored;

  const BackupRestoreScreen({
    super.key,
    this.backupService,
    this.onDataRestored,
  });

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late final GoogleDriveBackupService _backupService;

  List<DriveBackupItem> _backups = [];
  bool _isSigningIn = false;
  bool _isBackingUp = false;
  bool _isLoadingBackups = false;
  String? _restoringFileId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _backupService = widget.backupService ?? GoogleDriveBackupService();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final account = await _backupService.signInSilently();
    if (account != null) {
      await _fetchBackups();
    } else {
      if (mounted) {
        setState(() {
          _isLoadingBackups = false;
        });
      }
    }
  }

  Future<void> _fetchBackups() async {
    if (!_backupService.isSignedIn) return;

    setState(() {
      _isLoadingBackups = true;
      _errorMessage = null;
    });

    try {
      final items = await _backupService.fetchBackups();
      if (mounted) {
        setState(() {
          _backups = items;
          _isLoadingBackups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to list Google Drive backups: ${e.toString()}';
          _isLoadingBackups = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      final account = await _backupService.signIn();
      if (account != null) {
        await _fetchBackups();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google Sign-In failed or was cancelled.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _backupService.signOut();
    if (mounted) {
      setState(() {
        _backups = [];
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleBackup() async {
    if (!_backupService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your Google account first.')),
      );
      return;
    }

    setState(() {
      _isBackingUp = true;
      _errorMessage = null;
    });

    try {
      final backup = await _backupService.performBackup();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup uploaded to Google Drive! (${backup.formattedSize})'),
        ),
      );

      await _fetchBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _confirmAndRestore(DriveBackupItem backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Restore Database?', style: AppTextStyles.headlineSm()),
        content: Text(
          'Restoring will replace your current local products, cart, wishlist, orders, and profile with the backup created on ${backup.formattedDate}.\n\nYour current data will be overwritten.',
          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.labelLg(color: AppColors.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _restoringFileId = backup.id;
      });

      try {
        await _backupService.restoreBackup(backup);
        widget.onDataRestored?.call();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database restored successfully from Google Drive!')),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _restoringFileId = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _backupService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Google Drive Backup',
          style: AppTextStyles.headlineSm().copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Google Account Connection Card
            _buildGoogleAuthCard(user),

            const SizedBox(height: 20),

            // 2. Local Database Engine Info Card
            _buildLocalDatabaseCard(),

            const SizedBox(height: 20),

            // 3. Backup Trigger Action Button
            _buildBackupActionCard(),

            const SizedBox(height: 24),

            // 4. Available Cloud Backups List
            Text(
              'CLOUD BACKUPS IN GOOGLE DRIVE',
              style: AppTextStyles.labelMd(color: AppColors.onSurface)
                  .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),

            const SizedBox(height: 12),

            _buildBackupsListSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleAuthCard(GoogleSignInAccount? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user != null ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? 'Google Drive Connected' : 'Google Account Disconnected',
                      style: AppTextStyles.titleMd().copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      user != null ? user.email : 'Sign in to access your GLOW_UP_Backups folder',
                      style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: user != null
                ? OutlinedButton.icon(
                    onPressed: _handleSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('DISCONNECT ACCOUNT'),
                  )
                : ElevatedButton.icon(
                    onPressed: _isSigningIn ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                    ),
                    icon: _isSigningIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded, size: 18),
                    label: Text(
                      'CONNECT GOOGLE ACCOUNT',
                      style: AppTextStyles.labelLg(color: AppColors.onPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalDatabaseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local SQLite Database (glow_up.db)',
                  style: AppTextStyles.titleMd().copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  '7 Schema Tables • Foreign Keys Enabled',
                  style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupActionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Cloud Backup',
            style: AppTextStyles.titleMd().copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Copies your local products, cart items, wishlist, orders, and profile, then uploads a timestamped database file to GLOW_UP_Backups in Drive.',
            style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isBackingUp ? null : _handleBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              icon: _isBackingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 20),
              label: Text(
                'BACK UP TO GOOGLE DRIVE',
                style: AppTextStyles.labelLg(color: AppColors.onPrimary)
                    .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsListSection() {
    if (!_backupService.isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 36, color: AppColors.outlineVariant),
            const SizedBox(height: 8),
            Text(
              'Google Sign-In Required',
              style: AppTextStyles.titleMd().copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in above to list and restore existing database backups from your Google Drive.',
              style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoadingBackups) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(_errorMessage!, style: AppTextStyles.bodySm(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchBackups,
              child: const Text('Retry Fetching Backups'),
            ),
          ],
        ),
      );
    }

    if (_backups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.outlineVariant),
            const SizedBox(height: 8),
            Text(
              'No Backups Found',
              style: AppTextStyles.titleMd().copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'No backup database files found in your GLOW_UP_Backups Drive folder.',
              style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _backups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _backups[index];
        final isRestoring = _restoringFileId == item.id;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.titleMd().copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.formattedDate} • ${item.formattedSize}',
                      style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: isRestoring ? null : () => _confirmAndRestore(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: isRestoring
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                        )
                      : Text(
                          'RESTORE',
                          style: AppTextStyles.labelSm(color: AppColors.onPrimary)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
