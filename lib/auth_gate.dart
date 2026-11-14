import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'login_page.dart';
import 'table_lobby_page.dart';
import 'table_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return LoginPage(firebaseReady: firebaseReady);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          return AuthenticatedHomeGate(uid: snapshot.data!.uid);
        }
        return LoginPage(firebaseReady: firebaseReady);
      },
    );
  }
}


/// ログイン後、自分が参加している対局中の卓があれば再開する。
class AuthenticatedHomeGate extends StatefulWidget {
  const AuthenticatedHomeGate({
    required this.uid,
    this.repository,
    this.homePage,
    super.key,
  });

  final String uid;
  final TableRepository? repository;
  final Widget? homePage;

  @override
  State<AuthenticatedHomeGate> createState() => _AuthenticatedHomeGateState();
}

class _AuthenticatedHomeGateState extends State<AuthenticatedHomeGate> {
  late final TableRepository _repository;
  late Future<TableInfo?> _playingTableFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TableRepository();
    _playingTableFuture = _repository.findPlayingTableForCurrentUser();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedHomeGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uid != oldWidget.uid) {
      _playingTableFuture = _repository.findPlayingTableForCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TableInfo?>(
      future: _playingTableFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final table = snapshot.data;
        if (snapshot.hasError || table == null) {
          if (snapshot.hasError) {
            debugPrint('Failed to find a playing table: ${snapshot.error}');
          }
          return widget.homePage ?? const HomePage();
        }

        return TableLobbyPage(
          tableId: table.id,
          tableName: table.name,
          playerCount: table.playerCount,
          settings: table.settings,
          ownerName: table.ownerName,
          currentUserUid: widget.uid,
          repository: _repository,
        );
      },
    );
  }
}
