import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/utils/validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check authentication status when the page loads
    // This will trigger the AuthBloc to check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthStatusChecked());
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            // Navigate to greeting page for both existing and new logins
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/greeting',
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          // Show loading screen while checking authentication status
          if (state is AuthInitial || 
              (state is AuthLoading && _usernameController.text.isEmpty && _passwordController.text.isEmpty)) {
            return _buildLoadingScreen(theme);
          }
          
          // Show login form if user is not authenticated or there's an error
          return _buildLoginForm(context, theme, state);
        },
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo while loading
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Loading indicator
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Comprobando la autenticación...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, ThemeData theme, AuthState state) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Logo/Icon
              Container(
                height: 120,
                width: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Bienvenido de nuevo!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Inicia sesión para descubrir increíbles startups gastronómicas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Username Field
              CustomTextField(
                controller: _usernameController,
                hintText: 'Introduce tu nombre de usuario',
                labelText: 'Username',
                keyboardType: TextInputType.text,
                prefixIcon: Icon(
                  Icons.alternate_email,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                validator: Validators.username,
              ),
              
              const SizedBox(height: 16),
              
              // Password Field
              CustomTextField(
                controller: _passwordController,
                hintText: 'Introduce tu password',
                labelText: 'Password',
                obscureText: true,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                validator: Validators.password,
              ),
              
              const SizedBox(height: 16),
              
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/password-recovery');
                  },
                  child: Text(
                    '¿Has olvidado tu contraseña?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Login Button
              CustomButton(
                text: 'Sign In',
                onPressed: _handleLogin,
                isLoading: state is AuthLoading && 
                         (_usernameController.text.isNotEmpty || _passwordController.text.isNotEmpty),
                icon: const Icon(Icons.login),
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Register Button
              CustomButton(
                text: 'Crear cuenta',
                onPressed: () {
                  Navigator.of(context).pushNamed('/register');
                },
                isOutlined: true,
                icon: const Icon(Icons.person_add),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}