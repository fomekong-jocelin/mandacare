# CAHIER DES CHARGES

## Application premium de gestion digitale du Cabinet de Soins Manda Nsappe

**Version :** 1.0
**Projet :** Digitalisation complète d’un centre de santé
**Nom provisoire de l’application :** MandaCare
**Structure cible :** Cabinet de Soins Manda Nsappe de Logbessou
**Objectif :** Concevoir une application moderne, sécurisée, professionnelle et premium permettant de gérer l’ensemble des activités d’un centre de santé : patients, consultations, examens, prescriptions, laboratoire, facturation, documents médicaux, envoi WhatsApp, administration, statistiques et archivage.

---

# 1. Vision du projet

L’objectif du projet est de créer une application médicale premium, simple à utiliser, robuste et adaptée à la réalité des centres de santé au Cameroun.

L’application doit permettre au Cabinet de Soins Manda Nsappe de passer d’une gestion papier ou semi-numérique à une gestion digitale complète, fiable et professionnelle.

L’application doit respecter trois ambitions fortes :

1. **Professionnaliser l’image du centre**
   Tous les documents produits doivent être propres, modernes, officiels et cohérents avec l’identité du centre.

2. **Simplifier le travail quotidien du personnel**
   L’accueil, la consultation, les examens, les résultats, la caisse et les archives doivent être accessibles depuis une interface claire.

3. **Sécuriser les données médicales**
   Les dossiers patients, ordonnances, résultats de laboratoire et documents administratifs doivent être protégés, traçables et accessibles uniquement aux personnes autorisées.

---

# 2. Objectifs principaux

L’application devra permettre de :

* Créer et gérer les dossiers patients.
* Enregistrer les consultations.
* Prescrire des examens médicaux.
* Produire des ordonnances digitales.
* Saisir et valider les résultats de laboratoire.
* Générer des documents PDF professionnels.
* Envoyer les documents au patient via WhatsApp ou autre canal autorisé.
* Gérer les prestations et les tarifs du centre.
* Gérer la caisse, les paiements et les reçus.
* Suivre les statistiques du centre.
* Archiver les documents administratifs.
* Gérer le personnel, les rôles et les accès.
* Préparer à terme des rapports inspirés des exigences RGFOSA/MINSANTE.

---

# 3. Public cible

## 3.1 Utilisateurs internes

L’application doit prévoir plusieurs profils :

### Administrateur principal

Généralement la responsable du centre.
Elle doit avoir accès à toute l’activité : patients, consultations, recettes, statistiques, documents, personnel, paramètres et rapports.

### Médecin / Prescripteur

Il doit pouvoir consulter les dossiers patients, saisir les observations médicales, prescrire des examens, rédiger des ordonnances et consulter les résultats.

### Infirmier / Soignant

Il doit pouvoir enregistrer les constantes, créer des fiches de soins, suivre les patients, préparer les actes et consulter certaines informations selon ses droits.

### Technicien de laboratoire

Il doit pouvoir voir les examens demandés, enregistrer les prélèvements, saisir les résultats, générer les comptes rendus et soumettre à validation.

### Caissier / Agent d’accueil

Il doit pouvoir créer les patients, rechercher un patient, enregistrer une visite, facturer les actes, encaisser les paiements et imprimer ou envoyer les reçus.

### Gestionnaire administratif

Il doit pouvoir gérer les documents du centre, le personnel, les attestations, les archives et certaines informations administratives.

## 3.2 Utilisateurs externes

### Patient

Dans la première version, le patient ne dispose pas forcément d’un compte. Il reçoit ses documents par WhatsApp, SMS, email ou lien sécurisé.

Dans une version future, un portail patient pourra être ajouté pour consulter ses ordonnances, résultats, rendez-vous et historique.

---

# 4. Périmètre fonctionnel global

L’application devra couvrir les modules suivants :

1. Tableau de bord
2. Gestion des patients
3. Accueil et file d’attente
4. Consultation médicale
5. Constantes et soins
6. Prescription d’examens
7. Ordonnances
8. Laboratoire
9. Résultats médicaux
10. Catalogue des prestations
11. Tarification
12. Facturation et caisse
13. Reçus et documents financiers
14. Partage WhatsApp / PDF / Email
15. Gestion documentaire administrative
16. Gestion du personnel
17. Rapports et statistiques
18. Paramètres du centre
19. Sécurité et confidentialité
20. Charte graphique et identité visuelle

