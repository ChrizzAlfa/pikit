import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pikit/main.dart';
import 'package:pikit/outlet.dart';
import 'package:pikit/signup.dart';
import 'package:pikit/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> userLogin(String email, String password) async {
    try {
      // Attempt to log in the user
      await pb.collection("users").authWithPassword(email, password);
      
      // Retrieve the current user's ID after successful login
      String? userId = pb.authStore.record?.id; // Ensure this is correctly set

      // Store the email, password, and user ID securely
      await _storage.write(key: 'email', value: email);
      await _storage.write(key: 'password', value: password);
      if (userId != null) {
        await _storage.write(key: 'user_id', value: userId);
      } else {
        // Handle the case where userId is null
        throw Exception("User  ID is null after login.");
      }
      return true;
    } catch (e) {
      // Handle any errors that occur during login
      return false; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        reverse: true,
        child: Column(
          children: [
            _buildStackText(context),
            const SizedBox(height: 172),
            Padding(
              padding: const EdgeInsets.all(18),
              child: _buildSignupButton(context),
            ),
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStackText(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/vectors/wave.svg',
          width: MediaQuery.of(context).size.width,
        ),
        const Positioned(
          top: 57,
          left: 26,
          child: Text(
            'WelCOmE To',
            style: TextStyle(
              fontSize: 30,
              fontFamily: 'Dirtyline',
            ),
          ),
        ),
        const Positioned(
          top: 70,
          left: 26,
          child: Text(
            'PIKIT',
            style: TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return SizedBox(
      width: 313,
      height: 32,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupPage()
        ),
      );
        },
        child: const Text("don't have an account?"),
      ),
    );
  }

  Widget _buildTextInput(String text, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(hintText: text),
      style: const TextStyle(color: AppColors.accent),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 61,
      child: TextButton(
        onPressed: () async {
          bool isLoggedIn = await userLogin(_emailController.text, _passwordController.text);
          if (isLoggedIn) {
            // Navigate to OutletPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OutletPage()),
            );
          } else {
            // Show an error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login failed. Please check your credentials.'),
              ),
            );
          }
        },
        child: const Text('login'),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 392,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [
                _buildTextInput('Email', _emailController),
                const SizedBox(height: 38.7),
                _buildTextInput('Password', _passwordController, isPassword: true),
              ],
            ),
          ),
          const Spacer(),
          _buildLoginButton(context),
          Padding(
            padding: const EdgeInsets.all(35),
            child: SvgPicture.asset(
              'assets/vectors/batik.svg',
              width: 269,
            ),
          ),
        ],
      ),
    );
  }
}