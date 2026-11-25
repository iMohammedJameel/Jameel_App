import 'package:jameel/models/user_model.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';

/// The signed-in employee for the current app session (`null` when signed out).
///
/// Kept as a top-level variable for now because many screens read it; the
/// natural next step is to expose it through an injected session cubit.
JameelUserModel? userModel;

Future<JameelUserModel?> getUserDataLocally() => CacheHelper.getCachedUser();
