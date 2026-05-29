# Choix Techniques MandaCare

## Stack retenue

Le MVP MandaCare sera construit avec :

- **Mobile/tablette** : Flutter.
- **Backend API** : Java + Spring Boot + Maven.
- **Base de données** : PostgreSQL.
- **Génération PDF** : backend Spring Boot.
- **Stockage fichiers** : stockage local sécurisé au départ, extensible vers stockage objet.
- **Authentification** : Spring Security avec JWT.
- **Documentation API** : OpenAPI/Swagger.
- **Migrations base** : Flyway.

## Raisons du choix

### Flutter

Flutter permet de produire une application mobile/tablette cohérente, tactile, rapide et adaptée au terrain. Le même code pourra cibler Android mobile et tablette.

Priorité MVP :

- Android d'abord ;
- interface mobile/tablette ;
- navigation simple ;
- fonctionnement connecté ;
- offline complet repoussé après MVP.

### Spring Boot + Java + Maven

Spring Boot fournit un backend robuste, structuré et maintenable pour gérer des données médicales sensibles.

Standards retenus :

- Java 21 ;
- Spring Boot 3.4.x ;
- Maven ;
- architecture en couches ;
- DTO d'entrée/sortie ;
- validation Bean Validation ;
- transactions au niveau service ;
- gestion globale des erreurs ;
- tests JUnit 5.

### PostgreSQL

PostgreSQL est adapté aux données relationnelles du domaine : patients, visites, consultations, examens, factures, paiements et documents.

Principes :

- clés primaires UUID ;
- contraintes d'intégrité ;
- index sur recherches fréquentes ;
- migrations versionnées ;
- sauvegardes automatiques.

## Décisions MVP

### Application connectée

Le MVP fonctionne principalement en ligne. L'offline complet est hors périmètre. Une gestion minimale des erreurs réseau doit toutefois être prévue côté Flutter.

### PDF côté backend

Tous les PDF officiels sont générés côté backend pour garantir cohérence, traçabilité, QR code, archivage et sécurité.

### WhatsApp semi-automatique

Le MVP prépare le message et le document, puis déclenche un partage WhatsApp côté mobile si possible. L'intégration WhatsApp Business API est hors périmètre.

### Mobile Money manuel

Le MVP permet d'enregistrer un paiement mobile money avec référence saisie manuellement. L'intégration automatique opérateur est hors périmètre.

### Stockage fichiers

Les fichiers PDF générés sont stockés et référencés par l'entité `Document`. Le stockage doit pouvoir évoluer vers S3 compatible, MinIO ou serveur privé.

## Sécurité minimale

- HTTPS obligatoire en production.
- JWT court avec mécanisme de renouvellement.
- Mots de passe hachés avec BCrypt.
- Rôles et permissions appliqués côté backend.
- Journal d'audit pour actions sensibles.
- Aucun détail médical dans les logs.
- Validation stricte des entrées API.
- Limitation des exports selon rôle.

## Observabilité minimale

- Logs structurés côté backend.
- Actuator activé sur endpoints restreints.
- Journal technique des erreurs.
- Journal métier via `AuditLog`.
- Identifiant de corrélation par requête.

## Outils recommandés

Backend :

- Spring Web
- Spring Security
- Spring Data JPA
- PostgreSQL Driver
- Flyway
- Bean Validation
- Springdoc OpenAPI
- Actuator
- JUnit 5 / Mockito

Mobile :

- Flutter stable
- Riverpod ou Bloc pour l'état
- Dio pour HTTP
- GoRouter pour navigation
- Freezed/json_serializable pour modèles immuables
- Secure Storage pour tokens

## Hors périmètre technique MVP

- Desktop.
- Portail patient.
- Multi-centres.
- Offline complet.
- Signature numérique avancée.
- Paiement mobile money automatique.
- WhatsApp Business API officielle.
- Déploiement haute disponibilité complexe.

