# Matrice Rôles et Permissions - MandaCare

## Principes

Les permissions suivent le besoin minimal : chaque rôle accède uniquement aux informations nécessaires à son travail. Les données médicales complètes sont réservées aux profils soignants autorisés.

Légende :

- `L` : lire
- `C` : créer
- `M` : modifier
- `V` : valider
- `A` : annuler
- `E` : envoyer/exporter
- `Admin` : administrer
- `-` : interdit

## Rôles MVP

| Module / Action | Admin | Accueil/Caisse | Médecin | Infirmier | Laboratoire |
|---|---:|---:|---:|---:|---:|
| Connexion | L | L | L | L | L |
| Utilisateurs | Admin | - | - | - | - |
| Rôles et permissions | Admin | - | - | - | - |
| Paramètres du centre | Admin | L | L | L | L |
| Catalogue prestations | C/M | L | L | L | L |
| Patient - identité | L/C/M | L/C/M | L/C/M | L/C/M | L |
| Patient - données médicales | L | - | L/C/M | L/C/M | L partiel |
| Patient - historique complet | L | L partiel | L | L partiel | L partiel |
| File d'attente | L/C/M/A | L/C/M/A | L/M | L/M | L/M |
| Constantes | L | L | L | L/C/M | L |
| Consultation | L | - | L/C/M/V | L partiel | - |
| Notes confidentielles | L | - | L/C/M | - | - |
| Prescription examens | L | L | L/C/M/V | L | L |
| Ordonnance | L/E | - | L/C/M/V/E | L | - |
| Demande d'examen | L/E | L | L/C/M/V/E | L | L/M |
| Résultat laboratoire | L/E | - | L | - | L/C/M/V/E |
| Facture | L | L/C/M/A/E | L | L | L |
| Paiement | L | L/C/A/E | - | - | - |
| Reçu | L/E | L/C/E | - | - | - |
| Documents patient | L/E | L partiel/E | L/E | L partiel | L partiel/E |
| Envoi WhatsApp/email | L/E | E documents financiers | E documents médicaux | E selon droit | E résultats |
| Tableau de bord | L | L partiel | L partiel | - | L partiel |
| Rapports journaliers | L/E | L/E caisse | - | - | L labo |
| Journal d'audit | L | - | - | - | - |

## Restrictions sensibles

- La caisse ne voit pas les détails de consultation, diagnostics, notes confidentielles ou résultats complets non nécessaires.
- Le laboratoire voit les examens à traiter, l'identité nécessaire du patient et les informations utiles au résultat, mais pas toute l'histoire médicale.
- L'infirmier peut saisir les constantes et voir les informations utiles aux soins, mais ne valide pas les consultations médicales.
- Le médecin valide les consultations, ordonnances et prescriptions d'examens.
- L'administrateur peut consulter et administrer, mais ses accès sensibles doivent rester journalisés.

## Actions toujours journalisées

- Connexion et échec de connexion.
- Création ou modification patient.
- Ouverture, modification ou annulation de visite.
- Validation ou correction de consultation.
- Génération, envoi ou export de PDF.
- Validation de résultat laboratoire.
- Encaissement, remise, annulation de facture ou paiement.
- Modification de rôle, permission ou paramètre du centre.

## Permissions à confirmer avant développement

- Qui peut accorder une remise ?
- Qui peut annuler une facture déjà payée ?
- Qui valide officiellement un résultat laboratoire ?
- Qui peut corriger une consultation validée ?
- Qui peut télécharger un dossier patient complet ?