---

# 5. Module Tableau de bord

## 5.1 Objectif

Donner à la responsable du centre une vision immédiate de l’activité.

## 5.2 Indicateurs à afficher

Le tableau de bord devra afficher :

* Nombre de patients du jour.
* Nombre de consultations du jour.
* Nombre d’examens prescrits.
* Nombre d’examens en attente de résultats.
* Nombre de résultats validés.
* Recettes journalières.
* Recettes hebdomadaires.
* Recettes mensuelles.
* Nombre de documents envoyés par WhatsApp.
* Alertes importantes.
* Patients en attente.
* Examens non payés.
* Factures impayées.
* Résultats non validés.
* Stock critique, en phase future si pharmacie ajoutée.

## 5.3 Expérience attendue

Le tableau de bord doit être très lisible, avec de grandes cartes, des icônes médicales élégantes et une priorité donnée aux actions du jour.

---

# 6. Module Gestion des patients

## 6.1 Création du dossier patient

Le formulaire patient devra contenir :

* Numéro patient généré automatiquement.
* Nom et prénom.
* Sexe.
* Date de naissance ou âge.
* Téléphone.
* Téléphone WhatsApp.
* Quartier.
* Ville.
* Profession.
* État matrimonial.
* Personne à contacter.
* Téléphone de la personne à contacter.
* Groupe sanguin, si connu.
* Allergies connues.
* Antécédents médicaux.
* Antécédents chirurgicaux.
* Antécédents familiaux.
* Observations particulières.
* Consentement pour l’envoi numérique de documents.
* Date de création du dossier.

## 6.2 Recherche patient

Recherche rapide par :

* Nom.
* Téléphone.
* Numéro patient.
* Date de naissance.
* Quartier.

## 6.3 Historique patient

Chaque dossier patient doit afficher :

* Consultations passées.
* Ordonnances.
* Examens prescrits.
* Résultats de laboratoire.
* Factures.
* Paiements.
* Documents envoyés.
* Notes internes.
* Alertes médicales.

## 6.4 Exigence UX

La fiche patient doit être claire, sobre, rassurante et organisée sous forme d’onglets :

* Résumé
* Consultations
* Examens
* Ordonnances
* Factures
* Documents
* Notes

---

# 7. Module Accueil et file d’attente

## 7.1 Objectif

Permettre à l’accueil de gérer l’arrivée des patients.

## 7.2 Fonctionnalités

* Enregistrer une nouvelle visite.
* Sélectionner le motif de venue.
* Orienter vers consultation, laboratoire, soins, caisse ou autre service.
* Attribuer un statut :

    * En attente
    * En consultation
    * En laboratoire
    * En caisse
    * Terminé
    * Annulé
* Afficher la file d’attente en temps réel.
* Prioriser les urgences.
* Voir l’heure d’arrivée.
* Voir le temps d’attente.

## 7.3 Statuts visuels

* Vert : terminé
* Bleu : en cours
* Orange : en attente
* Rouge : urgence
* Gris : annulé

---

# 8. Module Consultation médicale

## 8.1 Objectif

Permettre au prescripteur de réaliser une consultation complète.

## 8.2 Fiche de consultation

La consultation devra contenir :

* Date et heure.
* Médecin ou soignant responsable.
* Motif de consultation.
* Histoire de la maladie.
* Symptômes.
* Constantes.
* Examen clinique.
* Diagnostic provisoire.
* Diagnostic final.
* Examens demandés.
* Traitement prescrit.
* Conseils donnés.
* Rendez-vous de contrôle.
* Notes confidentielles réservées au personnel médical.

## 8.3 Constantes à saisir

* Température.
* Tension artérielle.
* Pouls.
* Fréquence respiratoire.
* Saturation en oxygène.
* Poids.
* Taille.
* IMC automatique.
* Glycémie capillaire, si nécessaire.

## 8.4 Exigences spécifiques

