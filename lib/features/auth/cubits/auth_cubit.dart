import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await AuthService.login(email: email, password: password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void logout() {
    // Perform any local cleanup if necessary
    emit(Unauthenticated());
  }
}
