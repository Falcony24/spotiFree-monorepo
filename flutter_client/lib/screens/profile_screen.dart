import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/providers/auth_provider.dart';
import 'package:spotifree/providers/mode_provider.dart';
import 'package:spotifree/providers/player_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final modeProvider = Provider.of<ModeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withAlpha(120),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 44, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(
              'User',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 48),

            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(t.offlineMode, style: theme.textTheme.titleMedium),
                subtitle: Text(
                  modeProvider.hasInternet
                      ? 'Downloaded tracks available offline'
                      : 'No internet connection',
                  style: theme.textTheme.bodySmall,
                ),
                value: modeProvider.isOfflineMode,
                onChanged: modeProvider.hasInternet
                    ? (value) => modeProvider.setOfflineMode(value)
                    : null,
                secondary: Icon(
                  modeProvider.hasInternet ? Icons.wifi : Icons.wifi_off,
                  color: modeProvider.hasInternet
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha(100),
                ),
                activeTrackColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await playerProvider.stop();
                  await authProvider.logout();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text(t.logout),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withAlpha(80)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}