* Une consultation ne doit pas pouvoir être modifiée librement après validation sans journal de modification.
* Toute modification doit être tracée avec utilisateur, date, heure et motif.
* Une consultation doit pouvoir générer une ordonnance et/ou une demande d’examen.

---

# 9. Module Prescription d’examens

## 9.1 Objectif

Permettre au praticien de prescrire rapidement des examens depuis un catalogue prédéfini.

## 9.2 Catalogue initial d’examens

L’application devra intégrer le catalogue existant du centre, notamment :

* Ionogramme complet
* Magnésium
* SGOT
* SGPT
* Électrophorèse HB
* Groupe sanguin ABO/Rhésus
* NFS
* VS
* Coprologie / selles
* HIV
* Hépatites A, B, C
* Ag HBs Elisa
* Chlamydia
* Rubéole
* BW
* ECBU simple
* ECBU + antibiogramme
* PCV simple
* PCV + antibiogramme
* Acide urique / uricémie
* Albumine / sucre
* Calcium
* Chlore
* Bilan lipidique
* Chimie urinaire
* Glycémie
* Toxoplasmose
* GE
* Test de grossesse
* Typhoïde
* H. pylori
* Circoncision
* Spermoculture
* Mycoplasme
* Spermogramme

## 9.3 Fonctionnalités

* Sélection d’un ou plusieurs examens.
* Prix automatique selon catalogue.
* Possibilité de modifier le prix avec autorisation.
* Génération d’une demande d’examen.
* Statut de l’examen :

    * Prescrit
    * En attente de paiement
    * Payé
    * Prélèvement effectué
    * Résultat en cours
    * Résultat validé
    * Résultat envoyé
* Impression ou envoi numérique de la demande.

---

# 10. Module Ordonnances

## 10.1 Objectif

Produire des ordonnances professionnelles, propres, signées et archivées.

## 10.2 Contenu d’une ordonnance

* Logo du centre.
* Nom officiel du centre.
* Ministère / délégation / localisation selon charte.
* Téléphone du centre.
* Numéro de l’ordonnance.
* Date.
* Identité du patient.
* Âge.
* Sexe.
* Nom du prescripteur.
* Médicaments prescrits.
* Posologie.
* Durée.
* Conseils.
* Signature.
* Cachet.
* QR code de vérification.
* Mention de confidentialité.

## 10.3 Médicaments

Chaque ligne de médicament doit contenir :

* Nom du médicament.
* Forme.
* Dosage.
* Quantité.
* Fréquence.
* Durée.
* Instructions.
* Commentaire.

## 10.4 Exigence premium

L’ordonnance doit être belle, lisible et digne d’un centre moderne. Elle doit pouvoir être imprimée en A4 ou envoyée en PDF.

---

# 11. Module Laboratoire

## 11.1 Objectif

Gérer les examens biologiques depuis la prescription jusqu’au résultat final.

## 11.2 Workflow laboratoire

1. Réception de la demande.
2. Vérification du paiement.
3. Enregistrement du prélèvement.
4. Saisie des résultats.
5. Contrôle.
6. Validation.
7. Génération du PDF.
8. Envoi au patient.
9. Archivage automatique dans le dossier patient.

## 11.3 Types de résultats à prévoir

L’application devra proposer des modèles de résultats pour :

* Sérologie HIV.
* Hématologie / NFS.
* Bactériologie.
* ECBU.
* Chimie du sang.
* Biochimie.
* Spermogramme.
* Tests rapides.
* Autres examens configurables.

## 11.4 Contenu d’un résultat de laboratoire

* Entête du centre.
* Type d’examen.
* Patient.
* Âge.
* Sexe.
* Prescripteur.
* Date de prélèvement.
* Date d’édition.
* Numéro du résultat.
* Tableau des résultats.
* Valeurs de référence.
* Unités.
* Commentaires.
* Conclusion.
* Signature du biologiste ou responsable.
* Cachet.
* QR code de vérification.

## 11.5 Validation des résultats

Un résultat doit avoir trois états :

* Brouillon
* En attente de validation
* Validé

Un résultat validé ne doit pas être modifiable sans autorisation spéciale.

---

# 12. Module Facturation et caisse

## 12.1 Objectif

