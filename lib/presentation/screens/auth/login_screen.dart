import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/auth_provider.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/route_helper.dart';
import '../../../core/exceptions/api_exception.dart';
import '../home/home_screen.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  
  String? _emailError;
  String? _passwordError;
  String? _globalError;

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _globalError = null;
    });
  }

  Future<void> _handleLogin() async {
    _clearErrors();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authStateProvider.notifier)
          .login(email, password);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiException) {
            if (e.errors != null) {
              final errors = e.errors!;
              if (errors.containsKey('email')) {
                _emailError = _formatError(errors['email']);
              }
              if (errors.containsKey('password')) {
                _passwordError = _formatError(errors['password']);
              }
              
              if (errors.containsKey('non_field_errors')) {
                _globalError = _formatError(errors['non_field_errors']);
              } else if (errors.containsKey('detail')) {
                _globalError = _formatError(errors['detail']);
              }
            }
            
              if (_emailError == null && _passwordError == null && _globalError == null) {
                _globalError = e.message;
              }

              // Show error inline on password field if no field-level error was set
              if (_passwordError == null && _globalError != null) {
                _passwordError = _globalError;
              }
          } else {
            final msg = e.toString().toLowerCase();
            if (msg.contains("fetch") || msg.contains("connection") || msg.contains("socket")) {
              _globalError = "Impossible de joindre le serveur. Vérifiez votre connexion.";
            } else {
              _globalError = "E-mail ou mot de passe incorrect";
            }
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Réinitialisation", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Saisissez votre e-mail pour recevoir un lien de réinitialisation.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: emailController,
                label: "E-mail",
                icon: LucideIcons.mail,
                errorText: dialogError,
                onChanged: (_) => setDialogState(() => dialogError = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text("Annuler", style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        setDialogState(() => dialogError = "E-mail requis");
                        return;
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
                        setDialogState(() => dialogError = "Format d'e-mail invalide");
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        await ref.read(authRepositoryProvider).requestPasswordReset(email);
                        if (context.mounted) {
                          Navigator.pop(context);
                          AppToast.show(context, message: "Lien de réinitialisation envoyé !", type: ToastType.success);
                        }
                      } catch (e) {
                        setDialogState(() => dialogError = e.toString().replaceAll("Exception: ", ""));
                      } finally {
                        if (context.mounted) setDialogState(() => isSubmitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Envoyer"),
            ),
          ],
        ),
      ),
    );
  }

  String _formatError(dynamic error) {
    if (error is List) return error.join(" ");
    return error.toString();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;
    final horizontalPadding = isDesktop ? screenSize.width * 0.25 : 24.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(LucideIcons.rocket, size: 48, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Bon retour !",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Connectez-vous pour gérer vos projets",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_globalError != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                _globalError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.danger, fontSize: 13),
                              ),
                            ),
                          AppTextField(
                            controller: _emailController,
                            label: "E-mail",
                            icon: LucideIcons.mail,
                            errorText: _emailError,
                            onChanged: (_) => setState(() => _emailError = null),
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Veuillez saisir votre e-mail";
                              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
                                return "Format d'e-mail invalide";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordController,
                            label: "Mot de passe",
                            icon: LucideIcons.lock,
                            obscure: true,
                            isPassword: true,
                            errorText: _passwordError,
                            onChanged: (_) => setState(() => _passwordError = null),
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Veuillez saisir votre mot de passe";
                              if (v.length < 8) return "8 caractères minimum";
                              if (!v.contains(RegExp(r'[A-Z]'))) return "Au moins une majuscule";
                              if (!v.contains(RegExp(r'[a-z]'))) return "Au moins une minuscule";
                              if (!v.contains(RegExp(r'[0-9]'))) return "Au moins un chiffre";
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text("Mot de passe oublié ?", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Se connecter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text("Nouveau ici ? ", style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(Routes.register),
                      child: const Text("Créer un compte", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
          Positioned(
            top: 48,
            left: 16,
            child: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
