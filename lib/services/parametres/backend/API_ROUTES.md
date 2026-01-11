# API Routes - Module de Paramétrage Backend

## 📡 Endpoints REST

### Base URL
```
/api/v1
```

### Authentification
Tous les endpoints nécessitent un token d'authentification dans le header :
```
Authorization: Bearer <token>
```

---

## 🏢 Cooperative Endpoints

### GET /cooperatives
Récupérer toutes les coopératives

**Query Parameters:**
- `statut` (optional): ACTIVE, INACTIVE, SUSPENDED

**Response:**
```json
[
  {
    "id": "coop-123",
    "raison_sociale": "Coopérative de Cacaoculteurs",
    "sigle": "COOP-CACAO",
    "devise": "XAF",
    "langue": "FR",
    "statut": "ACTIVE",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

### GET /cooperatives/current
Récupérer la coopérative active

**Response:**
```json
{
  "id": "coop-123",
  "raison_sociale": "Coopérative de Cacaoculteurs",
  ...
}
```

### GET /cooperatives/{id}
Récupérer une coopérative par ID

### POST /cooperatives
Créer une nouvelle coopérative

**Body:**
```json
{
  "raison_sociale": "Nouvelle Coopérative",
  "sigle": "NEW-COOP",
  "devise": "XAF",
  "langue": "FR"
}
```

### PUT /cooperatives/{id}
Mettre à jour une coopérative

### DELETE /cooperatives/{id}
Supprimer une coopérative

### POST /cooperatives/{id}/set-current
Définir comme coopérative active

---

## ⚙️ Settings Endpoints

### GET /settings
Récupérer tous les settings

**Query Parameters:**
- `cooperative_id` (optional): ID de la coopérative
- `category` (optional): Filtrer par catégorie

**Response:**
```json
[
  {
    "id": "setting-123",
    "cooperative_id": "coop-123",
    "category": "finance",
    "key": "commission_rate",
    "value": "0.05",
    "value_type": "double",
    "editable": true
  }
]
```

### GET /settings/{category}
Récupérer tous les settings d'une catégorie

**Response:**
```json
[
  {
    "category": "finance",
    "key": "commission_rate",
    "value": "0.05",
    ...
  }
]
```

### GET /settings/{category}/{key}
Récupérer un setting spécifique

**Response:**
```json
{
  "category": "finance",
  "key": "commission_rate",
  "value": "0.05",
  "value_type": "double"
}
```

### POST /settings
Créer ou mettre à jour un setting

**Body:**
```json
{
  "category": "finance",
  "key": "commission_rate",
  "value": "0.05",
  "value_type": "double",
  "editable": true
}
```

### PUT /settings/{id}
Mettre à jour un setting

### DELETE /settings/{id}
Supprimer un setting

---

## 💰 Capital Settings Endpoints

### GET /capital-settings
Récupérer les paramètres du capital social

**Query Parameters:**
- `cooperative_id` (required)

### POST /capital-settings
Créer ou mettre à jour les paramètres

**Body:**
```json
{
  "cooperative_id": "coop-123",
  "valeur_part": 10000,
  "parts_min": 1,
  "parts_max": 100,
  "liberation_obligatoire": false
}
```

---

## 📊 Accounting Settings Endpoints

### GET /accounting-settings
Récupérer les paramètres comptables

### POST /accounting-settings
Créer ou mettre à jour

**Body:**
```json
{
  "cooperative_id": "coop-123",
  "exercice_actif": 2024,
  "plan_comptable": "SYSCOHADA",
  "taux_reserve": 0.1,
  "taux_frais_gestion": 0.05,
  "compte_caisse": "571",
  "compte_banque": "512"
}
```

---

## 🧾 Document Settings Endpoints

### GET /document-settings
Récupérer tous les paramètres de documents

### GET /document-settings/{type}
Récupérer par type (facture, recu, vente, etc.)

### POST /document-settings
Créer ou mettre à jour

**Body:**
```json
{
  "cooperative_id": "coop-123",
  "type_document": "facture",
  "prefix": "FAC",
  "format_numero": "{PREFIX}-{YEAR}-{NUM}",
  "pied_page": "Mentions légales...",
  "signature_auto": true
}
```

---

## 🔄 Utilisation en Mode Local (SQLite)

Pour utiliser ces endpoints en mode local, créer des adaptateurs qui appellent directement les services :

```dart
// Exemple d'adaptateur local
class LocalSettingsAdapter {
  final SettingsService _service = SettingsService();
  
  Future<SettingModel?> getSetting(String category, String key) async {
    return await _service.getSetting(
      category: category,
      key: key,
    );
  }
  
  Future<SettingModel> saveSetting({
    required String category,
    required String key,
    required dynamic value,
    required int userId,
  }) async {
    return await _service.saveSetting(
      category: category,
      key: key,
      value: value,
      userId: userId,
    );
  }
}
```

---

## 📝 Exemples d'Utilisation

### Exemple 1 : Récupérer le taux de commission

```dart
final service = SettingsService();
final commissionRate = await service.getValue<double>(
  category: 'finance',
  key: 'commission_rate',
  defaultValue: 0.05,
);
```

### Exemple 2 : Configurer les paramètres de document

```dart
final docRepo = DocumentSettingsRepository();
final settings = DocumentSettingsModel(
  cooperativeId: currentCoopId,
  typeDocument: DocumentType.facture,
  prefix: 'FAC',
  formatNumero: '{PREFIX}-{YEAR}-{NUM}',
  signatureAuto: true,
);

await docRepo.save(settings);
```

### Exemple 3 : Générer un numéro de facture

```dart
final docSettings = await docRepo.getByType(coopId, DocumentType.facture);
final numero = docSettings?.generateNumero(sequenceNumber);
// Résultat: FAC-2024-0001
```