Gérer les paiements et les recettes du centre.

## 12.2 Fonctionnalités

* Création de facture.
* Ajout automatique des actes prescrits.
* Ajout manuel d’un acte.
* Remise autorisée selon rôle.
* Encaissement total ou partiel.
* Paiement en espèces.
* Paiement mobile money.
* Paiement bancaire, en option.
* Reste à payer.
* Reçu PDF.
* Historique des paiements.
* Annulation contrôlée.
* Clôture journalière de caisse.

## 12.3 Reçu

Le reçu doit contenir :

* Numéro de reçu.
* Date.
* Patient.
* Actes facturés.
* Montant total.
* Montant payé.
* Reste à payer.
* Mode de paiement.
* Caissier.
* Signature ou cachet.
* QR code de vérification.

## 12.4 Rapports financiers

* Recettes du jour.
* Recettes par période.
* Recettes par type d’acte.
* Recettes par utilisateur.
* Impayés.
* Remises accordées.
* Annulations.
* Export Excel/PDF.

---

# 13. Module Partage WhatsApp, email et PDF

## 13.1 Objectif

Permettre au centre d’envoyer les documents aux patients simplement, tout en protégeant les données sensibles.

## 13.2 Documents partageables

* Ordonnance.
* Résultat de laboratoire.
* Reçu.
* Demande d’examen.
* Certificat ou attestation.
* Rendez-vous.
* Conseils post-consultation.

## 13.3 Règles de sécurité

L’application doit prévoir :

* Consentement du patient avant envoi.
* Journal des documents envoyés.
* Date et heure d’envoi.
* Utilisateur ayant envoyé.
* Canal utilisé.
* Possibilité d’envoyer un lien sécurisé au lieu d’un PDF direct.
* Expiration du lien.
* QR code de vérification.
* Protection contre l’envoi au mauvais numéro.

## 13.4 Message WhatsApp type

Bonjour [Nom du patient],
Veuillez trouver votre document médical émis par le Cabinet de Soins Manda Nsappe.
Pour votre confidentialité, ne partagez ce document qu’avec un professionnel de santé ou une personne de confiance.
Bonne guérison.

---

# 14. Module Documents administratifs

## 14.1 Objectif

Créer un coffre numérique du centre.

## 14.2 Documents à stocker

* Autorisation d’exercice.
* Arrêté de création.
* Arrêté d’ouverture.
* Arrêté de transformation.
* Convention avec le MINSANTE.
* Titre foncier ou document foncier.
* Photos de façade.
* Documents du personnel.
* Attestations de stage.
* Contrats.
* Documents fiscaux.
* Rapports.
* Courriers officiels.

## 14.3 Fonctionnalités

* Upload PDF/image.
* Classement par catégorie.
* Date d’expiration, si applicable.
* Alerte avant expiration.
* Recherche.
* Téléchargement.
* Accès limité aux administrateurs.
* Historique des consultations.

---

# 15. Module Gestion du personnel

## 15.1 Objectif

Gérer les acteurs du centre.

## 15.2 Données personnel

* Nom.
* Prénom.
* Fonction.
* Téléphone.
* Email.
* Rôle dans l’application.
* Type de contrat.
* Date d’entrée.
* Statut actif/inactif.
* Numéro d’ordre professionnel, si applicable.
* Autorisation d’exercice, si applicable.
* Documents associés.
* Signature numérique, si autorisée.

## 15.3 Rôles applicatifs

* Super administrateur.
* Administrateur centre.
* Médecin.
* Infirmier.
* Laboratoire.
* Caisse.
* Accueil.
* Lecture seule.
* Auditeur.

## 15.4 Permissions

Chaque rôle doit avoir des permissions précises :

* Voir.
* Créer.
* Modifier.
* Valider.
* Supprimer.
* Exporter.
* Envoyer.
* Encaisser.
* Administrer.

---

# 16. Module Rapports et statistiques

## 16.1 Objectif

Aider la responsable du centre à piloter l’activité.

## 16.2 Statistiques médicales

* Nombre de patients par période.
* Consultations par période.
* Examens par type.
* Résultats produits.
* Patients hommes/femmes.
* Patients par tranche d’âge.
* Activités de maternité, si activées.
* Soins à domicile, si activés.
* Vaccination, si activée.
* Hospitalisation/observation, si activée.

