import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'TODO':
        color = Colors.blueGrey;
        label = "À faire";
        break;
      case 'ACTIVE':
        color = Colors.green;
        label = "Actif";
        break;
      case 'IN_PROGRESS':
        color = Colors.cyan;
        label = "En cours";
        break;
      case 'DRAFT':
      case 'PLANNING':
        color = Colors.grey;
        label = "Brouillon";
        break;
      case 'COMPLETED':
      case 'DONE':
        color = Colors.blue;
        label = "Terminé";
        break;
      case 'REVIEW':
        color = Colors.orange;
        label = "En révision";
        break;
      case 'ARCHIVED':
        color = Colors.redAccent;
        label = "Archivé";
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
