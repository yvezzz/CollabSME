import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collabsme/core/constants/app_constants.dart';

const Map<String, List<String>> citiesByCountry = {
  'France': ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Bordeaux', 'Lille', 'Nice', 'Nantes', 'Strasbourg', 'Montpellier'],
  'Belgique': ['Bruxelles', 'Anvers', 'Liège', 'Gand', 'Charleroi', 'Bruges'],
  'Suisse': ['Zurich', 'Genève', 'Bâle', 'Berne', 'Lausanne', 'Lucerne'],
  'Canada': ['Montréal', 'Toronto', 'Vancouver', 'Québec', 'Ottawa', 'Calgary'],
  'Maroc': ['Casablanca', 'Rabat', 'Marrakech', 'Fès', 'Tanger', 'Agadir'],
  'Tunisie': ['Tunis', 'Sfax', 'Sousse', 'Kairouan', 'Bizerte'],
  'Algérie': ['Alger', 'Oran', 'Constantine', 'Annaba', 'Blida'],
  'Sénégal': ['Dakar', 'Thiès', 'Saint-Louis', 'Kaolack', 'Ziguinchor'],
  'Cameroun': ['Douala', 'Yaoundé', 'Garoua', 'Bamenda', 'Maroua'],
  'Côte d\'Ivoire': ['Abidjan', 'Bouaké', 'Yamoussoukro', 'San-Pédro', 'Korhogo'],
  'RDC': ['Kinshasa', 'Lubumbashi', 'Mbuji-Mayi', 'Kisangani', 'Bukavu'],
  'Madagascar': ['Antananarivo', 'Toamasina', 'Antsirabe', 'Mahajanga', 'Fianarantsoa'],
  'Allemagne': ['Berlin', 'Munich', 'Hambourg', 'Francfort', 'Cologne', 'Stuttgart'],
  'Italie': ['Rome', 'Milan', 'Naples', 'Turin', 'Florence', 'Venise'],
  'Espagne': ['Madrid', 'Barcelone', 'Valence', 'Séville', 'Bilbao'],
  'Portugal': ['Lisbonne', 'Porto', 'Braga', 'Coimbra', 'Faro'],
  'Royaume-Uni': ['Londres', 'Manchester', 'Birmingham', 'Édimbourg', 'Glasgow'],
  'Pays-Bas': ['Amsterdam', 'Rotterdam', 'La Haye', 'Utrecht', 'Eindhoven'],
  'États-Unis': ['New York', 'Los Angeles', 'Chicago', 'San Francisco', 'Miami', 'Houston', 'Boston'],
  'Brésil': ['São Paulo', 'Rio de Janeiro', 'Brasilia', 'Salvador', 'Fortaleza'],
  'Chine': ['Pékin', 'Shanghai', 'Guangzhou', 'Shenzhen', 'Chengdu'],
  'Japon': ['Tokyo', 'Osaka', 'Kyoto', 'Yokohama', 'Nagoya'],
  'Inde': ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai'],
  'Nigeria': ['Lagos', 'Abuja', 'Kano', 'Ibadan', 'Port Harcourt'],
  'Égypte': ['Le Caire', 'Alexandrie', 'Gizeh', 'Louxor', 'Assouan'],
};

const List<String> _allCountries = [
  'France', 'Belgique', 'Suisse', 'Canada', 'Maroc', 'Tunisie',
  'Algérie', 'Sénégal', 'Côte d\'Ivoire', 'Cameroun', 'RDC',
  'Madagascar', 'Haïti', 'Luxembourg', 'Monaco',
  'Allemagne', 'Italie', 'Espagne', 'Portugal', 'Royaume-Uni',
  'Pays-Bas', 'Suède', 'Norvège', 'Danemark', 'Finlande',
  'États-Unis', 'Brésil', 'Mexique', 'Argentine', 'Chili',
  'Chine', 'Japon', 'Inde', 'Corée du Sud', 'Australie',
  'Nigeria', 'Kenya', 'Égypte', 'Afrique du Sud', 'Ghana',
  'Autriche', 'Pologne', 'Tchéquie', 'Roumanie', 'Hongrie',
  'Grèce', 'Turquie', 'Israël', 'Émirats arabes unis', 'Arabie saoudite',
  'Russie', 'Ukraine', 'Vietnam', 'Thaïlande', 'Indonésie',
  'Philippines', 'Malaisie', 'Singapour',
];

class CountryPickerWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const CountryPickerWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value != null && _allCountries.contains(value!) ? value : null,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: "Pays",
        prefixIcon: const Icon(LucideIcons.flag, size: 20, color: AppColors.textSecondary),
        labelStyle: TextStyle(color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.4)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.card),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: enabled ? AppColors.card : AppColors.card.withValues(alpha: 0.5),
      ),
      dropdownColor: AppColors.card,
      style: TextStyle(color: enabled ? Colors.white : Colors.white38, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
      isExpanded: true,
      items: _allCountries.map((c) {
        return DropdownMenuItem(value: c, child: Text(c));
      }).toList(),
      selectedItemBuilder: (context) {
        return _allCountries.map((c) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(c, style: TextStyle(color: enabled ? Colors.white : Colors.white38)),
          );
        }).toList();
      },
    );
  }
}