## 16.3 Statistiques administratives

* Personnel actif.
* Documents manquants.
* Documents expirant bientôt.
* Équipements disponibles.
* Services actifs.
* Situation inspirée RGFOSA.

## 16.4 Exports

* Export PDF.
* Export Excel.
* Rapport mensuel.
* Rapport annuel.
* Rapport personnalisable.

---

# 17. Sécurité, confidentialité et conformité

## 17.1 Principes

L’application traite des données médicales sensibles. Elle doit être conçue avec un niveau élevé de sécurité.

## 17.2 Exigences obligatoires

* Authentification par identifiant et mot de passe.
* Mot de passe fort.
* Option de double authentification.
* Gestion des rôles.
* Permissions fines.
* Journal d’activité.
* Sauvegarde automatique.
* Chiffrement des données sensibles.
* Connexion sécurisée HTTPS.
* Déconnexion automatique après inactivité.
* Blocage après tentatives échouées.
* Traçabilité des modifications.
* Archivage sécurisé.
* Consentement patient pour le partage numérique.
* Suppression contrôlée ou anonymisation selon règles applicables.

## 17.3 Journal d’audit

Le système doit enregistrer :

* Connexions.
* Consultations de dossiers.
* Créations.
* Modifications.
* Suppressions.
* Validations.
* Exports.
* Envois WhatsApp/email.
* Annulations de factures.
* Changements de paramètres.

## 17.4 Confidentialité

Aucun utilisateur ne doit accéder à une information non nécessaire à son rôle.

Exemple :

* Le caissier voit les actes et les montants, mais pas les détails médicaux complets.
* Le laboratoire voit les examens à traiter, mais pas toute l’histoire médicale.
* Le médecin voit les données médicales complètes.
* L’administrateur peut gérer les accès et les rapports.

---

# 18. Exigences techniques

## 18.1 Plateformes

La solution devra être disponible au minimum sur :

* Application web responsive.
* Tablette.
* Mobile.
* Ordinateur.

Une application mobile Android pourra être prévue en phase 2.

## 18.2 Mode offline

Le système devra idéalement prévoir un fonctionnement partiel hors connexion :

* Création de patient.
* Consultation.
* Facture.
* Ordonnance.
* Synchronisation dès retour Internet.

## 18.3 Architecture recommandée

* Frontend : React, Next.js ou Flutter Web.
* Backend : Node.js, NestJS, Laravel ou Django.
* Base de données : PostgreSQL.
* Stockage fichiers : stockage cloud sécurisé ou serveur privé.
* Génération PDF : service dédié.
* Authentification : JWT sécurisé ou session sécurisée.
* Sauvegarde : quotidienne automatique.

## 18.4 Hébergement

L’hébergement doit garantir :

* Disponibilité élevée.
* Sauvegardes automatiques.
* Accès sécurisé.
* Possibilité de restauration.
* Journalisation.
* Évolutivité.

---

# 19. Documents PDF à générer

L’application devra générer des documents propres et premium :

1. Ordonnance.
2. Demande d’examen.
3. Résultat de laboratoire.
4. Reçu de paiement.
5. Facture.
6. Attestation de stage.
7. Certificat simple.
8. Rapport journalier.
9. Rapport mensuel.
10. Fiche patient.
11. Fiche de consultation.
12. Rapport RGFOSA simplifié.

Chaque document doit respecter la charte graphique du centre.

---

# 20. Charte graphique premium

## 20.1 Positionnement visuel

L’identité visuelle doit refléter :

* La santé.
* La confiance.
* La propreté.
* La modernité.
* La proximité humaine.
* Le sérieux administratif.
* Le côté premium voulu pour honorer la responsable du centre.

Le design doit éviter l’aspect “application bricolée”. Il doit donner l’impression d’un outil professionnel, fiable et digne d’une clinique moderne.

## 20.2 Nom recommandé

Nom principal recommandé : **MandaCare**

Variantes possibles :

* MandaCare
* Manda Santé
* MandaCare Clinic
* MandaCare Pro
* Manda Digital Health

