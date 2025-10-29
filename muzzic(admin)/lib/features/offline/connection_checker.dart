import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConnectionChecker extends StatefulWidget {
  const ConnectionChecker({super.key});

  @override
  State<ConnectionChecker> createState() => _ConnectionCheckerState();
}

class _ConnectionCheckerState extends State<ConnectionChecker> {
  final Connectivity _connectivity = Connectivity();
  late Stream<List<ConnectivityResult>> _connectivityStream;

  Future<void> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _navigate(result);
  }

  void _navigate(List<ConnectivityResult> result) {
    final hasConnection = result.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      Navigator.pushReplacementNamed(context, '/online');
    } else {
      Navigator.pushReplacementNamed(context, '/offline');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
        stream: _connectivityStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final results = snapshot.data!;
          final hasConnection = results.any((r) => r != ConnectivityResult.none);

          Future.microtask(() {
            if (hasConnection) {
              Navigator.pushReplacementNamed(context, '/online');
            } else {
              Navigator.pushReplacementNamed(context, '/offline');
            }
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
    );
  }
}
