import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../widgets/glass_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/invitation_repository.dart';
import '../home/home_screen.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../widgets/app_toast.dart';

class AcceptInvitationScreen extends StatefulWidget {
  final String token;
  const AcceptInvitationScreen({super.key, required this.token});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  final _invitationRepo = InvitationRepository();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isValidating = true;
  bool _isSubmitting = false;
  String? _error;
  String? _serverError;
  Map<String, dynamic>? _invitationData;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _validateInvitation();
  }

  Future<void> _validateInvitation() async {
    try {
      final data = await _invitationRepo.validateToken(widget.token);
      setState(() {
        _invitationData = data;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isValidating = false;
      });
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _invitationRepo.acceptInvitation(
        token: widget.token,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiException && e.errors != null) {
            final errors = e.errors!;
            if (errors.containsKey('first_name')) {
              _serverError = _formatError(errors['first_name']);
            } else if (errors.containsKey('last_name')) {
              _serverError = _formatError(errors['last_name']);
            } else if (errors.containsKey('password')) {
              _serverError = _formatError(errors['password']);
            } else {
              _serverError = e.message;
            }
          } else {
            _serverError = e.toString().replaceAll("Exception: ", "");
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatError(dynamic error) {
    if (error is List) return error.join(" ");
    return error.toString();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.background.withValues(alpha: 0.8),
              AppColors.primary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 500 : double.infinity),
              child: _isValidating 
                ? const CircularProgressIndicator(color: AppColors.primary)
                : _error != null
                  ? _buildErrorState()
                  : _buildAcceptForm(isDesktop),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(LucideIcons.alertTriangle, size: 64, color: AppColors.danger),
        const SizedBox(height: 16),
        Text(
          "Oups !",
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text("Retour"),
        ),
      ],
    );
  }

  Widget _buildAcceptForm(bool isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Logo Section
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                LucideIcons.rocket,
                size: 48,
                color: AppColors.primary,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          ),
          
          const SizedBox(height: 24),

          Text(
            "Bienvenue chez ${_invitationData?['company_name']}",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          
          const SizedBox(height: 8),
          
          Text(
            "Vous avez été invité par ${_invitationData?['invited_by_name'] ?? 'un administrateur'}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 40),

          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Finalisez votre profil",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: "Prénom",
                          icon: LucideIcons.user,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Prénom requis";
                            if (v.length < 2) return "Prénom trop court";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: "Nom",
                          icon: LucideIcons.user,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Nom requis";
                            if (v.length < 2) return "Nom trop court";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: "Créer un mot de passe",
                    icon: LucideIcons.lock,
                    obscure: _obscurePassword,
                    isPassword: true,
                    errorText: _serverError,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    onChanged: (_) => setState(() => _serverError = null),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Saisissez un mot de passe";
                      if (v.length < 8) return "8 caractères minimum";
                      if (!v.contains(RegExp(r'[A-Z]'))) return "Au moins une majuscule requise";
                      if (!v.contains(RegExp(r'[a-z]'))) return "Au moins une minuscule requise";
                      if (!v.contains(RegExp(r'[0-9]'))) return "Au moins un chiffre requis";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: "Confirmer le mot de passe",
                    icon: LucideIcons.checkCircle,
                    obscure: _obscurePassword,
                    isPassword: true,
                    validator: (v) => v != _passwordController.text ? "Les mots de passe ne correspondent pas" : null,
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            try {
                              await _invitationRepo.declineInvitation(widget.token);
                              if (mounted) {
                                AppToast.show(context, message: "Invitation refusée.", type: ToastType.info);
                                Navigator.of(context).pop();
                              }
                            } catch (_) {
                              if (mounted) {
                                AppToast.show(context, message: "Erreur lors du refus", type: ToastType.error);
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                          ),
                          child: const Text("Refuser", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                          child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Rejoindre l'équipe", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
               ),
             ),
           ),
         ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 20, color: AppColors.textSecondary), onPressed: onToggleVisibility) : null,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        errorStyle: const TextStyle(color: AppColors.danger),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger, width: 2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}