Recommandation : **MandaCare**
Court, moderne, mémorisable, facile à prononcer, compatible avec une future extension à d’autres centres.

## 20.3 Slogan recommandé

Options :

* “Le centre de santé, simplement digital.”
* “Soigner mieux, gérer simplement.”
* “La santé organisée, humaine et digitale.”
* “Votre centre, vos patients, vos soins — en toute confiance.”
* “La technologie au service du soin.”

Slogan recommandé :
**“Soigner mieux, gérer simplement.”**

## 20.4 Logo

### Concept du logo

Le logo doit combiner trois symboles :

1. **Une croix médicale douce**
   Pour identifier immédiatement le domaine de la santé.

2. **Une feuille ou une courbe protectrice**
   Pour représenter le soin, la douceur, la maman, l’humain et la guérison.

3. **Un signe digital discret**
   Par exemple un pixel, un cercle connecté, un QR code stylisé ou une ligne numérique.

### Direction artistique

Le logo doit être :

* Moderne.
* Sobre.
* Premium.
* Lisible.
* Utilisable sur fond blanc et fond sombre.
* Compatible avec une icône d’application.
* Éviter les logos trop chargés.
* Éviter les images de stéthoscope trop génériques.
* Éviter le rouge agressif dominant.
* Garder une touche médicale sans tomber dans le cliché.

### Versions attendues

Le designer devra livrer :

* Logo principal horizontal.
* Logo vertical.
* Icône seule.
* Version fond blanc.
* Version fond sombre.
* Version monochrome.
* Version noir et blanc.
* Version favicon.
* Version app icon Android/iOS.
* Logo en SVG, PNG, PDF.

## 20.5 Palette de couleurs

### Couleur principale

**Vert médical premium**
Hex : #0E7C66
Utilisation : boutons principaux, logo, titres importants, éléments de confiance.

### Couleur secondaire

**Bleu santé profond**
Hex : #0B3D5C
Utilisation : en-têtes, navigation, documents officiels, éléments administratifs.

### Couleur d’accent

**Or doux premium**
Hex : #D4A94F
Utilisation : détails premium, badges, éléments de validation, petites touches visuelles.

### Couleurs neutres

* Blanc pur : #FFFFFF
* Fond clair : #F7FAF9
* Gris texte : #344054
* Gris secondaire : #667085
* Bordure : #D0D5DD
* Fond carte : #FFFFFF

### Couleurs fonctionnelles

* Succès : #12B76A
* Alerte : #F79009
* Erreur : #D92D20
* Information : #2E90FA

## 20.6 Typographies

### Police principale

**Inter**
Utilisation : application web, mobile, tableaux, formulaires.

### Police secondaire

**Manrope** ou **Montserrat**
Utilisation : titres, documents, branding.

### Hiérarchie typographique

* H1 : 28 à 32 px, gras.
* H2 : 22 à 24 px, semi-gras.
* H3 : 18 à 20 px, semi-gras.
* Texte normal : 14 à 16 px.
* Petit texte : 12 à 13 px.
* Boutons : 14 à 16 px, semi-gras.

## 20.7 Style UI

L’interface doit être :

* Très claire.
* Aérée.
* Moderne.
* Accessible.
* Mobile-first.
* Adaptée à des utilisateurs non techniciens.
* Avec de gros boutons d’action.
* Avec des icônes compréhensibles.
* Avec des messages simples.

## 20.8 Composants UI

Le design system doit inclure :

* Boutons primaires.
* Boutons secondaires.
* Boutons danger.
* Champs de formulaire.
* Menus déroulants.
* Tableaux.
* Cartes statistiques.
* Badges de statut.
* Modales de confirmation.
* Toasts de notification.
* Onglets.
* Barre de recherche.
* Filtres.
* Calendrier.
* File d’attente.
* Timeline patient.
* Prévisualisation PDF.

## 20.9 Style des documents PDF

Les documents doivent avoir :

* Un entête officiel propre.
* Le logo.
* Le nom complet du centre.
* Les contacts.
* Une ligne de séparation élégante.
* Un titre clair.
* Des tableaux propres.
* Une signature.
* Un cachet.
* Un QR code.
* Une mention de confidentialité.
* Une mise en page A4 imprimable.

