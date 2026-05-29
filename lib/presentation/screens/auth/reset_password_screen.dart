import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collabsme/presentation/providers/auth_provider.dart';
import 'package:collabsme/core/exceptions/api_exception.dart';
import 'login_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../widgets/glass_container.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(widget.email);
      if (mounted) {
        AppToast.show(context, message: "Nouvel email envoyé !", type: ToastType.success);
        _error = null;
      }
    } catch (e) {
      if (mounted) AppToast.show(context, message: "Erreur d'envoi", type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
        email: widget.email,
        token: widget.token,
        newPassword: _passwordController.text,
      );

      if (mounted) {
        AppToast.show(context, message: "Mot de passe réinitialisé avec succès !", type: ToastType.success);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;
    final horizontalPadding = isDesktop ? screenSize.width * 0.25 : 24.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
            child: GlassContainer(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.lock, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Nouveau mot de passe",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Définissez votre nouveau mot de passe sécurisé pour l'e-mail ${widget.email}.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: AppColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _isResending ? null : _handleResend,
                            child: _isResending
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text("Renvoyer l'email", style: TextStyle(color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: const Text(
                              "Retour à la connexion",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],

                    AppTextField(
                      controller: _passwordController,
                      label: "Nouveau mot de passe",
                      icon: LucideIcons.key,
                      obscure: true,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Saisissez un mot de passe";
                        if (v.length < 8) return "8 caractères minimum";
                        if (!v.contains(RegExp(r'[A-Z]'))) return "Au moins une majuscule requise";
                        if (!v.contains(RegExp(r'[a-z]'))) return "Au moins une minuscule requise";
                        if (!v.contains(RegExp(r'[0-9]'))) return "Au moins un chiffre requis";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: "Confirmer le mot de passe",
                      icon: LucideIcons.checkCircle,
                      obscure: true,
                      isPassword: true,
                      validator: (v) => v != _passwordController.text ? "Les mots de passe ne correspondent pas" : null,
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Réinitialiser le mot de passe", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
