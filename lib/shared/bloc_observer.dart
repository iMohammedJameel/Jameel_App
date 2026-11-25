import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Central place for bloc diagnostics. Cubits report unexpected failures with
/// `addError(error, stackTrace)`, and they all end up here, which is also where
/// a crash-reporting service (e.g. Crashlytics) would be hooked in.
class MyBlocObserver extends BlocObserver {
  const MyBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('[${bloc.runtimeType}] $error\n$stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}