---

# 21. Expérience utilisateur attendue

## 21.1 Principes UX

L’application doit respecter ces principes :

* Une action importante doit être accessible en moins de 3 clics.
* Les écrans doivent être compréhensibles sans formation lourde.
* Les données sensibles doivent être protégées par défaut.
* Les erreurs doivent être expliquées en langage simple.
* Le personnel doit gagner du temps, pas en perdre.
* Les interfaces doivent être utilisables sur ordinateur, tablette et téléphone.

## 21.2 Parcours principaux

### Parcours patient en consultation

1. Accueil crée ou retrouve le patient.
2. Accueil ouvre une visite.
3. Infirmier saisit les constantes.
4. Médecin consulte le patient.
5. Médecin prescrit examens et/ou ordonnance.
6. Caisse facture.
7. Laboratoire traite les examens.
8. Résultat validé.
9. Document envoyé au patient.
10. Dossier archivé.

### Parcours laboratoire

1. Voir les examens du jour.
2. Filtrer par statut.
3. Ouvrir une demande.
4. Saisir les résultats.
5. Vérifier les valeurs.
6. Valider.
7. Générer PDF.
8. Envoyer.
9. Archiver.

### Parcours caisse

1. Voir actes à payer.
2. Générer facture.
3. Encaisser.
4. Générer reçu.
5. Envoyer ou imprimer.
6. Clôturer la caisse.

---

# 22. MVP recommandé

La première version doit être ambitieuse mais maîtrisée.

## 22.1 Fonctionnalités MVP obligatoires

* Connexion utilisateur.
* Gestion des rôles.
* Tableau de bord simple.
* Création patient.
* Fiche patient.
* File d’attente.
* Consultation.
* Constantes.
* Prescription d’examens.
* Ordonnance PDF.
* Catalogue des prestations.
* Laboratoire simple.
* Résultat PDF.
* Facturation.
* Reçu PDF.
* Envoi WhatsApp manuel ou semi-automatique.
* Coffre documentaire simple.
* Paramètres du centre.
* Historique patient.
* Sauvegarde.

## 22.2 Fonctionnalités hors MVP

À prévoir après la première version :

* Application mobile native.
* Portail patient.
* Stock pharmacie.
* Hospitalisation complète.
* Maternité complète.
* Gestion avancée RH.
* Rapports RGFOSA avancés.
* Synchronisation offline complète.
* Signature numérique avancée.
* Intégration WhatsApp Business API officielle.
* Intégration Mobile Money.
* Multi-centres.

---

# 23. Back-office et paramètres

L’administrateur doit pouvoir configurer :

* Nom du centre.
* Logo.
* Adresse.
* Téléphones.
* Emails.
* Responsable.
* Cachet numérique.
* Signatures.
* Liste des services.
* Liste des prestations.
* Prix.
* Utilisateurs.
* Rôles.
* Modèles de documents.
* Messages WhatsApp.
* Mentions de confidentialité.
* Modes de paiement.
* Paramètres de sauvegarde.

---

# 24. Modèle de données principal

## 24.1 Entités principales

* Utilisateur
* Rôle
* Permission
* Patient
* Visite
* Consultation
* Constantes
* Prescription
* Ordonnance
* Médicament
* Examen
* DemandeExamen
* RésultatExamen
* Facture
* Paiement
* Reçu
* Document
* Personnel
* Centre
* Service
* Prestation
* AuditLog
* MessageEnvoyé
* Fichier

## 24.2 Relations clés

* Un patient peut avoir plusieurs visites.
* Une visite peut contenir une consultation.
* Une consultation peut produire une ordonnance.
* Une consultation peut produire plusieurs demandes d’examens.
* Une demande d’examen peut générer un résultat.
* Une facture peut contenir plusieurs prestations.
* Un paiement est lié à une facture.
* Un document est lié à un patient, une consultation, un résultat ou une facture.
* Tout événement important est lié à un utilisateur dans le journal d’audit.

---

# 25. Critères d’acceptation

Le projet sera considéré comme réussi si :

