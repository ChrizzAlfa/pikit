import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pikit/main.dart';
import 'package:pikit/theme/app_colors.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String name = _nameController.text.trim();

    // Validate inputs
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields are required')),
        );
      }
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    if (!emailRegex.hasMatch(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')),
        );
      }
      return;
    }

    // Basic password validation
    if (password.length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 8 characters long')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user body
      final body = {
        "password": password,
        "passwordConfirm": password,
        "email": email,
        "emailVisibility": false,
        "verified": false,
        "name": name,
        "cart": []
      };

      // Create user in PocketBase
      await pb.collection('users').create(body: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome!')),
        );
        
        // Navigate to home page or dashboard
        Navigator.of(context).pushReplacementNamed('/home');  // Adjust route name as needed
      }

    } catch (e) {
      print('Signup error: $e');
      
      // Handle specific error cases
      String errorMessage = 'You May Login!';
      
      if (e.toString().contains('email')) {
        errorMessage = 'This email is already registered';
      } else if (e.toString().contains('password')) {
        errorMessage = 'Password is not strong enough';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            const SizedBox(height: 175),
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStackText(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset(width: MediaQuery.of(context).size.width, 'assets/vectors/wave.svg'),
        const Positioned(
          top: 57,
          left: 26,
          child: Text(
            'Welcome To',
            style: TextStyle(fontSize: 30, fontFamily: 'Dirtyline'),
          ),
        ),
        const Positioned(
          top: 70,
          left: 26,
          child: Text(
            'PIKIT',
            style: TextStyle(fontSize: 70, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.5,
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
                _buildTextInput('Name', _nameController),
                const SizedBox(height: 20),
                _buildTextInput('Email', _emailController),
                const SizedBox(height: 20),
                _buildTextInput('Password', _passwordController, obscureText: true),
              ],
            ),
          ),
          const Spacer(),
          _isLoading
              ? const CircularProgressIndicator(color: AppColors.accent)
              : _buildSignupActionButton(context),
          Padding(
            padding: const EdgeInsets.all(35),
            child: SvgPicture.asset(width: 269, 'assets/vectors/batik.svg'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(String hint, TextEditingController controller, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(hintText: hint),
      style: const TextStyle(color: AppColors.accent),
    );
  }

  Widget _buildSignupActionButton(context) {
    return SizedBox(
      width: 350,
      height: 61,
      child: TextButton(
        onPressed: _signup,
        child: const Text('sign up'),
      ),
    );
  }
}