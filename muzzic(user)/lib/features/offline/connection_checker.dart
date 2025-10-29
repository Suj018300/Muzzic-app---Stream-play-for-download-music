import 'package:client/features/offline/offline_page.dart';
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
  bool _navigated = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _initialCheck();
  }

  Future<void> _initialCheck() async {
    // Wait a small delay to ensure context is ready
    await Future.delayed(const Duration(milliseconds: 500));
    final results = await _connectivity.checkConnectivity();
    _handleNavigation(results);
  }

  void _handleNavigation(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (_navigated || !mounted) return; // Prevent multiple navigations
    _navigated = true;

    if (hasConnection) {
      Navigator.pushReplacementNamed(context, '/online');
    } else {
      Navigator.pushReplacementNamed(context, '/offline');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
        stream: _connectivityStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!;
        final hasConnection = results.any((r) => r != ConnectivityResult.none);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNavigation(results);
        });

        return _buildStatusUI(hasConnection);
        }
    );
  }
  Widget _buildStatusUI(bool connected) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            connected ? Icons.wifi : Icons.wifi_off,
            size: 80,
            color: connected ? Colors.greenAccent : Colors.deepOrangeAccent,
          ),
          const SizedBox(height: 20),
          Text(
            connected ? "Online" : "Offline",
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
