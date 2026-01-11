# Module Ventes V2 - Documentation Technique

## Vue d'ensemble

Le Module Ventes V2 étend le Module Ventes V1 avec des fonctionnalités avancées d'intelligence décisionnelle, gestion financière, workflow organisationnel et impact social.

## Architecture

```
lib/
├── data/
│   └── models/
│       ├── lot_vente_model.dart              # Modèle Lot de Vente
│       ├── lot_vente_detail_model.dart        # Détails d'un lot
│       ├── simulation_vente_model.dart        # Simulation de vente
│       ├── validation_vente_model.dart       # Workflow de validation
│       ├── creance_client_model.dart         # Créances clients
│       ├── fonds_social_model.dart           # Fonds social
│       └── historique_simulation_model.dart   # Historique simulations
├── services/
│   └── vente/
│       ├── simulation_vente_service.dart     # Service simulation
│       ├── lot_vente_service.dart            # Service lots intelligents
│       ├── creance_client_service.dart       # Service créances
│       ├── validation_workflow_service.dart  # Service workflow
│       └── fonds_social_service.dart         # Service fonds social
└── services/database/migrations/
    └── ventes_v2_migrations.dart            # Migrations V2
```

## Structure de la base de données V2

### Table `lots_vente`

```sql
CREATE TABLE lots_vente (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code_lot TEXT UNIQUE NOT NULL,
  campagne_id INTEGER,
  qualite TEXT,
  categorie_producteur TEXT,
  quantite_total REAL NOT NULL,
  prix_unitaire_propose REAL NOT NULL,
  client_id INTEGER,
  statut TEXT DEFAULT 'preparation',
  notes TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL,
  date_validation TEXT,
  date_vente TEXT,
  FOREIGN KEY (campagne_id) REFERENCES campagnes(id),
  FOREIGN KEY (client_id) REFERENCES clients(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

### Table `lot_vente_details`

```sql
CREATE TABLE lot_vente_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lot_vente_id INTEGER NOT NULL,
  adherent_id INTEGER NOT NULL,
  quantite REAL NOT NULL,
  is_exclu INTEGER DEFAULT 0,
  raison_exclusion TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (lot_vente_id) REFERENCES lots_vente(id),
  FOREIGN KEY (adherent_id) REFERENCES adherents(id)
)
```

### Table `simulations_vente`

```sql
CREATE TABLE simulations_vente (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lot_vente_id INTEGER,
  client_id INTEGER,
  campagne_id INTEGER,
  quantite_total REAL NOT NULL,
  prix_unitaire_propose REAL NOT NULL,
  montant_brut REAL NOT NULL,
  montant_commission REAL NOT NULL,
  montant_net REAL NOT NULL,
  montant_fonds_social REAL DEFAULT 0.0,
  prix_moyen_jour REAL DEFAULT 0.0,
  prix_moyen_precedent REAL DEFAULT 0.0,
  marge_cooperative REAL DEFAULT 0.0,
  indicateurs TEXT,
  statut TEXT DEFAULT 'simulee',
  notes TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL,
  date_validation TEXT,
  FOREIGN KEY (lot_vente_id) REFERENCES lots_vente(id),
  FOREIGN KEY (client_id) REFERENCES clients(id),
  FOREIGN KEY (campagne_id) REFERENCES campagnes(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

### Table `validations_vente`

```sql
CREATE TABLE validations_vente (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vente_id INTEGER NOT NULL,
  etape TEXT NOT NULL,
  statut TEXT DEFAULT 'en_attente',
  valide_par INTEGER,
  commentaire TEXT,
  created_at TEXT NOT NULL,
  date_validation TEXT,
  FOREIGN KEY (vente_id) REFERENCES ventes(id),
  FOREIGN KEY (valide_par) REFERENCES users(id)
)
```

### Table `creances_clients`

```sql
CREATE TABLE creances_clients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vente_id INTEGER NOT NULL,
  client_id INTEGER NOT NULL,
  montant_total REAL NOT NULL,
  montant_paye REAL DEFAULT 0.0,
  montant_restant REAL NOT NULL,
  date_vente TEXT NOT NULL,
  date_echeance TEXT NOT NULL,
  date_paiement TEXT,
  statut TEXT DEFAULT 'en_attente',
  jours_retard INTEGER,
  is_client_bloque INTEGER DEFAULT 0,
  notes TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY (vente_id) REFERENCES ventes(id),
  FOREIGN KEY (client_id) REFERENCES clients(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

### Table `fonds_social`

```sql
CREATE TABLE fonds_social (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vente_id INTEGER,
  source TEXT NOT NULL,
  montant REAL NOT NULL,
  pourcentage REAL,
  description TEXT NOT NULL,
  date_contribution TEXT NOT NULL,
  notes TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL,
  ecriture_comptable_id INTEGER,
  FOREIGN KEY (vente_id) REFERENCES ventes(id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (ecriture_comptable_id) REFERENCES ecritures_comptables(id)
)
```

### Table `historiques_simulation`

```sql
CREATE TABLE historiques_simulation (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  simulation_id INTEGER NOT NULL,
  action TEXT NOT NULL,
  donnees_avant TEXT,
  donnees_apres TEXT,
  commentaire TEXT,
  user_id INTEGER,
  created_at TEXT NOT NULL,
  FOREIGN KEY (simulation_id) REFERENCES simulations_vente(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
)
```

## Fonctionnalités V2

### 1. Vente par lots intelligents

**Service**: `LotVenteService`

- Constitution automatique de lots par :
  - **Campagne** : `createLotParCampagne()`
  - **Qualité** : `createLotParQualite()`
  - **Catégorie producteur** : `createLotParCategorie()`
- Visualisation avant validation
- Exclusion manuelle possible : `exclureAdherentDuLot()`
- Réintégration : `reintegrerAdherentDansLot()`

### 2. Simulation de vente

**Service**: `SimulationVenteService`

- Simulation complète avant validation : `createSimulation()`
- Comparaisons :
  - Prix du jour : `_getPrixMoyenJour()`
  - Ventes précédentes : `_getPrixMoyenPrecedent()`
- Indicateurs calculés :
  - Marge coopérative
  - Impact adhérents
  - Niveaux de risque
  - Écarts de prix
- Validation : `validerSimulation()`
- Rejet : `rejeterSimulation()`

### 3. Paiement différé client

**Service**: `CreanceClientService`

- Création de créance : `createCreance()`
- Enregistrement paiement : `enregistrerPaiement()`
- Suivi créances : `getCreancesByClient()`
- Blocage automatique si retard : `_verifierBlocageClient()`
- Statistiques : `getStatistiquesCreances()`

### 4. Workflow de validation

**Service**: `ValidationWorkflowService`

- Étapes :
  1. **Préparation** (gestionnaire) : `validerPreparation()`
  2. **Validation Prix** (superviseur) : `validerPrix()`
  3. **Confirmation Finale** (admin) : `validerConfirmationFinale()`
- Journal de validation obligatoire
- Rejet possible : `rejeterEtape()`
- Suivi : `getWorkflowVente()`

### 5. Impact social intégré

**Service**: `FondsSocialService`

- Contribution depuis vente : `createContributionFromVente()`
- Contribution manuelle : `createContributionManuelle()`
- Affichage sur facture (à implémenter dans module facturation)
- Écriture comptable automatique
- Statistiques : `getStatistiquesFondsSocial()`

## Services créés

### SimulationVenteService

- `createSimulation()` : Créer une simulation avec comparaisons et indicateurs
- `getSimulationById()` : Récupérer une simulation
- `validerSimulation()` : Valider une simulation (convertir en vente)
- `rejeterSimulation()` : Rejeter une simulation
- `getAllSimulations()` : Récupérer toutes les simulations

### LotVenteService

- `createLotParCampagne()` : Créer un lot par campagne
- `createLotParQualite()` : Créer un lot par qualité
- `createLotParCategorie()` : Créer un lot par catégorie producteur
- `exclureAdherentDuLot()` : Exclure un adhérent d'un lot
- `reintegrerAdherentDansLot()` : Réintégrer un adhérent
- `getLotById()` : Récupérer un lot
- `getLotDetails()` : Récupérer les détails d'un lot
- `validerLot()` : Valider un lot
- `getAllLots()` : Récupérer tous les lots

### CreanceClientService

- `createCreance()` : Créer une créance pour paiement différé
- `enregistrerPaiement()` : Enregistrer un paiement
- `getCreanceById()` : Récupérer une créance
- `getCreancesByClient()` : Récupérer les créances d'un client
- `getCreancesEnRetard()` : Récupérer les créances en retard
- `getAllCreances()` : Récupérer toutes les créances
- `debloquerClient()` : Débloquer un client
- `getStatistiquesCreances()` : Statistiques des créances

### ValidationWorkflowService

- `initialiserWorkflow()` : Initialiser le workflow pour une vente
- `validerPreparation()` : Valider l'étape préparation
- `validerPrix()` : Valider l'étape validation prix
- `validerConfirmationFinale()` : Valider la confirmation finale
- `rejeterEtape()` : Rejeter une étape
- `getWorkflowVente()` : Récupérer le workflow d'une vente
- `getEtapeActuelle()` : Récupérer l'étape actuelle
- `getVentesEnAttenteValidation()` : Récupérer les ventes en attente

### FondsSocialService

- `createContributionFromVente()` : Créer contribution depuis vente
- `createContributionManuelle()` : Créer contribution manuelle
- `getContributionById()` : Récupérer une contribution
- `getContributionsByVente()` : Récupérer contributions d'une vente
- `getAllContributions()` : Récupérer toutes les contributions
- `getStatistiquesFondsSocial()` : Statistiques du fonds social

## Migration

La migration vers la version 13 est automatique lors de la mise à jour de la base de données.

**Fichier**: `lib/services/database/migrations/ventes_v2_migrations.dart`

**Version base de données**: 13 (mise à jour dans `app_config.dart`)

## Prochaines étapes

### À implémenter (UI)

1. **Écrans V2** :
   - `SimulationVenteScreen` : Interface de simulation
   - `LotsVenteScreen` : Gestion des lots
   - `ValidationWorkflowScreen` : Workflow de validation
   - `CreancesClientsScreen` : Suivi créances
   - `FondsSocialScreen` : Gestion fonds social
   - `AnalysePrixScreen` : Analyse prix/marge

2. **Widgets de visualisation** :
   - Graphiques de comparaison prix
   - Alertes risques
   - Indicateurs couleur
   - Tableaux de bord

3. **Extension ViewModel** :
   - Ajouter les méthodes V2 dans `VenteViewModel`
   - Gestion d'état pour simulations, lots, validations

## Notes techniques

- Tous les services utilisent des transactions pour garantir la cohérence
- Les écritures comptables sont créées automatiquement pour le fonds social
- Le blocage automatique des clients est vérifié à chaque paiement
- L'historique des simulations est conservé pour audit
- Les indicateurs de simulation incluent des niveaux de risque

## Sécurité

- Toutes les actions sont auditées via `AuditService`
- Les validations multi-niveaux garantissent la sécurité
- Les écritures comptables sont automatiques et traçables
- Les QR codes sont générés pour les ventes (V1)

## Performance

- Index créés sur toutes les colonnes fréquemment utilisées
- Requêtes optimisées avec jointures
- Pagination recommandée pour les grandes listes

