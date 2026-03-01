import 'dart:convert';

/// Modele de session utilisateur mémorisée (pour la connexion rapide)
class UserSession {
  final String idUtilisateur;
  final String nomUtilisateur;
  final String email;
  final String? photoProfil;
  final bool hasBlueBadge;
  final DateTime dateConnexion;
  final String? provider; // 'email', 'google', 'apple'

  UserSession({
    required this.idUtilisateur,
    required this.nomUtilisateur,
    required this.email,
    this.photoProfil,
    this.hasBlueBadge = false,
    required this.dateConnexion,
    this.provider,
  });

  /// Cree une session a partir d'un JSON
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      idUtilisateur: json['id_utilisateur'],
      nomUtilisateur: json['nom_utilisateur'],
      email: json['email'],
      photoProfil: json['photo_profil'],
      hasBlueBadge: json['has_blue_badge'] ?? false,
      dateConnexion: DateTime.parse(json['date_connexion']),
      provider: json['provider'],
    );
  }

  /// Convertit la session en JSON
  Map<String, dynamic> toJson() {
    return {
      'id_utilisateur': idUtilisateur,
      'nom_utilisateur': nomUtilisateur,
      'email': email,
      'photo_profil': photoProfil,
      'has_blue_badge': hasBlueBadge,
      'date_connexion': dateConnexion.toIso8601String(),
      'provider': provider,
    };
  }

  /// Convertit la session en JSON string
  String toJsonString() => json.encode(toJson());

  /// Cree a partir d'un JSON string
  static UserSession? fromJsonString(String jsonString) {
    try {
      return UserSession.fromJson(json.decode(jsonString));
    } catch (e) {
      return null;
    }
  }
}
