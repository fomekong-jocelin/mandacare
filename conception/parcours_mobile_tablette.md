# Parcours Mobile/Tablette - MandaCare

## Principes d'interface

L'application est pensée d'abord pour smartphone et tablette.

- Mobile : navigation inférieure, écrans courts, une action principale visible.
- Tablette : plus d'espace horizontal, listes et détails côte à côte si utile, sans logique desktop.
- Toutes les actions sensibles demandent confirmation : validation, annulation, envoi, encaissement, correction.
- La recherche patient doit rester accessible depuis les modules principaux.
- Les statuts doivent combiner couleur et libellé, jamais la couleur seule.

## Navigation principale mobile

Onglets recommandés :

1. Accueil
2. Patients
3. Consult.
4. Caisse
5. Plus

Dans `Plus` :

- Laboratoire
- Documents
- Paramètres
- Tableau de bord
- Déconnexion

Sur tablette, les mêmes entrées peuvent devenir un menu latéral compact.

## Parcours 1 - Accueil et file d'attente

### Écran A1 - Accueil du jour

Contenu :

- résumé du jour : patients, consultations, examens, recettes ;
- bouton `Nouveau patient` ;
- bouton `Nouvelle visite` ;
- liste courte des patients en attente ;
- alertes importantes.

Action principale : `Nouvelle visite`.

### Écran A2 - Recherche patient

Contenu :

- champ de recherche par nom, téléphone ou numéro patient ;
- résultats sous forme de cartes ;
- alerte doublon possible ;
- bouton `Créer patient` si aucun résultat.

### Écran A3 - Création patient

Sections :

- identité ;
- contacts ;
- informations médicales rapides ;
- consentement numérique.

Règle : seuls les champs indispensables bloquent l'enregistrement.

### Écran A4 - Ouverture visite

Contenu :

- patient sélectionné ;
- motif de venue ;
- service cible ;
- niveau d'urgence ;
- bouton `Ajouter à la file`.

### Écran A5 - File d'attente

Contenu :

- filtres : tous, urgence, consultation, labo, caisse ;
- cartes patients avec heure d'arrivée, motif, statut ;
- action `Appeler le prochain`.

## Parcours 2 - Consultation

### Écran C1 - Patient en consultation

Contenu :

- identité courte ;
- alertes médicales ;
- dernières constantes ;
- historique récent ;
- boutons `Constantes`, `Nouvelle consultation`, `Ordonnance`, `Examens`.

### Écran C2 - Constantes

Champs :

- température ;
- tension ;
- pouls ;
- fréquence respiratoire ;
- saturation ;
- poids ;
- taille ;
- glycémie si nécessaire.

Règle : l'IMC est calculé automatiquement.

### Écran C3 - Consultation

Sections :

- motif ;
- symptômes ;
- examen clinique ;
- diagnostic provisoire ;
- diagnostic final ;
- conseils ;
- notes confidentielles.

Actions :

- `Enregistrer brouillon` ;
- `Prescrire examens` ;
- `Créer ordonnance` ;
- `Valider consultation`.

### Écran C4 - Correction après validation

Contenu :

- consultation verrouillée ;
- bouton `Demander correction` ou `Corriger` selon permission ;
- champ motif obligatoire ;
- journalisation automatique.

## Parcours 3 - Ordonnance

### Écran O1 - Création ordonnance

Contenu :

- patient ;
- prescripteur ;
- lignes médicaments ;
- conseils généraux.

Chaque ligne contient :

- médicament ;
- forme ;
- dosage ;
- fréquence ;
- durée ;
- quantité ;
- instructions.

### Écran O2 - Aperçu PDF

Contenu :

- preview lisible ;
- boutons `Télécharger`, `Envoyer`, `Imprimer si disponible` ;
- rappel du numéro WhatsApp ;
- consentement affiché.

## Parcours 4 - Laboratoire

### Écran L1 - Examens à traiter

Contenu :

- filtres par statut ;
- recherche patient ;
- badges urgence ;
- indicateur paiement.

### Écran L2 - Détail demande

Contenu :

- patient ;
- examens demandés ;
- statut paiement ;
- informations de prélèvement ;
- action `Marquer prélèvement effectué`.

### Écran L3 - Saisie résultat

Contenu :

- tableau mobile de paramètres ;
- valeur, unité, référence ;
- commentaire ;
- conclusion.

Actions :

- `Enregistrer brouillon` ;
- `Prévisualiser PDF` ;
- `Valider résultat`.

### Écran L4 - Résultat validé

Règles :

- résultat verrouillé ;
- envoi possible ;
- correction seulement avec permission spéciale et motif.

## Parcours 5 - Caisse

### Écran F1 - Actes à payer

Contenu :

- patient ;
- actes prescrits ou ajoutés ;
- total estimé ;
- statut de paiement.

### Écran F2 - Facture

Contenu :

- lignes de prestations ;
- quantité ;
- prix unitaire ;
- remise si autorisée ;
- total ;
- reste à payer.

Actions :

- `Encaisser` ;
- `Générer facture PDF` ;
- `Annuler` selon permission.

### Écran F3 - Paiement

Contenu :

- montant à payer ;
- montant reçu ;
- mode : espèces, mobile money manuel ;
- référence optionnelle.

Action principale : `Valider paiement`.

### Écran F4 - Reçu

Contenu :

- aperçu reçu PDF ;
- boutons `Envoyer`, `Télécharger`, `Imprimer`.

## Parcours 6 - Partage documentaire

### Écran S1 - Choisir document

Documents partageables MVP :

- ordonnance ;
- demande d'examen ;
- résultat laboratoire ;
- facture ;
- reçu ;
- fiche patient simplifiée.

### Écran S2 - Choisir canal

Canaux :

- WhatsApp manuel ou semi-automatique ;
- email ;
- téléchargement PDF ;
- lien sécurisé si disponible.

### Écran S3 - Confirmation d'envoi

Contenu :

- document ;
- patient ;
- numéro ou email ;
- consentement ;
- mention de confidentialité.

Règle : l'envoi ne part pas sans confirmation explicite.

### Écran S4 - Journal d'envoi

Contenu :

- date ;
- utilisateur ;
- canal ;
- destinataire ;
- statut.

## États à prévoir pour tous les écrans

- Chargement.
- Liste vide.
- Erreur réseau.
- Accès refusé.
- Confirmation avant action sensible.
- Succès après enregistrement.
- Données verrouillées après validation.

