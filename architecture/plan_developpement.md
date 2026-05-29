# Plan de Développement MVP - MandaCare

## Hypothèse d'organisation

Le MVP est découpé en lots fonctionnels livrables. Chaque lot doit produire une fonctionnalité testable sur mobile/tablette et connectée au backend.

Ordre recommandé :

1. Socle technique.
2. Authentification et permissions.
3. Patients et file d'attente.
4. Consultation et ordonnances.
5. Examens et laboratoire.
6. Facturation et reçus.
7. Documents, PDF et partage.
8. Dashboard, audit et stabilisation.

## Lot 0 - Initialisation projet

### Backend

- Créer projet Spring Boot Maven.
- Configurer Java 21.
- Ajouter dépendances : Web, Security, Data JPA, PostgreSQL, Flyway, Validation, Actuator, OpenAPI.
- Configurer profils `dev`, `test`, `prod`.
- Configurer PostgreSQL local.
- Ajouter migration initiale Flyway.
- Ajouter structure de packages.

### Flutter

- Créer projet Flutter.
- Configurer thème MandaCare.
- Configurer routing.
- Configurer client HTTP.
- Préparer stockage sécurisé du token.
- Créer composants UI de base.

### Livrables

- Backend démarre.
- App Flutter démarre.
- Connexion PostgreSQL validée.
- Documentation README technique initiale.

## Lot 1 - Authentification, rôles et paramètres

### Backend

- Entités utilisateur, rôle, permission.
- Login JWT.
- Endpoint `/auth/me`.
- Middleware sécurité.
- Paramètres du centre.
- Audit des connexions.

### Flutter

- Écran login.
- Gestion session.
- Redirection selon authentification.
- Écran paramètres centre en lecture.

### Tests

- Login succès/échec.
- Accès refusé sans token.
- Permissions appliquées.

## Lot 2 - Patients et file d'attente

### Backend

- CRUD patient contrôlé.
- Recherche patient.
- Timeline patient.
- Visite.
- File d'attente du jour.
- Statuts visite.

### Flutter

- Recherche patient.
- Création patient.
- Fiche patient.
- Nouvelle visite.
- File d'attente mobile/tablette.

### Tests

- Création patient avec champs requis.
- Recherche par nom/téléphone/numéro.
- Création visite.
- Changement statut.

## Lot 3 - Consultation et ordonnance

### Backend

- Constantes.
- Consultation brouillon.
- Validation consultation.
- Correction avec motif.
- Ordonnance.
- Lignes médicaments.
- Génération PDF ordonnance.

### Flutter

- Saisie constantes.
- Écran consultation.
- Création ordonnance.
- Aperçu ordonnance.
- Téléchargement/partage ordonnance.

### Tests

- Consultation validée verrouillée.
- Correction journalisée.
- Ordonnance PDF générée.

## Lot 4 - Examens et laboratoire

### Backend

- Catalogue examens.
- Demande d'examen.
- Statuts laboratoire.
- Résultat brouillon.
- Validation résultat.
- PDF résultat laboratoire.

### Flutter

- Prescription examens.
- Liste examens demandés.
- Détail demande.
- Saisie résultat.
- Aperçu PDF résultat.

### Tests

- Demande multi-examens.
- Filtre par statut.
- Résultat validé verrouillé.

## Lot 5 - Facturation et paiements

### Backend

- Catalogue prestations.
- Factures.
- Lignes facture.
- Remises avec permission.
- Paiements espèces et mobile money manuel.
- Reçu PDF.
- Annulation contrôlée.

### Flutter

- Actes à payer.
- Facture.
- Paiement.
- Reçu.
- Clôture journalière simple si retenue.

### Tests

- Totaux corrects.
- Paiement partiel.
- Reste à payer.
- Reçu généré après paiement.

## Lot 6 - Documents et partage

### Backend

- Entité Document.
- Téléchargement sécurisé.
- Journal d'envoi.
- Préparation partage WhatsApp/email.
- QR code.

### Flutter

- Liste documents patient.
- Preview document.
- Confirmation consentement.
- Partage WhatsApp ou téléchargement.
- Historique d'envoi.

### Tests

- Envoi impossible sans consentement confirmé.
- Journal créé après partage.
- Accès document filtré par rôle.

## Lot 7 - Dashboard, audit et stabilisation

### Backend

- Dashboard du jour.
- Audit logs filtrables.
- Rapports journaliers simples.
- Durcissement sécurité.
- Logs structurés.

### Flutter

- Dashboard.
- Alertes.
- Écran audit admin si nécessaire.
- États vides, erreurs, chargement.

### Tests

- Indicateurs cohérents.
- Audit non modifiable.
- Parcours complet accueil -> consultation -> caisse -> PDF.

## Définition de terminé

Une fonctionnalité est terminée si :

- endpoint backend implémenté ;
- validation des entrées faite ;
- permissions appliquées ;
- audit ajouté si action sensible ;
- écran Flutter connecté ;
- erreurs affichées clairement ;
- tests backend minimum passants ;
- cas mobile et tablette vérifiés ;
- documentation API mise à jour.

## Risques à surveiller

- Périmètre MVP trop large.
- PDF livrés trop tard.
- Permissions codées uniquement côté Flutter.
- Données médicales dans les logs.
- Tables sans contraintes d'intégrité.
- Écrans tablette oubliés.
- Absence de stratégie de sauvegarde.

