import 'package:flutter/material.dart';

/// Modèle pour un événement dans la timeline chronologique d'un adhérent
/// 
/// Représente un événement financier ou opérationnel dans l'historique :
/// - Dépôt cacao
/// - Vente associée
/// - Recette générée
/// - Retenue sociale
/// - Paiement partiel
/// - Paiement final

class TimelineEventModel {
  final int? id;
  final int adherentId;
  final String type; // 'depot', 'vente', 'recette', 'retenue', 'paiement'
  final int? operationId; // ID de l'opération (depot_id, vente_id, recette_id, etc.)
  final String titre;
  final String description;
  final double? montant; // Montant associé (peut être null pour certains événements)
  final DateTime dateEvenement;
  final String? documentPath; // Chemin vers PDF si disponible
  final String? qrCodeHash; // Hash QR Code pour vérification
  final Map<String, dynamic>? metadata; // Données supplémentaires (JSON)

  TimelineEventModel({
    this.id,
    required this.adherentId,
    required this.type,
    this.operationId,
    required this.titre,
    required this.description,
    this.montant,
    required this.dateEvenement,
    this.documentPath,
    this.qrCodeHash,
    this.metadata,
  });

  IconData get icon {
    switch (type) {
      case 'depot':
        return Icons.inventory;
      case 'vente':
        return Icons.shopping_cart;
      case 'recette':
        return Icons.receipt_long;
      case 'retenue':
        return Icons.remove_circle;
      case 'paiement':
        return Icons.payment;
      default:
        return Icons.event;
    }
  }

  Color get color {
    switch (type) {
      case 'depot':
        return Colors.blue;
      case 'vente':
        return Colors.green;
      case 'recette':
        return Colors.teal;
      case 'retenue':
        return Colors.orange;
      case 'paiement':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Convertir depuis Map (base de données)
  factory TimelineEventModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? metadata;
    if (map['metadata'] != null) {
      // TODO: Parser JSON si nécessaire
      metadata = {};
    }
    
    return TimelineEventModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      type: map['type'] as String,
      operationId: map['operation_id'] as int?,
      titre: map['titre'] as String,
      description: map['description'] as String,
      montant: map['montant'] != null ? (map['montant'] as num).toDouble() : null,
      dateEvenement: DateTime.parse(map['date_evenement'] as String),
      documentPath: map['document_path'] as String?,
      qrCodeHash: map['qr_code_hash'] as String?,
      metadata: metadata,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'type': type,
      if (operationId != null) 'operation_id': operationId,
      'titre': titre,
      'description': description,
      if (montant != null) 'montant': montant,
      'date_evenement': dateEvenement.toIso8601String(),
      if (documentPath != null) 'document_path': documentPath,
      if (qrCodeHash != null) 'qr_code_hash': qrCodeHash,
      // TODO: Sérialiser metadata en JSON si nécessaire
    };
  }

  // Créer une copie avec des modifications
  TimelineEventModel copyWith({
    int? id,
    int? adherentId,
    String? type,
    int? operationId,
    String? titre,
    String? description,
    double? montant,
    DateTime? dateEvenement,
    String? documentPath,
    String? qrCodeHash,
    Map<String, dynamic>? metadata,
  }) {
    return TimelineEventModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      type: type ?? this.type,
      operationId: operationId ?? this.operationId,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      montant: montant ?? this.montant,
      dateEvenement: dateEvenement ?? this.dateEvenement,
      documentPath: documentPath ?? this.documentPath,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      metadata: metadata ?? this.metadata,
    );
  }
}

