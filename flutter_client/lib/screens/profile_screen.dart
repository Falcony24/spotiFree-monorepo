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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            SwitchListTile(
              title: Text(t.offlineMode),
              value: modeProvider.isOfflineMode,
              onChanged: modeProvider.hasInternet
                  ? (value) => modeProvider.setOfflineMode(value)
                  : null,
              secondary: Icon(
                modeProvider.hasInternet ? Icons.offline_bolt : Icons.wifi_off,
                color: modeProvider.hasInternet ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(t.logout),
              onTap: () async {
                await playerProvider.stop();
                await authProvider.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}