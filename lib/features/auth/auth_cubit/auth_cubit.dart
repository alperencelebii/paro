import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<bool> {
  AuthCubit() : super(true);

  void changeAuth({required bool showLogin}) => emit(showLogin);
}
