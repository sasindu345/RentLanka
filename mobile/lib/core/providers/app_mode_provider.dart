import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserAppMode { renter, owner }

final appModeProvider = StateProvider<UserAppMode>((ref) {
  return UserAppMode.renter;
});
