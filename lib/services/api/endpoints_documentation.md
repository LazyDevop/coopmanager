# Documentation des Endpoints API REST

## Format de Réponse Standardisé

Toutes les réponses suivent le format suivant :

```json
{
  "success": true,
  "message": "Operation successful",
  "data": {},
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "user_id": 1,
    "module": "vente"
  }
}
```

En cas d'erreur :

```json
{
  "success": false,
  "message": "Error message",
  "error": {
    "code": "ERROR_CODE",
    "message": "Detailed error message",
    "status_code": 400
  }
}
```

---

## 🔐 Authentification

### POST /api/v1/auth/login
Connexion utilisateur

**Request:**
```json
{
  "username": "admin",
  "password": "password"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt_token_here",
    "refresh_token": "refresh_token_here",
    "user": {
      "id": 1,
      "username": "admin",
      "role": "admin"
    }
  }
}
```

### POST /api/v1/auth/refresh
Rafraîchir le token

**Request:**
```json
{
  "refresh_token": "refresh_token_here"
}
```

### POST /api/v1/auth/logout
Déconnexion

---

## 👤 ADHÉRENTS

### GET /api/v1/adherents
Liste des adhérents

**Query Parameters:**
- `is_active` (boolean): Filtrer par statut actif
- `categorie` (string): Filtrer par catégorie
- `statut` (string): Filtrer par statut
- `page` (int): Numéro de page
- `limit` (int): Nombre d'éléments par page
- `search` (string): Recherche textuelle

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "ADH001",
      "nom": "Doe",
      "prenom": "John",
      ...
    }
  ]
}
```

### GET /api/v1/adherents/{id}
Détails d'un adhérent

### POST /api/v1/adherents
Créer un adhérent

**Request:**
```json
{
  "code": "ADH001",
  "nom": "Doe",
  "prenom": "John",
  "telephone": "+1234567890",
  "date_adhesion": "2024-01-01",
  ...
}
```

**Backend Actions:**
- Validation du code unique
- Création automatique de l'historique
- Calcul initial du capital si applicable

### PUT /api/v1/adherents/{id}
Mettre à jour un adhérent

### PUT /api/v1/adherents/{id}/statut
Mettre à jour le statut (avec historique automatique)

**Request:**
```json
{
  "statut": "suspendu",
  "raison": "Raison de la suspension",
  "updated_by": 1
}
```

### DELETE /api/v1/adherents/{id}
Supprimer un adhérent (soft delete)

### GET /api/v1/adherents/{id}/stock
Obtenir le stock disponible

**Response:**
```json
{
  "success": true,
  "data": {
    "stock_disponible": 1500.5
  }
}
```

### GET /api/v1/adherents/{id}/can-sell
Vérifier si l'adhérent peut vendre

**Response:**
```json
{
  "success": true,
  "data": {
    "can_sell": true,
    "reason": null
  }
}
```

### GET /api/v1/adherents/search?q={query}
Rechercher des adhérents

---

## 🛒 VENTES

### GET /api/v1/ventes
Liste des ventes

**Query Parameters:**
- `adherent_id` (int)
- `client_id` (int)
- `campagne_id` (int)
- `type` (string): 'individuelle' ou 'groupee'
- `statut` (string)
- `statut_paiement` (string): 'payee' ou 'non_payee'
- `start_date` (datetime)
- `end_date` (datetime)
- `page` (int)
- `limit` (int)

### GET /api/v1/ventes/{id}
Détails d'une vente

### POST /api/v1/ventes/individuelle
Créer une vente individuelle

**Request:**
```json
{
  "client_id": 1,
  "campagne_id": 1,
  "adherent_id": 1,
  "quantite_total": 100.0,
  "prix_unitaire": 1500.0,
  "mode_paiement": "especes",
  "date_vente": "2024-01-01T00:00:00Z",
  "notes": "Notes optionnelles",
  "created_by": 1,
  "override_prix_validation": false
}
```

**Backend Transaction (ATOMIQUE):**
```sql
BEGIN TRANSACTION;
  -- 1. Débiter le stock
  UPDATE stock_depots SET quantite_restante = quantite_restante - ? WHERE adherent_id = ?;
  
  -- 2. Créer la vente
  INSERT INTO ventes (...) VALUES (...);
  
  -- 3. Calculer et créer la recette
  INSERT INTO recettes (...) VALUES (...);
  
  -- 4. Créer l'écriture comptable
  INSERT INTO ecritures_comptables (...) VALUES (...);
  
  -- 5. Mettre à jour le capital si applicable
  UPDATE capital_social SET montant = montant + ? WHERE adherent_id = ?;
