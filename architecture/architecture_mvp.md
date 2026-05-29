# Architecture MVP MandaCare

## Vue d'ensemble

MandaCare suit une architecture client mobile/tablette + API backend + base PostgreSQL.

Flux principal :

```text
Flutter mobile/tablette
        |
        | HTTPS / JSON
        v
Spring Boot API
        |
        | JPA / SQL
        v
PostgreSQL
        |
        v
Stockage PDF / fichiers
```

Le backend est l'autorité métier : permissions, validations, calculs, génération PDF, audit et cohérence des données.

## Découpage backend

Structure recommandée :

```text
src/main/java/cm/mandacare/api/
  MandaCareApplication.java
  config/
  security/
  common/
    error/
    pagination/
    audit/
  module/
    auth/
    user/
    patient/
    visit/
    consultation/
    prescription/
    laboratory/
    billing/
    document/
    dashboard/
    setting/
```

Chaque module suit une structure stable :

```text
module/patient/
  PatientController.java
  PatientService.java
  PatientRepository.java
  Patient.java
  dto/
  mapper/
```

Pour les règles plus complexes, ajouter :

```text
policy/
event/
```

## Règles d'architecture backend

- Les contrôleurs exposent les endpoints et délèguent.
- Les services portent les transactions et règles métier.
- Les entités JPA restent simples.
- Les repositories ne contiennent pas de logique métier.
- Les DTO isolent l'API des entités.
- Les exceptions métier passent par un `@RestControllerAdvice`.
- Les opérations sensibles écrivent dans `AuditLog`.

## Modules backend MVP

### Auth

Responsabilités :

- connexion ;
- émission JWT ;
- renouvellement si retenu ;
- déconnexion logique côté client ;
- blocage temporaire après échecs.

### User / Role / Permission

Responsabilités :

- gestion utilisateurs ;
- attribution rôles ;
- contrôle des permissions ;
- statut actif/inactif.

### Patient

Responsabilités :

- création patient ;
- recherche ;
- fiche patient ;
- historique filtré selon rôle.

### Visit

Responsabilités :

- ouverture de visite ;
- file d'attente ;
- changement de statut ;
- urgence ;
- orientation service.

### Consultation

Responsabilités :

- constantes ;
- consultation ;
- validation ;
- correction contrôlée ;
- notes confidentielles.

### Prescription

Responsabilités :

- ordonnance ;
- lignes médicaments ;
- prescription d'examens ;
- demande d'examen.

### Laboratory

Responsabilités :

- liste des demandes ;
- statut laboratoire ;
- saisie résultat ;
- validation ;
- PDF résultat.

### Billing

Responsabilités :

- prestations ;
- factures ;
- remises autorisées ;
- paiements ;
- reçus ;
- clôture journalière simple.

### Document

Responsabilités :

- génération PDF ;
- stockage ;
- QR code ;
- partage ;
- journal d'envoi.

### Dashboard

Responsabilités :

- indicateurs du jour ;
- recettes ;
- impayés ;
- alertes.

## Architecture Flutter

Structure recommandée :

```text
lib/
  main.dart
  app/
    router/
    theme/
    config/
  core/
    api/
    auth/
    storage/
    errors/
    widgets/
  features/
    auth/
    dashboard/
    patients/
    queue/
    consultation/
    prescriptions/
    laboratory/
    billing/
    documents/
    settings/
```

Chaque feature contient :

```text
features/patients/
  data/
    patient_api.dart
    patient_dto.dart
  domain/
    patient.dart
  presentation/
    screens/
    widgets/
    state/
```

## Règles Flutter

- UI mobile/tablette uniquement.
- Navigation claire par onglets bas sur mobile.
- Adaptation tablette avec layouts plus larges.
- Token stocké dans un stockage sécurisé.
- Erreurs API affichées en langage simple.
- Pas de logique métier critique côté client.
- Tous les droits sont revalidés côté backend.

## Base de données

Schéma recommandé :

- `auth_users`
- `roles`
- `permissions`
- `patients`
- `visits`
- `vitals`
- `consultations`
- `prescriptions`
- `prescription_lines`
- `exams`
- `exam_requests`
- `exam_request_lines`
- `lab_results`
- `lab_result_lines`
- `services`
- `benefits`
- `invoices`
- `invoice_lines`
- `payments`
- `receipts`
- `documents`
- `sent_messages`
- `audit_logs`
- `center_settings`

## Gestion des statuts

Les statuts doivent être des enums côté backend et exposés clairement côté API.

Exemples :

- visite : `WAITING`, `CONSULTATION`, `LABORATORY`, `CASHIER`, `DONE`, `CANCELLED`, `EMERGENCY`
- facture : `DRAFT`, `PARTIAL`, `PAID`, `CANCELLED`
- résultat : `DRAFT`, `PENDING_VALIDATION`, `VALIDATED`
- document : `GENERATED`, `SENT`, `PRINTED`, `ARCHIVED`

## Stratégie PDF

Le backend génère le PDF, crée une ligne `Document`, stocke le fichier, retourne une URL sécurisée ou un identifiant de téléchargement.

Règles :

- génération seulement par utilisateur autorisé ;
- QR code unique ;
- lien de téléchargement contrôlé ;
- document archivé dans le dossier patient ;
- envoi journalisé.

## Audit

Toute action sensible doit générer une entrée `audit_logs`.

Actions prioritaires :

- connexion ;
- création patient ;
- modification patient ;
- validation consultation ;
- correction consultation ;
- validation résultat ;
- génération PDF ;
- envoi document ;
- paiement ;
- annulation facture ;
- changement permission.

## Déploiement MVP

Architecture simple recommandée au départ :

```text
Flutter APK
Spring Boot API
PostgreSQL
Stockage fichiers local sécurisé
Reverse proxy HTTPS
Sauvegarde quotidienne
```

Le backend et PostgreSQL peuvent être hébergés sur un serveur privé au départ, avec sauvegardes automatisées et restauration testée.

