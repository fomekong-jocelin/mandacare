# Règles Qualité MandaCare

## Principe général

MandaCare doit rester premium, maintenable et lisible. Le projet refuse les gros fichiers fourre-tout, les contrôleurs chargés, les écrans Flutter monolithiques et les raccourcis qui fragilisent la sécurité médicale.

## Limite de taille

- Aucun fichier de code applicatif ne doit dépasser **500 lignes**.
- Objectif recommandé : 50 à 250 lignes par fichier.
- Si un fichier approche 300 lignes, extraire un composant, service, DTO, mapper ou policy.
- Les fichiers générés par les outils peuvent être ignorés, mais ne doivent pas être modifiés à la main inutilement.

## Backend Spring Boot

- Java 21, Spring Boot 3.4.x, Maven.
- Architecture par modules métier.
- Flux recommandé : controller -> service -> domain/policy -> repository.
- Pas de logique métier dans les contrôleurs.
- Pas de logique métier lourde dans les entités JPA.
- DTO en `record` quand les données sont immuables.
- Validation d'entrée avec Bean Validation.
- Transactions au niveau service.
- Exceptions métier explicites et gestion globale des erreurs.
- Permissions toujours vérifiées côté backend.
- Aucune donnée médicale sensible dans les logs.

## Flutter mobile/tablette

- Design mobile/tablette uniquement pour la V1.
- Thème premium centralisé dans `lib/app/theme`.
- Écrans dans `features/<module>/presentation`.
- Composants réutilisables dans `widgets`.
- Une action principale claire par écran.
- Boutons larges, cartes lisibles, statuts avec couleur et texte.
- Pas de logique métier critique côté UI.
- Tous les accès sensibles restent validés côté API.

## Design premium

- Palette officielle : vert `#0E7C66`, bleu `#0B3D5C`, or `#D4A94F`.
- Rayon de bordure sobre : 8 px.
- Textes courts, lisibles, sans surcharge.
- Icônes explicites pour les actions.
- Les PDF doivent rester aussi soignés que l'interface.

## Avant validation d'une fonctionnalité

- Compilation backend OK.
- Analyse Flutter OK.
- Permissions vérifiées.
- Audit ajouté si action sensible.
- État vide, chargement et erreur prévus côté mobile.
- Aucun fichier applicatif au-dessus de 500 lignes.

