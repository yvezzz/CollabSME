import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/network/route_helper.dart';

import '../../providers/auth_provider.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/api_exception.dart';
import '../home/home_screen.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _acceptTerms = false;
  
  // Field-specific error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _companyError;
  String? _passwordError;
  String? _phoneError;

  void _clearErrors() {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _companyError = null;
      _passwordError = null;
      _phoneError = null;
    });
  }

  void _handleRegister() async {
    _clearErrors();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _passwordError = "Les mots de passe ne correspondent pas");
      return;
    }
    if (!_acceptTerms) {
      AppToast.show(context, message: "Vous devez accepter les conditions générales", type: ToastType.error);
      return;
    }
    final password = _passwordController.text;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final company = _companyController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(authStateProvider.notifier).register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        companyName: company,
        phoneNumber: phone.isNotEmpty ? phone : null,
      );

      if (success && mounted) {
        AppToast.show(context, message: "Compte créé avec succès !", type: ToastType.success);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiException) {
            if (e.errors != null) {
              final errors = e.errors!;
              
              if (errors.containsKey('first_name')) {
                _firstNameError = _formatError(errors['first_name']);
              }
              if (errors.containsKey('last_name')) {
                _lastNameError = _formatError(errors['last_name']);
              }
              if (errors.containsKey('email')) {
                final emailErr = _formatError(errors['email']).toLowerCase();
                if (emailErr.contains("existe") || emailErr.contains("exists") || emailErr.contains("used")) {
                  _emailError = "Cette adresse e-mail est déjà associée à un compte.";
                } else {
                  _emailError = _formatError(errors['email']);
                }
              }
              if (errors.containsKey('company_name')) {
                final compErr = _formatError(errors['company_name']).toLowerCase();
                if (compErr.contains("utilisé") || compErr.contains("already") || compErr.contains("exists")) {
                  _companyError = "Ce nom d'entreprise est déjà enregistré.";
                } else {
                  _companyError = _formatError(errors['company_name']);
                }
              }
              if (errors.containsKey('password')) {
                _passwordError = _formatError(errors['password']);
              }
              if (errors.containsKey('phone_number')) {
                _phoneError = _formatError(errors['phone_number']);
              }
            } else {
              AppToast.show(context, message: e.message, type: ToastType.error);
            }
          } else {
            AppToast.show(context, message: "Une erreur réseau est survenue.", type: ToastType.error);
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    _emailController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;
    final horizontalPadding = isDesktop ? screenSize.width * 0.2 : 24.0;

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
                  "Créer un compte",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Commencez votre aventure avec CollabSME",
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 400) {
                                return Column(
                                  children: [
                                    AppTextField(
                                      controller: _firstNameController,
                                      label: "Prénom",
                                      icon: LucideIcons.user,
                                      errorText: _firstNameError,
                                      onChanged: (_) => setState(() => _firstNameError = null),
                                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]'))],
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return "Saisissez votre prénom";
                                        if (v.length < 2) return "Prénom trop court";
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: _lastNameController,
                                      label: "Nom",
                                      icon: LucideIcons.user,
                                      errorText: _lastNameError,
                                      onChanged: (_) => setState(() => _lastNameError = null),
                                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]'))],
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return "Saisissez votre nom";
                                        if (v.length < 2) return "Nom trop court";
                                        return null;
                                      },
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _firstNameController,
                                      label: "Prénom",
                                      icon: LucideIcons.user,
                                      errorText: _firstNameError,
                                      onChanged: (_) => setState(() => _firstNameError = null),
                                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]'))],
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return "Prénom requis";
                                        if (v.length < 2) return "Trop court";
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _lastNameController,
                                      label: "Nom",
                                      icon: LucideIcons.user,
                                      errorText: _lastNameError,
                                      onChanged: (_) => setState(() => _lastNameError = null),
                                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]'))],
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return "Nom requis";
                                        if (v.length < 2) return "Trop court";
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _emailController,
                            label: "E-mail professionnel",
                            icon: LucideIcons.mail,
                            errorText: _emailError,
                            onChanged: (_) => setState(() => _emailError = null),
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Veuillez saisir une adresse e-mail";
                              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
                                return "Format d'e-mail invalide";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _companyController,
                            label: "Nom de l'entreprise",
                            icon: LucideIcons.building,
                            errorText: _companyError,
                            onChanged: (_) => setState(() => _companyError = null),
                            validator: (v) => (v == null || v.isEmpty) ? "Nom d'entreprise requis" : null,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                             controller: _phoneController,
                             label: "Numéro de téléphone",
                              hint: "+237 6 12 34 56 78",
                             icon: LucideIcons.phone,
                             errorText: _phoneError,
                             keyboardType: TextInputType.phone,
                             formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]'))],
                             onChanged: (_) => setState(() => _phoneError = null),
                             validator: (v) {
                                if (v == null || v.isEmpty) return "Numéro de téléphone requis";
                                final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                               if (cleaned.length < 8) return "Numéro trop court (min. 8 chiffres)";
                               if (cleaned.length > 20) return "Numéro trop long (max. 20 chiffres)";
                               if (!RegExp(r'^\+?\d{7,20}$').hasMatch(cleaned)) {
                                  return "Format invalide. Exemple: +237612345678";
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
                                if (v == null || v.isEmpty) return "Veuillez saisir un mot de passe";
                                if (v.length < 8) return "Le mot de passe doit contenir au moins 8 caractères";
                                if (!v.contains(RegExp(r'[A-Z]'))) return "Le mot de passe doit contenir au moins une majuscule";
                                if (!v.contains(RegExp(r'[a-z]'))) return "Le mot de passe doit contenir au moins une minuscule";
                                if (!v.contains(RegExp(r'[0-9]'))) return "Le mot de passe doit contenir au moins un chiffre";
                                return null;
                              },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _confirmPasswordController,
                            label: "Confirmer le mot de passe",
                            icon: LucideIcons.lock,
                            obscure: true,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Veuillez confirmer le mot de passe";
                              if (v != _passwordController.text) return "Les mots de passe ne correspondent pas";
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                  activeColor: AppColors.primary,
                                  checkColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      children: [
                                        const TextSpan(text: "J'accepte les "),
                                        TextSpan(
                                          text: "conditions générales d'utilisation",
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("S'inscrire", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    const Text("Déjà un compte ? ", style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(Routes.login),
                      child: const Text("Se connecter", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
