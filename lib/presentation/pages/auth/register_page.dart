import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/utils/validators.dart';
import 'email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(RegisterRequested(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        rePassword: _confirmPasswordController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface, // Fixed: was theme.colorScheme.surface
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } else if (state is AuthRegistered) {
            // Navigate to email verification page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EmailVerificationPage(
                  email: _emailController.text.trim(),
                ),
              ),
            );
          } else if (state is AuthAuthenticated) {
            // This handles the case when user verifies email and gets authenticated
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/main',
              (route) => false,
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Crear cuenta',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface, // Fixed: was theme.colorScheme.surface
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Únete para explorar nuevas empresas gastronómicas.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // First Name Field
                  /*CustomTextField(
                    controller: _firstNameController,
                    hintText: 'Enter your first name',
                    labelText: 'First Name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    validator: Validators.firstName, // Changed from required to firstName for better validation
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Last Name Field
                  CustomTextField(
                    controller: _lastNameController,
                    hintText: 'Enter your last name',
                    labelText: 'Last Name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    validator: Validators.lastName, // Changed from required to lastName for better validation
                  ),
                  */
                  //const SizedBox(height: 16),
                  
                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Ingresa tu email',
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    validator: Validators.email,
                  ),
                  
                  const SizedBox(height: 16),

                  // Username Field
                  CustomTextField(
                    controller: _usernameController,
                    hintText: 'Ingresa tu nombre de usuario',
                    labelText: 'Username',
                    keyboardType: TextInputType.text,
                    prefixIcon: Icon(
                      Icons.alternate_email, // Changed to a more appropriate icon
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    validator: Validators.username,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Ingresa tu password',
                    labelText: 'Password',
                    obscureText: true,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    validator: Validators.password,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirma tu password',
                    labelText: 'Confirma tu Password',
                    obscureText: true,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return Validators.password(value);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Register Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: 'Crear cuenta',
                        onPressed: _handleRegister,
                        isLoading: state is AuthLoading,
                        icon: const Icon(Icons.person_add),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}