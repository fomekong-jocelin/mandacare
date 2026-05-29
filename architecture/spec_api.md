# Spécification API MVP - MandaCare

## Principes API

Base URL :

```text
/api/v1
```

Format :

- JSON pour les échanges applicatifs.
- PDF retourné par téléchargement sécurisé.
- Dates au format ISO 8601.
- Identifiants au format UUID.
- Pagination sur les listes.

Sécurité :

- JWT obligatoire hors endpoints d'authentification.
- Permissions vérifiées côté backend.
- Validation Bean Validation sur toutes les entrées.
- Erreurs homogènes.

## Format d'erreur

```json
{
  "code": "PATIENT_NOT_FOUND",
  "message": "Patient introuvable.",
  "details": [],
  "timestamp": "2026-05-29T14:00:00Z"
}
```

## Authentification

### POST `/auth/login`

Connecte un utilisateur.

Entrée :

```json
{
  "identifier": "admin",
  "password": "secret"
}
```

Sortie :

```json
{
  "accessToken": "...",
  "expiresAt": "2026-05-29T16:00:00Z",
  "user": {
    "id": "uuid",
    "fullName": "Admin Centre",
    "role": "ADMIN"
  }
}
```

### GET `/auth/me`

Retourne l'utilisateur connecté, son rôle et ses permissions.

## Utilisateurs et rôles

### GET `/users`

Liste les utilisateurs. Réservé administrateur.

### POST `/users`

Crée un utilisateur.

### PATCH `/users/{id}/status`

Active ou désactive un utilisateur.

### GET `/roles`

Liste les rôles disponibles.

## Patients

### GET `/patients`

Recherche paginée.

Paramètres :

- `q`
- `phone`
- `patientNumber`
- `page`
- `size`

### POST `/patients`

Crée un patient.

Champs minimum :

- `firstName`
- `lastName`
- `sex`
- `phone`
- `birthDate` ou `declaredAge`
- `digitalConsent`

### GET `/patients/{id}`

Retourne la fiche patient selon les droits de l'utilisateur.

### PATCH `/patients/{id}`

Modifie les informations autorisées.

### GET `/patients/{id}/timeline`

Retourne l'historique filtré : visites, consultations, examens, factures, documents.

## Visites et file d'attente

### POST `/visits`

Ouvre une visite.

Entrée :

```json
{
  "patientId": "uuid",
  "reason": "Fièvre",
  "targetService": "CONSULTATION",
  "priority": "NORMAL"
}
```

### GET `/visits/today`

Liste la file d'attente du jour.

Paramètres :

- `status`
- `service`
- `priority`

### PATCH `/visits/{id}/status`

Change le statut d'une visite.

### POST `/visits/{id}/cancel`

Annule une visite avec motif.

## Constantes et consultations

### POST `/visits/{visitId}/vitals`

Saisit les constantes.

### GET `/visits/{visitId}/vitals/latest`

Retourne les dernières constantes de la visite.

### POST `/consultations`

Crée une consultation brouillon.

### GET `/consultations/{id}`

Retourne une consultation selon permissions.

### PATCH `/consultations/{id}`

Modifie une consultation brouillon.

### POST `/consultations/{id}/validate`

Valide et verrouille la consultation.

### POST `/consultations/{id}/corrections`

Corrige une consultation validée avec motif obligatoire.

## Ordonnances

### POST `/consultations/{consultationId}/prescriptions`

Crée une ordonnance.

### GET `/prescriptions/{id}`

Retourne l'ordonnance.

### POST `/prescriptions/{id}/validate`

Valide l'ordonnance.

### POST `/prescriptions/{id}/pdf`

Génère ou régénère le PDF selon permission.

### GET `/prescriptions/{id}/pdf`

Télécharge le PDF.

## Examens et laboratoire

### GET `/exams`

Liste le catalogue des examens.

### POST `/consultations/{consultationId}/exam-requests`

Crée une demande d'examen.

### GET `/exam-requests`

Liste les demandes d'examens.

Paramètres :

- `status`
- `patientId`
- `date`
- `urgent`

### GET `/exam-requests/{id}`

Détail d'une demande.

### PATCH `/exam-requests/{id}/status`

Change le statut laboratoire.

### POST `/exam-requests/{id}/results`

Crée un résultat brouillon.

### PATCH `/lab-results/{id}`

Modifie un résultat brouillon.

### POST `/lab-results/{id}/validate`

Valide le résultat.

### POST `/lab-results/{id}/pdf`

Génère le PDF officiel.

## Prestations, factures et paiements

### GET `/benefits`

Liste les prestations.

### POST `/benefits`

Crée une prestation. Réservé administrateur.

### POST `/invoices`

Crée une facture.

### GET `/invoices/{id}`

Détail facture.

### PATCH `/invoices/{id}`

Modifie une facture non payée.

### POST `/invoices/{id}/cancel`

Annule une facture avec motif.

### POST `/invoices/{id}/payments`

Enregistre un paiement.

Entrée :

```json
{
  "amount": 10000,
  "mode": "CASH",
  "reference": null
}
```

### POST `/payments/{id}/receipt`

Génère le reçu PDF.

## Documents et partage

### GET `/patients/{patientId}/documents`

Liste les documents du patient selon permissions.

### GET `/documents/{id}`

Détail document.

### GET `/documents/{id}/download`

Téléchargement sécurisé.

### POST `/documents/{id}/share`

Prépare et journalise un partage.

Entrée :

```json
{
  "channel": "WHATSAPP",
  "recipient": "+237...",
  "consentConfirmed": true
}
```

## Dashboard

### GET `/dashboard/today`

Retourne les indicateurs du jour.

Sortie :

```json
{
  "patientsToday": 24,
  "consultationsToday": 16,
  "pendingExams": 8,
  "validatedResults": 5,
  "dailyRevenue": 185000,
  "unpaidInvoices": 3
}
```

## Audit

### GET `/audit-logs`

Liste filtrée des actions sensibles. Réservé administrateur.

Paramètres :

- `module`
- `userId`
- `entityType`
- `from`
- `to`

## Paramètres

### GET `/settings/center`

Retourne les informations du centre.

### PATCH `/settings/center`

Met à jour les informations du centre. Réservé administrateur.