COMMIT;
-- ROLLBACK si erreur
```

**Response:**
```json
{
  "success": true,
  "message": "Vente créée avec succès",
  "data": {
    "id": 1,
    "type": "individuelle",
    "montant_total": 150000.0,
    "montant_commission": 7500.0,
    "montant_net": 142500.0,
    ...
  }
}
```

### POST /api/v1/ventes/groupee
Créer une vente groupée

**Request:**
```json
{
  "client_id": 1,
  "campagne_id": 1,
  "details": [
    {
      "adherent_id": 1,
      "quantite": 50.0
    },
    {
      "adherent_id": 2,
      "quantite": 75.0
    }
  ],
  "prix_unitaire": 1500.0,
  "mode_paiement": "virement",
  "date_vente": "2024-01-01T00:00:00Z",
  "created_by": 1
}
```

**Backend Transaction (ATOMIQUE):**
- Débiter le stock pour chaque adhérent
- Créer la vente principale
- Créer les détails de vente
- Calculer et créer les recettes individuelles
- Créer les écritures comptables

### POST /api/v1/ventes/{id}/annuler
Annuler une vente

**Request:**
```json
{
  "annule_par": 1,
  "raison": "Raison de l'annulation"
}
```

**Backend Transaction (ATOMIQUE):**
- Restaurer le stock
- Annuler les recettes
- Annuler les écritures comptables
- Marquer la vente comme annulée

### GET /api/v1/ventes/{id}/details
Obtenir les détails d'une vente groupée

### POST /api/v1/ventes/simulation
Simuler une vente (calculs sans création)

**Request:**
```json
{
  "client_id": 1,
  "campagne_id": 1,
  "adherent_id": 1,
  "quantite_total": 100.0,
  "prix_unitaire": 1500.0
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "montant_brut": 150000.0,
    "montant_commission": 7500.0,
    "montant_net": 142500.0,
    "stock_disponible": 500.0,
    "validation_prix": {
      "is_valid": true,
      "message": null
    }
  }
}
```

### GET /api/v1/ventes/statistiques
Statistiques des ventes

**Query Parameters:**
- `start_date` (datetime)
- `end_date` (datetime)
- `adherent_id` (int)
- `client_id` (int)
- `campagne_id` (int)

**Response:**
```json
{
  "success": true,
  "data": {
    "nombre_ventes": 150,
    "quantite_totale": 15000.0,
    "montant_total": 22500000.0,
    "montant_commission": 1125000.0,
    "montant_net": 21375000.0
  }
}
```

### GET /api/v1/ventes/search?q={query}
Rechercher des ventes

---

## 📦 STOCK

### GET /api/v1/stock
Liste des stocks

**Query Parameters:**
- `adherent_id` (int)
- `campagne_id` (int)
- `qualite` (string)

### GET /api/v1/stock/{id}
Détails d'un stock

### POST /api/v1/stock/depot
Créer un dépôt de stock

**Request:**
```json
{
  "adherent_id": 1,
  "campagne_id": 1,
  "quantite": 500.0,
  "qualite": "standard",
  "prix_unitaire": null,
  "date_depot": "2024-01-01T00:00:00Z",
  "observations": "Notes",
  "created_by": 1
}
```

**Backend Transaction (ATOMIQUE):**
- Créer le dépôt
- Mettre à jour le stock actuel
- Créer un mouvement de stock
- Enregistrer l'audit

### GET /api/v1/stock/{adherent_id}/actuel
Obtenir le stock actuel d'un adhérent

### GET /api/v1/stock/mouvements
Historique des mouvements

---

## 💰 RECETTES

### GET /api/v1/recettes
Liste des recettes

**Query Parameters:**
- `adherent_id` (int)
- `vente_id` (int)
- `campagne_id` (int)
- `start_date` (datetime)
- `end_date` (datetime)

### GET /api/v1/recettes/{id}
Détails d'une recette

### GET /api/v1/recettes/{id}/bordereau
Générer le bordereau PDF

---

## 🧾 FACTURATION

### GET /api/v1/factures
Liste des factures

### GET /api/v1/factures/{id}
Détails d'une facture

### POST /api/v1/factures
Créer une facture depuis une vente

**Request:**
```json
{
  "vente_id": 1,
  "created_by": 1
}
```

**Backend Actions:**
- Génération du numéro unique
- Calcul des montants
- Génération du QR Code
- Calcul du hash du document

### GET /api/v1/factures/{id}/pdf
Télécharger le PDF de la facture

---

## 📊 COMPTABILITÉ

### GET /api/v1/comptabilite/ecritures
Liste des écritures comptables

### GET /api/v1/comptabilite/soldes
Obtenir les soldes des comptes

### GET /api/v1/comptabilite/journal
Journal comptable

---

## 🔄 SYNCHRONISATION

### POST /api/v1/sync
Synchroniser les données offline

**Request:**
```json
{
  "items": [
    {
      "action": "create",
      "module": "vente",
      "endpoint": "/api/v1/ventes/individuelle",
      "data": {...},
      "local_id": {"id": -1}
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "synced": 5,
    "failed": 0,
    "conflicts": []
  }
}
```

### GET /api/v1/sync/status
Statut de la synchronisation

### GET /api/v1/health
Health check (pour vérifier la connexion)

---

## 🔍 AUDIT & TRAÇABILITÉ

### GET /api/v1/audit/logs
Logs d'audit

**Query Parameters:**
- `module` (string)
- `user_id` (int)
- `start_date` (datetime)
- `end_date` (datetime)
- `action` (string)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "module": "vente",
      "action": "create",
      "entity_id": 123,
      "old_value": null,
      "new_value": {...},
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

## Codes HTTP

- `200 OK`: Succès
- `201 Created`: Ressource créée
- `400 Bad Request`: Erreur de validation
- `401 Unauthorized`: Non authentifié
- `403 Forbidden`: Permissions insuffisantes
- `404 Not Found`: Ressource introuvable
- `409 Conflict`: Conflit de synchronisation
- `500 Internal Server Error`: Erreur serveur

---

## Sécurité

- Tous les endpoints (sauf `/auth/login` et `/health`) nécessitent un token JWT
- Le token doit être envoyé dans le header: `Authorization: Bearer {token}`
- RBAC (Role-Based Access Control) appliqué selon le rôle utilisateur
- Toutes les actions sensibles sont enregistrées dans l'audit log

