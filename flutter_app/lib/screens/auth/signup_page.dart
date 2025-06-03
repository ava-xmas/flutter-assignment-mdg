import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
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

class _SignupPageState extends State<SignupPage> {
  // controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String errorText = "";

  final Dio _dio = Dio();

  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      setState(() {
        errorText = "Username, email and password cannot be empty";
      });
      return;
    }

    try {
      final response = await _dio.post(
        'http://192.168.10.39:18080/register',
        data: {
          "username": username,
          "email": email,
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
        print("Sign up successfull ${response.data}");
        setState(() {
          errorText = "";
        });
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Sign up"),
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

              // email text field
              TextField(
                controller: _emailController,
                decoration: inputDecor("Enter your email here..."),
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
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Sign up"),
                ),
              ),

              SizedBox(height: 5),

              Text(
                "Login instead",
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
