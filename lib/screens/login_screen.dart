import 'package:alumni_connect/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (success && mounted) {
      // Clear any stale error before changing routes.
      context.read<AuthProvider>().clearError();
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, color: AppTheme.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Nice to see you again',
                  style: TextStyle(fontSize: 18, color: AppTheme.textGray),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Email or phone number',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                if (context.watch<AuthProvider>().error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.watch<AuthProvider>().error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  text: 'Sign In',
                  onPressed: _signIn,
                  isLoading: context.watch<AuthProvider>().isLoading,
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.dividerGray)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Or Sign In With', style: TextStyle(color: AppTheme.textGray)),
                    ),
                    Expanded(child: Divider(color: AppTheme.dividerGray)),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: context.watch<AuthProvider>().isLoading
                      ? null
                      : () async {
                          final success = await context.read<AuthProvider>().signInWithGoogle();
                          if (success && mounted) {
                            context.read<AuthProvider>().clearError();
                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          }
                        },
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: const Text('Sign In with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textDark,
                    side: const BorderSide(color: AppTheme.dividerGray),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: AppTheme.textGray),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                MaterialButton(onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                },
                  child: const Text("Skip"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
