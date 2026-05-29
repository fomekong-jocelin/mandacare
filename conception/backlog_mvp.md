# Backlog MVP MandaCare - Mobile/Tablette

## Objectif

Ce backlog transforme le cadrage mobile/tablette en unités fonctionnelles développables. Le MVP doit permettre au centre de gérer le parcours patient complet : accueil, consultation, laboratoire, caisse, PDF et partage.

## Priorité P0 - Socle obligatoire

### AUTH-01 - Connexion utilisateur

En tant qu'utilisateur interne, je veux me connecter avec identifiant et mot de passe afin d'accéder uniquement aux fonctions autorisées.

Critères d'acceptation :

- connexion obligatoire avant tout accès ;
- message clair en cas d'identifiants invalides ;
- blocage temporaire après plusieurs échecs ;
- déconnexion manuelle disponible ;
- déconnexion automatique après inactivité.

### AUTH-02 - Rôles et permissions

En tant qu'administrateur, je veux attribuer un rôle à chaque utilisateur afin de limiter l'accès aux données sensibles.

Critères d'acceptation :

- rôles minimum : administrateur, accueil/caisse, médecin, infirmier, laboratoire ;
- permissions appliquées sur lecture, création, modification, validation, annulation, export et envoi ;
- accès médical complet interdit au rôle caisse ;
- toutes les modifications de permissions sont journalisées.

### PARAM-01 - Paramètres du centre

En tant qu'administrateur, je veux configurer les informations du centre afin qu'elles apparaissent sur les écrans et PDF.

Critères d'acceptation :

- nom, adresse, contacts, logo, slogan, responsable ;
- cachet et signatures configurables ;
- mentions de confidentialité configurables ;
- modification journalisée.

## Priorité P1 - Parcours patient

### PAT-01 - Création patient

En tant qu'accueil, je veux créer un patient en moins de 2 minutes afin d'ouvrir rapidement une visite.

Critères d'acceptation :

- champs requis : nom, prénom, sexe, âge ou date de naissance, téléphone ;
- numéro patient généré automatiquement ;
- téléphone WhatsApp distinct si nécessaire ;
- consentement numérique enregistré ;
- fiche consultable immédiatement après création.

### PAT-02 - Recherche patient

En tant qu'utilisateur autorisé, je veux retrouver un patient par nom, téléphone ou numéro afin d'éviter les doublons.

Critères d'acceptation :

- recherche visible depuis les écrans principaux ;
- résultats lisibles sur mobile ;
- alerte si plusieurs patients similaires existent ;
- accès au dossier selon le rôle.

### PAT-03 - Fiche patient

En tant que soignant, je veux consulter le résumé du patient afin de voir rapidement les informations importantes.

Critères d'acceptation :

- identité, contacts, allergies, antécédents, alertes ;
- onglets : résumé, consultations, examens, ordonnances, factures, documents ;
- historique chronologique ;
- données médicales masquées pour les rôles non autorisés.

### WAIT-01 - File d'attente

En tant qu'accueil, je veux suivre les patients du jour afin d'orienter chaque visite vers le bon service.

Critères d'acceptation :

- création d'une visite depuis un patient ;
- statuts : en attente, consultation, laboratoire, caisse, terminé, annulé, urgence ;
- filtres par statut et service ;
- temps d'attente affiché ;
- action "appeler le prochain" disponible.

## Priorité P2 - Consultation

### CONS-01 - Saisie des constantes

En tant qu'infirmier, je veux saisir les constantes afin de préparer la consultation.

Critères d'acceptation :

- température, tension, pouls, fréquence respiratoire, saturation, poids, taille ;
- IMC calculé automatiquement si poids et taille renseignés ;
- valeurs visibles dans la consultation ;
- modification tracée.

### CONS-02 - Consultation médicale

En tant que médecin, je veux saisir la consultation afin de documenter le diagnostic et les décisions médicales.

Critères d'acceptation :

- motif, symptômes, examen clinique, diagnostic provisoire/final ;
- conseils et notes confidentielles ;
- génération d'ordonnance ou demande d'examens ;
- validation obligatoire avant archivage ;
- consultation validée non modifiable sans correction journalisée.

### PRESC-01 - Prescription d'examens

En tant que médecin, je veux prescrire des examens depuis un catalogue afin d'accélérer le passage au laboratoire.

Critères d'acceptation :

- sélection multiple ;
- prix proposé depuis le catalogue ;
- urgence normale ou urgente ;
- demande d'examen générée ;
- passage caisse possible si paiement requis.

### ORDO-01 - Ordonnance PDF

En tant que médecin, je veux générer une ordonnance PDF afin de remettre un document officiel au patient.

Critères d'acceptation :

- médicaments avec dosage, fréquence, durée et conseils ;
- aperçu PDF avant envoi ou impression ;
- QR code de vérification ;
- signature/cachet configurables ;
- document archivé dans le dossier patient.

## Priorité P3 - Laboratoire et caisse

### LAB-01 - Liste des examens à traiter

En tant que laboratoire, je veux voir les examens demandés afin de prioriser mon travail.

Critères d'acceptation :

- filtres : prescrit, en attente paiement, payé, prélèvement, résultat en cours, validé ;
- indication d'urgence ;
- accès uniquement aux informations nécessaires ;
- historique de statut.

### LAB-02 - Résultat laboratoire

En tant que laboratoire, je veux saisir et valider un résultat afin de produire un PDF officiel.

Critères d'acceptation :

- modèle de résultat simple avec tableau, unités et valeurs de référence ;
- états : brouillon, en attente validation, validé ;
- résultat validé verrouillé ;
- PDF généré et archivé.

### CAISSE-01 - Facturation

En tant que caisse, je veux facturer les actes afin d'encaisser correctement les prestations.

Critères d'acceptation :

- facture créée depuis une visite, consultation ou demande d'examen ;
- ajout manuel d'une prestation autorisé ;
- remise soumise à permission ;
- total, payé et reste à payer calculés ;
- annulation contrôlée et journalisée.

### CAISSE-02 - Paiement et reçu

En tant que caisse, je veux enregistrer un paiement afin de produire un reçu.

Critères d'acceptation :

- modes MVP : espèces, mobile money manuel ;
- paiement total ou partiel ;
- reçu PDF généré ;
- paiement visible dans le dossier patient ;
- clôture journalière simple.

## Priorité P4 - Partage et pilotage

### SHARE-01 - Partage de document

En tant qu'utilisateur autorisé, je veux envoyer un document au patient afin de limiter l'impression.

Critères d'acceptation :

- canaux : WhatsApp manuel/semi-automatique, email, téléchargement PDF ;
- consentement patient vérifié ;
- confirmation du numéro avant envoi ;
- journal d'envoi avec utilisateur, date, canal et statut ;
- possibilité de préférer un lien sécurisé au PDF direct.

### DASH-01 - Tableau de bord

En tant qu'administrateur, je veux consulter l'activité du jour afin de piloter le centre.

Critères d'acceptation :

- patients du jour, consultations, examens en attente, résultats validés ;
- recettes du jour et impayés ;
- alertes : résultats non validés, factures impayées, documents non envoyés ;
- affichage lisible sur tablette et mobile.

### AUDIT-01 - Journal d'audit

En tant qu'administrateur, je veux consulter les actions sensibles afin de contrôler la traçabilité.

Critères d'acceptation :

- connexions, créations, modifications, validations, annulations, envois, exports ;
- utilisateur, date, action, entité, ancien/nouveau statut si utile ;
- journal non modifiable par les utilisateurs standards.

