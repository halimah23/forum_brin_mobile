import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Set user langsung jika sudah tersedia
  void setUser(UserModel user) {
    emit(Authenticated(user));
  }

  /// Logout dari sesi saat ini
  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await AuthService.logout();
    } catch (_) {}
    emit(Unauthenticated());
  }
}