* Le centre peut créer un patient en moins de 2 minutes.
* Le centre peut produire une ordonnance PDF professionnelle.
* Le centre peut prescrire et facturer des examens.
* Le laboratoire peut saisir un résultat et produire un PDF propre.
* Un reçu peut être généré après paiement.
* Les documents peuvent être envoyés par WhatsApp ou téléchargés.
* Les utilisateurs ont des droits différents selon leur rôle.
* Les actions importantes sont tracées.
* Les données restent sécurisées.
* L’application fonctionne correctement sur ordinateur et tablette.
* L’identité visuelle est premium, cohérente et professionnelle.
* La responsable du centre peut consulter les statistiques du jour.

---

# 26. Livrables attendus

## 26.1 Design

* Logo complet.
* Charte graphique.
* UI kit.
* Maquettes desktop.
* Maquettes mobile.
* Maquettes tablette.
* Design des documents PDF.
* Prototype interactif Figma.

## 26.2 Technique

* Application web.
* Backend.
* Base de données.
* Système d’authentification.
* Génération PDF.
* Système d’upload documentaire.
* Tableau de bord.
* Module patient.
* Module consultation.
* Module laboratoire.
* Module facturation.
* Module partage.
* Module administration.

## 26.3 Documentation

* Documentation utilisateur.
* Documentation administrateur.
* Documentation technique.
* Guide de déploiement.
* Guide de sauvegarde.
* Guide de sécurité.
* Manuel rapide pour le personnel.

---

# 27. Planning recommandé

## Phase 1 : Cadrage et conception

Durée estimée : 1 à 2 semaines

Livrables :

* Validation du cahier des charges.
* Arborescence de l’application.
* Parcours utilisateurs.
* Charte graphique.
* Logo.
* Maquettes principales.

## Phase 2 : Développement MVP

Durée estimée : 6 à 10 semaines

Livrables :

* Authentification.
* Patients.
* Consultations.
* Ordonnances.
* Examens.
* Laboratoire.
* Facturation.
* PDF.
* Partage.
* Tableau de bord.

## Phase 3 : Tests et corrections

Durée estimée : 2 à 3 semaines

Livrables :

* Tests utilisateurs.
* Corrections.
* Optimisation mobile/tablette.
* Tests sécurité.
* Tests PDF.
* Tests sauvegarde.

## Phase 4 : Déploiement

Durée estimée : 1 semaine

Livrables :

* Mise en production.
* Formation du personnel.
* Configuration du centre.
* Import initial des prestations.
* Création des comptes.
* Assistance au démarrage.

## Phase 5 : Amélioration continue

Durée : permanente

Livrables :

* Nouvelles fonctionnalités.
* Rapports avancés.
* Portail patient.
* Stock pharmacie.
* Mobile Money.
* Application mobile.

---

# 28. Qualité attendue

L’application doit être :

* Premium.
* Rapide.
* Simple.
* Sécurisée.
* Élégante.
* Stable.
* Évolutive.
* Adaptée au terrain.
* Facile à maintenir.
* Digne d’un centre de santé moderne.

Le niveau attendu ne doit pas être celui d’un simple logiciel local bricolé, mais celui d’un véritable produit de santé numérique, capable de devenir demain une solution commercialisable pour d’autres centres de santé.

---

# 29. Phrase directrice du projet

Cette application doit être conçue comme un hommage au sérieux, au courage et au travail de la responsable du Cabinet de Soins Manda Nsappe.

Elle doit lui permettre de gérer son centre avec plus de confort, plus de contrôle, plus de professionnalisme et plus de fierté.

L’objectif n’est pas seulement de digitaliser un centre de santé.

L’objectif est de créer une solution belle, utile, sécurisée et humaine, à la hauteur de celle qui porte ce centre au quotidien.

---

# 30. Décision finale recommandée

Nom du produit : **MandaCare**
Slogan : **Soigner mieux, gérer simplement.**
Positionnement : **Application premium de gestion digitale pour centres de santé africains.**
Priorité MVP : **patients, consultations, examens, ordonnances, laboratoire, caisse, documents PDF, WhatsApp et tableau de bord.**
Ambition long terme : **devenir une solution de référence pour la digitalisation des petits centres de santé au Cameroun et en Afrique francophone.**
