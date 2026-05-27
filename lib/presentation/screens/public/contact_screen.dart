import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;
  bool _sending = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() { _sending = false; _sent = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Contact", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text("CONTACT", style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text("Une question ?", style: GoogleFonts.outfit(
                  fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text("Notre equipe vous repond sous 24h.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isWide) const SizedBox(height: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _contactCard(LucideIcons.mail, "Email", "contact@collabsme.com",
                                "Notre equipe repond a tous les emails."),
                              const SizedBox(height: 12),
                              _contactCard(LucideIcons.messageCircle, "Chat en direct",
                                "Disponible dans l'application",
                                "Connectez-vous pour acceder au support instantane."),
                              const SizedBox(height: 12),
                              _contactCard(LucideIcons.twitter, "Twitter", "@collabsme",
                                "Suivez-nous pour les actualites."),
                              const SizedBox(height: 12),
                              _contactCard(LucideIcons.phone, "Telephone", "+237 6 12 34 56 78",
                                "Du lundi au vendredi, 9h-18h."),
                            ],
                          ),
                        ),
                        if (isWide) const SizedBox(width: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _sent ? _buildSuccessCard() : _buildForm(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.card),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Envoyez-nous un message",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _input("Nom complet", LucideIcons.user),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Veuillez entrer votre nom" : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _input("Adresse email", LucideIcons.mail),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Veuillez entrer votre email";
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return "Email invalide";
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _msgCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _input("Votre message", LucideIcons.messageSquare),
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty) ? "Veuillez entrer votre message" : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.send, size: 16),
                        SizedBox(width: 8),
                        Text("Envoyer le message"),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, color: AppColors.accent, size: 36),
          ),
          const SizedBox(height: 20),
          Text("Message envoye !", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          const Text("Nous vous repondrons dans les plus brefs delais.",
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              _nameCtrl.clear();
              _emailCtrl.clear();
              _msgCtrl.clear();
              setState(() => _sent = false);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Envoyer un autre message"),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.card),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.danger),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.danger),
        borderRadius: BorderRadius.circular(10),
      ),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _contactCard(IconData icon, String title, String value, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.card),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
