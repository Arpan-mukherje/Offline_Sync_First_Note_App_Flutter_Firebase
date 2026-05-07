import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  static final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  static Stream<bool> get onlineStream => _onlineController.stream;

  // Start as false — real state is set after the internet probe in init().
  static bool _isOnline = false;
  static bool get isOnline => _isOnline;

  static StreamSubscription? _subscription;
  static Timer? _retryTimer;

  static Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    final hasInterface = _isConnected(result);


    if (hasInterface) {
      unawaited(_probeAndEmit(initialLaunch: true));
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      _retryTimer?.cancel();
      if (!_isConnected(results)) {
        // Interface is gone — go offline immediately.
        if (_isOnline) {
          _isOnline = false;
          _onlineController.add(false);
        }
        return;
      }
      // Interface came back up — verify actual internet before going online.
      await _probeAndEmit(initialLaunch: false);
    });
  }


  static Future<void> _probeAndEmit({required bool initialLaunch}) async {
    if (initialLaunch) {
      // Allow runApp() → first frame → BlocProvider.create → subscription.
      await Future.delayed(const Duration(milliseconds: 400));
    }

    final reachable = await _checkInternet();
    if (reachable) {
      _isOnline = true;
      // Added by Arpan
      // Always emit true (even if already true) so ConnectivityChanged(true)
      // → SyncNow → fetchAllNotes runs every time the network becomes usable,
      // including the first time on WiFi when Firestore wasn't ready yet.
      _onlineController.add(true);
    } else {
      if (_isOnline) {
        _isOnline = false;
        _onlineController.add(false);
      }
      _scheduleRetry();
    }
  }

  /// DNS lookup to confirm real internet access. Times out in 5 s.
  static Future<bool> _checkInternet() async {
    try {
      final addrs = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return addrs.isNotEmpty && addrs.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Polls every 3 s until internet is reachable, then emits true.
  static void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (await _checkInternet()) {
        timer.cancel();
        _isOnline = true;
        _onlineController.add(true);
      }
    });
  }

  static bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }

  static void dispose() {
    _retryTimer?.cancel();
    _subscription?.cancel();
    _onlineController.close();
  }
}
