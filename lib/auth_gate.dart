import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'in_game_page.dart';
import 'login_page.dart';
import 'table_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.firebaseReady,
    this.repository,
    super.key,
  });

  final bool firebaseReady;
  final TableRepository? repository;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return LoginPage(firebaseReady: firebaseReady);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingPage();
        }
        final user = snapshot.data;
        if (user == null) return LoginPage(firebaseReady: firebaseReady);
        return _AuthenticatedDestination(
          key: ValueKey(user.uid),
          repository: repository ?? TableRepository(),
        );
      },
    );
  }
}

class _AuthenticatedDestination extends StatefulWidget {
  const _AuthenticatedDestination({required this.repository, super.key});

  final TableRepository repository;

  @override
  State<_AuthenticatedDestination> createState() =>
      _AuthenticatedDestinationState();
}

class _AuthenticatedDestinationState extends State<_AuthenticatedDestination> {
  late Future<ActiveTableInfo?> _activeTable;

  @override
  void initState() {
    super.initState();
    _activeTable = widget.repository.findPlayingTableForCurrentUser();
  }

  void _retry() {
    setState(() {
      _activeTable = widget.repository.findPlayingTableForCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ActiveTableInfo?>(
      future: _activeTable,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingPage();
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '対局中の卓を確認できませんでした。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('再試行'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const HomePage(),
                        ),
                      ),
                      child: const Text('ホームへ進む'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final active = snapshot.data;
        if (active == null) return const HomePage();

        final membersByUid = {
          for (final member in active.members) member.uid: member,
        };
        final startingPoints =
            (active.table.settings['startingPoints'] as num?)?.toInt() ??
                25000;
        const winds = ['東', '南', '西', '北'];
        final players = <GamePlayer>[];
        for (final wind in winds) {
          final uid = active.seats[wind];
          if (uid == null) continue;
          players.add(
            GamePlayer(
              uid: uid,
              wind: wind,
              name: membersByUid[uid]?.displayName ?? 'ユーザー',
              score: startingPoints,
              isDealer: wind == '東',
            ),
          );
        }

        return InGamePage(
          tableName: active.table.name,
          players: players,
          startingPoints: startingPoints,
          tableId: active.table.id,
          currentUserUid: widget.repository.currentUserUid,
          repository: widget.repository,
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
