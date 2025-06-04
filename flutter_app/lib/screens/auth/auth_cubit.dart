import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthStatus { authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? username;

  AuthState({required this.status, required this.username});

  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated, username: "Guest");

  factory AuthState.authenticated({required String username}) =>
      AuthState(status: AuthStatus.authenticated, username: username);
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState.unauthenticated());

  void login({required String username}) {
    emit(AuthState.authenticated(username: username));
  }

  void logout() {
    emit(AuthState.unauthenticated());
  }
}
