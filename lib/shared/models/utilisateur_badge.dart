import 'badge.dart';

class UtilisateurBadge {
  final String idAttribution;
  final String idUtilisateur;
  final String idBadge;
  final BadgeModel badge;
  final String? message;
  final DateTime dateAttribution;

  UtilisateurBadge({
    required this.idAttribution,
    required this.idUtilisateur,
    required this.idBadge,
    required this.badge,
    this.message,
    required this.dateAttribution,
  });

  factory UtilisateurBadge.fromJson(Map<String, dynamic> json) {
    return UtilisateurBadge(
      idAttribution: json['id_attribution'],
      idUtilisateur: json['id_utilisateur'],
      idBadge: json['id_badge'],
      badge: BadgeModel.fromJson(json['badge']),
      message: json['message'],
      dateAttribution: DateTime.parse(json['date_attribution']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_attribution': idAttribution,
      'id_utilisateur': idUtilisateur,
      'id_badge': idBadge,
      'badge': badge.toJson(),
      'message': message,
      'date_attribution': dateAttribution.toIso8601String(),
    };
  }
}
