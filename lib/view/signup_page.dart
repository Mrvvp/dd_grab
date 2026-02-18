import 'package:dd_grab/viewmodels/sign_up_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  @override
  void dispose() {
    // Clear text fields when the page is disposed
    // Note: We clear controllers through PopScope/back button instead
    // to avoid using ref after disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(signUpViewModelProvider);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Clear text fields when navigating back
          vm.clearControllers();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              vm.clearControllers();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 35),
                  Image.asset('assets/images/ddgrab_icon.png', height: 60),
                  const SizedBox(height: 24),
                  const Text(
                    'Sign up with Email',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up now to explore features, stay\nupdated, and enjoy seamless access!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // 🔤 Form fields
                  _buildField(vm.firstNameController, 'First Name'),
                  const SizedBox(height: 16),
                  _buildField(vm.lastNameController, 'Last Name'),
                  const SizedBox(height: 16),
                  _buildField(vm.usernameController, 'Username'),
                  const SizedBox(height: 16),
                  _buildField(vm.emailController, 'Email'),
                  const SizedBox(height: 16),
                  _buildField(
                    vm.phoneController,
                    'Phone Number',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildField(vm.passwordController, 'Password', obscure: true),
                  const SizedBox(height: 16),
                  _buildField(
                    vm.confirmPasswordController,
                    'Confirm Password',
                    obscure: true,
                  ),
                  const SizedBox(height: 24),

                  // 🔘 Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          vm.isLoading ? null : () => vm.signup(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[600],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child:
                          vm.isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                              : const Text(
                                'Create an account',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.yellow),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.yellowAccent),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
