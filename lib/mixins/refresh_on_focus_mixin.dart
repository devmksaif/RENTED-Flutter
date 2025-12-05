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

/// Alternative mixin using RouteAware for navigation-based refresh
/// This refreshes when navigating back to the screen
mixin RefreshOnNavigationMixin<T extends StatefulWidget> on State<T> {
  /// Override this method in your screen to implement the refresh logic
  Future<void> onNavigationRefresh();

  /// Flag to track if initial load is done
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    // Don't refresh on initial load
    _initialLoadDone = false;
  }

  /// Call this in your route's onGenerateRoute or when popping
  void handleNavigationReturn() {
    if (_initialLoadDone && mounted) {
      onNavigationRefresh();
    }
    _initialLoadDone = true;
  }

  /// Manually trigger refresh
  Future<void> manualRefresh() async {
    await onNavigationRefresh();
  }
}
