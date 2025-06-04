import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/screens/auth/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

OutlineInputBorder border = OutlineInputBorder(
  borderSide: BorderSide(
    color: Colors.black,
    width: 1.5,
  ),
  borderRadius: BorderRadius.circular(8),
);

InputDecoration inputDecor(String hintText) => InputDecoration(
      hintText: hintText,
      errorBorder: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border,
    );

class _LoginPageState extends State<LoginPage> {
  // controllers
  final TextEditingController _usernameController = TextEditingController();
  // no email controller for log in
  final TextEditingController _passwordController = TextEditingController();

  String errorText = "";

  final Dio _dio = Dio();

  Future<void> _login({required AuthCubit authCubit}) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        errorText = "Username and password cannot be empty";
      });
      return;
    }

    try {
      final response = await _dio.post(
        'http://192.168.10.39:18080/login',
        data: {
          "username": username,
          "password": password,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      // handle success
      if (response.statusCode == 200) {
        print("Login successful ${response.data}");
        authCubit.login(username: username);
        setState(() {
          errorText = "";
        });

        // wait for a bit
        await Future.delayed(Duration(milliseconds: 500));

        // setState(() {
        //   errorText = "Logged in yay!";
        // });

        if (!mounted) return;
        // take user to books screen
        context.go('/books');
      }
    } on DioException catch (e) {
      setState(() {
        errorText = e.response?.data.toString() ??
            "Could not connect to server: ${e.message}";
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final AuthCubit authCubit = context.read<AuthCubit>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Login"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // username text field
              TextField(
                controller: _usernameController,
                decoration: inputDecor("Enter your username here..."),
              ),

              SizedBox(height: 10),

              // password text field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: inputDecor("Enter your password here..."),
              ),

              SizedBox(height: 5),

              // error text
              Text(
                errorText,
                style: TextStyle(color: Colors.red),
              ),

              SizedBox(height: 5),

              // log in button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _login(authCubit: authCubit),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Log in"),
                ),
              ),

              SizedBox(height: 5),

              GestureDetector(
                onTap: () => context.go('/signup'),
                child: Text(
                  "Sign up instead",
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
