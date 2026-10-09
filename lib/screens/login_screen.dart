import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import 'admin_dashboard_screen.dart';
import 'student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registering = false; // false = log in, true = create account
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    final email = _emailController.text;
    final password = _passwordController.text;
    final error = _registering
        ? await dataService.register(email, password)
        : await dataService.login(email, password);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    if (_registering) {
      setState(() {
        _busy = false;
        _registering = false;
        _info = 'Account created! We sent a verification link to your email. '
            'Open it, then log in here.';
      });
      return;
    }

    // Students go to the rating screens, admins go to the dashboard.
    final isAdmin = dataService.currentUser!.role == UserRole.admin;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
        isAdmin ? const AdminDashboardScreen() : const StudentHomeScreen(),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final error = await dataService.sendPasswordReset(_emailController.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error != null) {
        _error = error;
      } else {
        _info = 'If an account exists for that email, we sent a password '
            'reset link. Check your inbox (and spam folder).';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 64),
                const SizedBox(height: 8),
                Text(
                  'ClassComfort',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Text(
                  'Classroom Environment Rating System',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_registering && DataService.allowedEmailDomain.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Use your school email (@${DataService.allowedEmailDomain})',
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!_registering)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (_info != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_info!, style: TextStyle(color: Colors.green.shade700)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? 'Please wait...'
                        : (_registering ? 'Create Student Account' : 'Log In'),
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                    _registering = !_registering;
                    _error = null;
                    _info = null;
                  }),
                  child: Text(
                    _registering
                        ? 'Already have an account? Log in'
                        : 'New student? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}