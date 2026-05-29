# Cahier des charges MandaCare - Version mobile/tablette

## 1. Positionnement

**MandaCare** est une application premium de gestion digitale pour le Cabinet de Soins Manda Nsappe de Logbessou.

L'objectif est de remplacer une gestion papier ou semi-numérique par un outil simple, fiable et sécurisé, utilisable prioritairement sur **mobile et tablette** par le personnel du centre.

Le produit doit aider le centre à :

- professionnaliser les documents médicaux et administratifs ;
- accélérer l'accueil, la consultation, le laboratoire et la caisse ;
- tracer les actions sensibles ;
- produire et partager des PDF propres par WhatsApp, email ou lien sécurisé.

## 2. Périmètre plateformes

La version actuelle est conçue pour :

- smartphones Android récents ;
- tablettes Android ;
- navigateur mobile/tablette si une application web responsive est retenue ;
- usage tactile prioritaire, avec gros boutons, formulaires lisibles et navigation simple.

Le desktop n'est pas dans le périmètre de conception pour le moment. Aucune maquette desktop, optimisation bureau ou workflow poste fixe n'est attendu en V1.

## 3. Utilisateurs cibles

### Administrateur principal

Pilote l'activité du centre, consulte les statistiques, gère les utilisateurs, les prestations, les prix, les documents, les paramètres et les exports.

### Accueil / Caisse

Crée les patients, ouvre les visites, gère la file d'attente, facture les actes, encaisse les paiements et génère les reçus.

### Médecin / Prescripteur

Consulte les dossiers patients, saisit les observations, prescrit examens et traitements, génère ordonnances et demandes d'examens.

### Infirmier / Soignant

Saisit les constantes, prépare les soins, complète les fiches utiles et consulte les informations autorisées.

### Laboratoire

Reçoit les demandes d'examens, vérifie le paiement, saisit les résultats, soumet à validation et génère les comptes rendus PDF.

### Patient

Ne dispose pas de compte en V1. Il reçoit ses documents par WhatsApp, email, PDF imprimé ou lien sécurisé selon son consentement.

## 4. MVP validé

Le MVP doit rester ambitieux mais maîtrisable. Les modules obligatoires sont :

1. Authentification et rôles.
2. Tableau de bord mobile/tablette.
3. Création et recherche patient.
4. Fiche patient avec historique.
5. File d'attente.
6. Consultation et constantes.
7. Prescription d'examens.
8. Ordonnance PDF.
9. Catalogue des prestations et tarifs.
10. Laboratoire simple.
11. Résultat de laboratoire PDF.
12. Facturation, paiements et reçu PDF.
13. Partage manuel ou semi-automatique par WhatsApp.
14. Paramètres du centre.
15. Journal d'audit des actions sensibles.

## 5. Hors périmètre V1

Les éléments suivants sont repoussés après le MVP :

- portail patient ;
- application mobile native séparée si une web app mobile suffit au départ ;
- stock pharmacie ;
- hospitalisation complète ;
- maternité complète ;
- gestion RH avancée ;
- rapports RGFOSA avancés ;
- synchronisation offline complète ;
- WhatsApp Business API officielle ;
- intégration Mobile Money automatique ;
- multi-centres.

## 6. Parcours prioritaires

### Parcours accueil

1. Rechercher ou créer un patient.
2. Ouvrir une visite.
3. Sélectionner le motif.
4. Orienter vers consultation, laboratoire, soins ou caisse.
5. Suivre le statut dans la file d'attente.

### Parcours consultation

1. Ouvrir le patient depuis la file.
2. Consulter le résumé médical.
3. Saisir les constantes et observations.
4. Poser diagnostic provisoire ou final.
5. Prescrire examens et/ou ordonnance.
6. Valider avec journalisation.

### Parcours laboratoire

1. Voir les examens demandés.
2. Filtrer par statut.
3. Vérifier le paiement.
4. Saisir les résultats.
5. Soumettre ou valider.
6. Générer le PDF.
7. Envoyer ou archiver.

### Parcours caisse

1. Voir les actes à payer.
2. Générer une facture.
3. Encaisser total ou partiel.
4. Générer un reçu.
5. Envoyer, imprimer ou archiver.

## 7. Modules fonctionnels

### Tableau de bord

Afficher les indicateurs du jour : patients, consultations, examens en attente, résultats validés, recettes, impayés, documents envoyés et alertes critiques.

### Patients

Chaque dossier contient l'identité, contacts, quartier, âge ou date de naissance, sexe, antécédents, allergies, personne à contacter, consentement numérique et historique.

### File d'attente

Les statuts doivent être visibles rapidement : en attente, en consultation, en laboratoire, en caisse, terminé, annulé, urgence.

### Consultation

