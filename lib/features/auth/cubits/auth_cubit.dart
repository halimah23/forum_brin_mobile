import 'package:flutter_bloc/flutter_bloc.dart';
import '../../notifications/services/notification_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  /// Memeriksa status login saat aplikasi dimulai (Auto-login)
  Future<void> checkAuthStatus() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        if (user.id != null && user.id!.isNotEmpty) {
          NotificationService.startRealtimeSubscription(user.id!);
        }
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  /// Login dengan email dan password
  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await AuthService.login(email: email, password: password);
      if (user.id != null && user.id!.isNotEmpty) {
        NotificationService.startRealtimeSubscription(user.id!);
      }
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Set user langsung jika sudah tersedia
  void setUser(UserModel user) {
    if (user.id != null && user.id!.isNotEmpty) {
      NotificationService.startRealtimeSubscription(user.id!);
    }
    emit(Authenticated(user));
  }

  /// Logout dari sesi saat ini
  Future<void> logout() async {
    emit(AuthLoading());
    try {
      NotificationService.stopRealtimeSubscription();
      await AuthService.logout();
    } catch (_) {}
    emit(Unauthenticated());
  }
}
