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
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final ok = dataService.login(_emailController.text, _passwordController.text);
    if (!ok) {
      setState(() => _error = 'Invalid email or password');
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
                  onSubmitted: (_) => _login(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _login, child: const Text('Log In')),
                const SizedBox(height: 24),
                const Text(
                  'Demo accounts\nstudent@school.edu / 1234\nadmin@school.edu / admin',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
