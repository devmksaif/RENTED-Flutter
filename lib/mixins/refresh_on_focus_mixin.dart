import 'package:flutter/material.dart';

/// Mixin that automatically refetches data when the screen comes into focus
/// Use this to ensure data is always fresh when navigating back to a screen
mixin RefreshOnFocusMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  /// Override this method in your screen to implement the refresh logic
  Future<void> onRefresh();

  /// Tracks if this is the first load (to avoid double-loading on init)
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed && !_isFirstLoad) {
      onRefresh();
    }
    
    if (_isFirstLoad) {
      _isFirstLoad = false;
    }
  }

  /// Call this method to trigger a refresh
  Future<void> triggerRefresh() async {
    await onRefresh();
  }
}

/// Mixin using RouteAware for navigation-based refresh
/// This refreshes when navigating to/back to the screen
/// Requires RouteObserver to be set up in MaterialApp
mixin RefreshOnNavigationMixin<T extends StatefulWidget> on State<T> {
  /// Override this method in your screen to implement the refresh logic
  Future<void> onNavigationRefresh();

  /// Flag to track if initial load is done
  bool _initialLoadDone = false;

  /// RouteObserver instance - should be set in main.dart
  static RouteObserver<PageRoute>? routeObserver;

  /// RouteAware instance to handle route lifecycle
  late final _RouteAwareHandler _routeAwareHandler;

  @override
  void initState() {
    super.initState();
    _initialLoadDone = false;
    _routeAwareHandler = _RouteAwareHandler(
      onPush: () {
        if (_initialLoadDone && mounted) {
          onNavigationRefresh();
        }
        _initialLoadDone = true;
      },
      onPopNext: () {
        if (_initialLoadDone && mounted) {
          onNavigationRefresh();
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute && routeObserver != null) {
      routeObserver!.subscribe(_routeAwareHandler, route);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    if (routeObserver != null) {
      routeObserver!.unsubscribe(_routeAwareHandler);
    }
    super.dispose();
  }
}

/// Internal RouteAware handler
class _RouteAwareHandler extends RouteAware {
  final VoidCallback onPush;
  final VoidCallback onPopNext;

  _RouteAwareHandler({required this.onPush, required this.onPopNext});

  @override
  void didPush() {
    onPush();
  }

  @override
  void didPopNext() {
    onPopNext();
  }
}