La consultation contient motif, histoire, symptômes, constantes, examen clinique, diagnostic, examens demandés, traitement, conseils et notes confidentielles.

Après validation, une consultation ne doit plus être modifiable librement. Toute correction exige un motif et une trace d'audit.

### Ordonnances

Le PDF doit inclure logo, centre, patient, prescripteur, date, médicaments, posologie, conseils, signature, cachet, QR code et mention de confidentialité.

### Laboratoire

Le laboratoire couvre prescription, paiement, prélèvement, saisie, validation, PDF, envoi et archivage. Les résultats validés ne sont modifiables qu'avec autorisation spéciale.

### Facturation

La caisse doit gérer facture, remise autorisée, paiement total ou partiel, espèces, mobile money manuel, reste à payer, annulation contrôlée, reçu et clôture journalière simple.

### Partage documentaire

Chaque envoi de document doit enregistrer patient, canal, utilisateur, date, consentement et statut. Le lien sécurisé est préférable au PDF direct lorsque le document est sensible.

## 8. Sécurité et confidentialité

Exigences minimales :

- authentification obligatoire ;
- mots de passe forts ;
- rôles et permissions fines ;
- journal d'audit ;
- déconnexion après inactivité ;
- blocage après tentatives échouées ;
- sauvegarde automatique ;
- HTTPS en production ;
- accès limité selon le rôle ;
- consentement patient pour tout envoi numérique.

Exemple de restriction : la caisse voit les actes et montants, mais pas les détails médicaux complets.

## 9. Données principales

Les entités de base sont :

- Utilisateur, Rôle, Permission ;
- Patient, Visite, Consultation, Constantes ;
- Prescription, Ordonnance, Médicament ;
- Examen, DemandeExamen, RésultatExamen ;
- Prestation, Facture, Paiement, Reçu ;
- Document, Fichier, MessageEnvoyé ;
- Centre, Service, Personnel, AuditLog.

## 10. Identité visuelle

Nom retenu : **MandaCare**.

Slogan retenu : **Soigner mieux, gérer simplement.**

La direction artistique doit rester médicale, sobre, premium et humaine. Le logo recommandé combine :

- un **M** identifiable ;
- une croix médicale douce ;
- une feuille ou courbe protectrice ;
- un détail digital discret.

Palette recommandée :

- vert médical premium : `#0E7C66` ;
- bleu santé profond : `#0B3D5C` ;
- or doux premium : `#D4A94F` ;
- fond clair : `#F7FAF9` ;
- texte principal : `#344054`.

Typographie recommandée :

- Inter pour l'application ;
- Manrope ou Montserrat pour les titres et documents officiels.

## 11. Design mobile/tablette

Les écrans doivent être conçus pour un usage tactile :

- navigation inférieure sur mobile ;
- menus latéraux ou onglets étendus sur tablette ;
- cartes lisibles ;
- boutons d'action larges ;
- formulaires découpés en sections courtes ;
- statuts colorés explicites ;
- preview PDF avant envoi ;
- confirmation pour les actions sensibles.

Les mockups actuels valident bien la direction mobile. Il faut maintenant produire les équivalents tablette pour les écrans critiques : dashboard, file d'attente, fiche patient, consultation, laboratoire, facturation et partage.

## 12. Documents PDF

Les PDF prioritaires du MVP sont :

1. Ordonnance.
2. Demande d'examen.
3. Résultat de laboratoire.
4. Facture.
5. Reçu.
6. Fiche patient simplifiée.
7. Rapport journalier simple.

Chaque PDF doit être lisible en A4, contenir le logo, les coordonnées, un titre clair, une signature, un cachet, un QR code et une mention de confidentialité.

## 13. Critères d'acceptation MVP

Le MVP est acceptable si :

- un patient peut être créé en moins de 2 minutes ;
- une consultation peut générer ordonnance et examens ;
- la caisse peut facturer et encaisser un acte ;
- le laboratoire peut produire un résultat PDF ;
- un document peut être envoyé ou imprimé depuis mobile/tablette ;
- les rôles limitent réellement l'accès aux données sensibles ;
- les actions critiques sont tracées ;
- l'application reste lisible sur smartphone et tablette ;
- l'identité visuelle est cohérente avec les mockups et documents PDF.

## 14. Livrables immédiats

Pour lancer proprement la suite, produire :

1. Backlog MVP priorisé.
2. Matrice rôles/permissions.
3. Modèle de données détaillé.
4. Maquettes mobile finalisées.
5. Maquettes tablette des écrans critiques.
6. Templates PDF officiels.
7. Logo vectoriel et déclinaisons.
8. Guide de style UI.
9. Plan de tests fonctionnels.
10. Plan de sécurité et sauvegarde.



