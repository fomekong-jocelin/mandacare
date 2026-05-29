# Architecture MandaCare

Ce dossier décrit les choix techniques et l'architecture du MVP mobile/tablette.

## Stack validée

- Backend : Java, Spring Boot, Maven.
- Base de données : PostgreSQL.
- Mobile/tablette : Flutter.
- PDF : génération côté backend.
- Sécurité : Spring Security + JWT.
- Migrations : Flyway.

## Fichiers

- `choix_techniques.md` : stack, décisions MVP, sécurité, outils.
- `architecture_mvp.md` : découpage backend, Flutter, base, audit et déploiement.
- `spec_api.md` : endpoints API MVP.
- `plan_developpement.md` : lots de développement.

## Sources liées

- `conception/backlog_mvp.md`
- `conception/matrice_roles_permissions.md`
- `conception/modele_donnees.md`
- `conception/parcours_mobile_tablette.md`
- `conception/templates_pdf.md`

## Règle de périmètre

La V1 reste mobile/tablette. Le desktop, le portail patient, le multi-centres, l'offline complet, WhatsApp Business API et Mobile Money automatique restent hors MVP.

