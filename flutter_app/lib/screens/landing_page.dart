import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

TextStyle headingStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
TextStyle descStyle = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w400,
    color: Colors.grey[800]);
TextStyle buttonStyle = TextStyle(fontSize: 16);
// ButtonStyle buttonStyle = ButtonStyle(elevation: ,);

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    "Ink & Insight",
                    style: headingStyle,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Where readers discover, review and share books they love. Thoughful reviews, personal favorites, and a community built on stories.",
                    textAlign: TextAlign.center,
                    style: descStyle,
                  ),
                ],
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: Text(
                      "Sign up",
                      style: buttonStyle,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text(
                      "Log in",
                      style: buttonStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
