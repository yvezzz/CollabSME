import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../widgets/glass_container.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _companyRepo = CompanyRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _company;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    try {
      final company = await _companyRepo.getCompany();
      setState(() {
        _company = company;
        _nameController.text = company['name'] ?? '';
        _websiteController.text = company['website'] ?? '';
        _billingEmailController.text = company['billing_email'] ?? '';
        _addressController.text = company['address'] ?? '';
        _cityController.text = company['city'] ?? '';
        _postalCodeController.text = company['postal_code'] ?? '';
        _countryController.text = company['country'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.show(context, message: "Erreur de chargement : $e", type: ToastType.error);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _companyRepo.updateCompany({
        'name': _nameController.text.trim(),
        'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        'billing_email': _billingEmailController.text.trim().isEmpty ? null : _billingEmailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'postal_code': _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
        'country': _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      });
      if (mounted) {
        AppToast.show(context, message: "Entreprise mise à jour avec succès", type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _billingEmailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;
    final horizontalPadding = isDesktop ? screenSize.width * 0.15 : 16.0;

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          icon: const Icon(LucideIcons.chevronLeft),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: "Retour",
                        ),
                      ),
                      Text(
                        "Entreprise",
                        style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Modifier les informations de votre entreprise.",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: GlassContainer(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(LucideIcons.building2, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _company?['name'] ?? "Mon Entreprise",
                                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "ID: ${_company?['id'] ?? '-'}",
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                _sectionTitle("INFORMATIONS GÉNÉRALES"),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _nameController,
                                  label: "Nom de l'entreprise",
                                  icon: LucideIcons.building2,
                                  validator: (v) => (v == null || v.isEmpty) ? "Nom requis" : null,
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _websiteController,
                                  label: "Site web",
                                  icon: LucideIcons.globe,
                                ),
                                const SizedBox(height: 32),
                                _sectionTitle("CONTACT & FACTURATION"),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _billingEmailController,
                                  label: "E-mail de facturation",
                                  icon: LucideIcons.mail,
                                ),
                                const SizedBox(height: 32),
                                _sectionTitle("ADRESSE"),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _addressController,
                                  label: "Adresse",
                                  icon: LucideIcons.mapPin,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        controller: _cityController,
                                        label: "Ville",
                                        icon: LucideIcons.map,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppTextField(
                                        controller: _postalCodeController,
                                        label: "Code postal",
                                        icon: LucideIcons.mail,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _countryController,
                                  label: "Pays",
                                  icon: LucideIcons.flag,
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isSaving ? null : _save,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: _isSaving
                                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text("Enregistrer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }
}
