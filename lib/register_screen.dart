import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // for JSON encoding/decoding


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? accountType; // holds selected value

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();


  Future<void> sendData() async {
    final url = Uri.parse("https://rented-backend-api-production.up.railway.app/api/register");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': _firstName.text,
          'last_name': _password.text,
          'email' : _email.text,
          'phone': _phone.text,
          'password' : _password.text,
          'password_confirmation' : _confirmPassword.text,
          'role' : accountType?.toLowerCase()
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Fluttertoast.showToast(msg: "Registered successfully",
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
      Fluttertoast.showToast(msg: "Server error",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);

    }
}




  void _validateSubmit () {
    if(_firstName.text.isEmpty){
      Fluttertoast.showToast(msg: "First name cannot be empty.",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if(_lastName.text.isEmpty){
      Fluttertoast.showToast(msg: "Last name cannot be empty.",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if(_email.text.isEmpty){
      Fluttertoast.showToast(msg: "Email cannot be empty.",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if(_phone.text.isEmpty){
      Fluttertoast.showToast(msg: "Phone cannot be empty.",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if(_password.text.isEmpty){
      Fluttertoast.showToast(msg: "Password cannot be empty.",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if(_confirmPassword.text.isEmpty){
      Fluttertoast.showToast(msg: "Password confirm cannot be empty.",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if(_confirmPassword.text != _password.text){
      Fluttertoast.showToast(msg: "Passwords do not match.",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_LONG also works
          gravity: ToastGravity.TOP, // TOP, CENTER, BOTTOM
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
     sendData();
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
          // 🔹 Form content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔹 Heading
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 🔹 Image with rounded corners & shadow

                    const SizedBox(height: 30),
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _firstName,
                        decoration: InputDecoration(
                          hintText: "First name",
                          prefixIcon: Icon(Icons.person_2_outlined, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _lastName,
                        decoration: InputDecoration(
                          hintText: "Last name",
                          prefixIcon: Icon(Icons.person_2_outlined, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _email,
                        decoration: InputDecoration(
                          hintText: "Email",
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    // 🔹 Phone field
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _phone,
                        decoration: InputDecoration(
                          hintText: "Phone Number",
                          prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 🔹 Password field
                    SizedBox(
                      width: 400,
                      child: TextField(
                        obscureText: true,
                        controller: _password,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 🔹 Confirm Password field
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _confirmPassword,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Confirm Password",
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 400,
                      child: Column(
                          children: [
                            ListTile(
                              title: const Text("Buyer"),
                              leading: Radio<String>(
                                value: "Buyer",
                                groupValue: accountType,
                                onChanged: (value) {
                                  setState(() {
                                    accountType = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text("Seller"),
                              leading: Radio<String>(
                                value: "Seller",
                                groupValue: accountType,
                                onChanged: (value) {
                                  setState(() {
                                    accountType = value;
                                  });
                                },
                              ),
                            ),

                          ]
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 🔹 Sign Up button
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _validateSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // 🔹 Already have account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, "/login"),
                          child: const Text(
                            "Sign In",
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
