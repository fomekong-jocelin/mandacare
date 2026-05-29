# Templates PDF MVP - MandaCare

## Principes communs

Chaque document PDF doit être professionnel, lisible en A4 et cohérent avec l'identité MandaCare.

Éléments communs :

- logo du centre ;
- nom complet du centre ;
- adresse, téléphone, email ;
- titre du document ;
- numéro unique ;
- date d'édition ;
- identité patient si applicable ;
- signature ou cachet ;
- QR code de vérification ;
- mention de confidentialité ;
- pied de page discret.

Palette :

- vert médical premium `#0E7C66` ;
- bleu santé profond `#0B3D5C` ;
- or doux `#D4A94F` pour accents limités ;
- texte principal `#344054`.

## PDF 1 - Ordonnance

### Objectif

Remettre au patient un document médical officiel contenant les médicaments prescrits.

### Contenu

- En-tête du centre.
- Numéro ordonnance.
- Date.
- Patient : nom, prénom, âge, sexe, numéro patient.
- Prescripteur.
- Liste des médicaments.
- Conseils.
- Signature et cachet.
- QR code.
- Mention de confidentialité.

### Tableau médicaments

Colonnes :

- Médicament
- Forme / dosage
- Fréquence
- Durée
- Quantité
- Instructions

### Règles

- Une ordonnance validée est archivée.
- Le PDF doit être prévisualisé avant envoi.
- Toute correction après validation doit créer une trace d'audit.

## PDF 2 - Demande d'examen

### Objectif

Transmettre au laboratoire les examens prescrits et leur statut de paiement.

### Contenu

- En-tête du centre.
- Numéro de demande.
- Date.
- Patient.
- Prescripteur.
- Liste des examens.
- Urgence : normal ou urgent.
- Statut paiement.
- Observations.
- QR code.

### Tableau examens

Colonnes :

- Examen
- Catégorie
- Prix
- Statut
- Commentaire

### Règles

- Le laboratoire ne doit voir que les informations nécessaires.
- Le statut de paiement doit être clair avant traitement si paiement requis.

## PDF 3 - Résultat de laboratoire

### Objectif

Remettre un compte rendu officiel et lisible au patient ou au prescripteur.

### Contenu

- En-tête du centre.
- Numéro résultat.
- Type d'examen.
- Patient.
- Prescripteur.
- Date de prélèvement.
- Date d'édition.
- Tableau des résultats.
- Conclusion.
- Responsable validation.
- Signature/cachet.
- QR code.
- Mention de confidentialité.

### Tableau résultats

Colonnes :

- Paramètre
- Résultat
- Unité
- Valeurs de référence
- Commentaire

### Règles

- Un résultat validé est verrouillé.
- Le PDF n'est généré en version officielle qu'après validation.
- Toute correction exige une permission spéciale et un motif.

## PDF 4 - Facture

### Objectif

Présenter les actes facturés, le total et le reste à payer.

### Contenu

- En-tête du centre.
- Numéro facture.
- Date.
- Patient.
- Caissier.
- Liste des prestations.
- Sous-total.
- Remise.
- Total net.
- Montant payé.
- Reste à payer.
- Statut.
- QR code.

### Tableau prestations

Colonnes :

- Désignation
- Quantité
- Prix unitaire
- Montant

### Règles

- Toute remise doit être liée à une permission.
- Toute annulation doit être journalisée.

## PDF 5 - Reçu

### Objectif

Confirmer un paiement reçu par le centre.

### Contenu

- En-tête du centre.
- Numéro reçu.
- Date.
- Patient.
- Facture liée.
- Montant payé.
- Mode de paiement.
- Référence si mobile money manuel.
- Caissier.
- Signature/cachet.
- QR code.

### Règles

- Un reçu est généré uniquement après paiement validé.
- Un paiement annulé doit invalider ou annoter le reçu correspondant.

## PDF 6 - Fiche patient simplifiée

### Objectif

Fournir une synthèse administrative et médicale courte selon les droits.

### Contenu

- Identité patient.
- Contacts.
- Personne à contacter.
- Allergies.
- Antécédents principaux.
- Dernières visites.
- Derniers documents.
- Mention de confidentialité.

### Règles

- Export réservé aux rôles autorisés.
- Les notes confidentielles ne sont jamais incluses.

## PDF 7 - Rapport journalier simple

### Objectif

Donner à l'administration une synthèse de l'activité quotidienne.

### Contenu

- Date.
- Nombre de patients.
- Consultations.
- Examens demandés.
- Résultats validés.
- Factures.
- Paiements.
- Recettes du jour.
- Impayés.
- Annulations.
- Utilisateur ayant généré le rapport.

### Règles

- Rapport réservé à l'administrateur et aux profils explicitement autorisés.
- Les détails médicaux individuels ne sont pas inclus.

## Mentions de confidentialité recommandées

Texte court :

> Document confidentiel émis par le Cabinet de Soins Manda Nsappe. Ne le partagez qu'avec un professionnel de santé ou une personne de confiance.

Texte pour lien sécurisé :

> Ce document contient des informations sensibles. Le lien peut expirer et ne doit pas être transféré sans consentement du patient.

