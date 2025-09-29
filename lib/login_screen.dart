import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // for JSON encoding/decoding

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreen();
}
class _LoginScreen extends State<LoginScreen> {


  bool _isLoading = false;
  String _message = "";
  final TextEditingController _login = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final ApiLogin = "https://rented-backend-api-production.up.railway.app/api/login";
  Future<void> postData() async {
    final url = Uri.parse(ApiLogin);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': _login.text,
          'password': _password.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Fluttertoast.showToast(msg: "Logged in successfully",
            toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
            gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        Fluttertoast.showToast(msg: response.statusCode.toString(),
            toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
            gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    } catch (e) {
      print('Exception: $e');
    }
  }


  void _performLogin() {

      if(_login.text.isEmpty  || _password.text.isEmpty ){
        Fluttertoast.showToast(msg: "Fields cannot be empty",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
        return;
      }


      _isLoading = true;
      postData();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🔹 Top left splash
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),
          // 🔹 Bottom right splash
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(200),
              ),
            ),
          ),
          // 🔹 Login form
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔹 Heading
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 🔹 Image with rounded corners & shadow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/login_vec.jpg',
                          width: 400,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 🔹 Email field
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _login,
                        decoration: InputDecoration(
                          hintText: "Email or phone",

                          prefixIcon:
                          const Icon(Icons.people_outlined, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 🔹 Password field
                    SizedBox(
                      width: 400,
                      child: TextField(
                        obscureText: true,
                        controller: _password,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon:
                          const Icon(Icons.lock_outlined, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // 🔹 Sign in button
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _performLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // 🔹 Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, "/register"),
                          child: const Text(
                            "Create one",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
