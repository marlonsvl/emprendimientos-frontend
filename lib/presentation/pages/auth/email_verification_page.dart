import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';

class EmailVerificationPage extends StatelessWidget {
  final String email;
  
  const EmailVerificationPage({
    Key? key, 
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Email Icon with Animation Container
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          size: 60,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Title
                      Text(
                        'Revisa tu correo electrónico',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle with email
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Hemos enviado un enlace de verificación a\n',
                            ),
                            TextSpan(
                              text: email,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Haz clic en el enlace de verificación que recibes en tu correo electrónico para activar tu cuenta. El enlace caducará en 24 horas.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
                
                // Bottom section with buttons
                Flexible(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Resend Email Button
                      CustomButton(
                        text: 'Reenviar correo electrónico de verificación',
                        onPressed: () {
                          // Handle resend verification email
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('¡Correo electrónico de verificación enviado nuevamente!'),
                              backgroundColor: theme.colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        isOutlined: true,
                        width: double.infinity,
                        icon: const Icon(Icons.refresh),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Back to Login Button
                      CustomButton(
                        text: 'Volver a Iniciar sesión',
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        width: double.infinity,
                        icon: const Icon(Icons.login),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Help text
                      TextButton(
                        onPressed: () {
                          // Handle help/support
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('¿Necesitas ayuda?'),
                                content: const Text(
                                  'Si no recibe el correo electrónico de verificación:\n\n'
                                  '• Revise su carpeta de correo no deseado/spam\n'
                                  '• Asegúrese de haber ingresado el correo electrónico correcto\n'
                                  '• Intente reenviar el correo electrónico de verificación\n\n'
                                  '¿Sigues teniendo problemas? Contacta con nuestro equipo de soporte.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Entendido'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text(
                          '¿No recibiste el correo electrónico?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
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