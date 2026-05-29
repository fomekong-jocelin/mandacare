# Synthèse MandaCare - MVP mobile/tablette

## Verdict

Le dossier est prêt pour passer en cadrage produit détaillé. La vision est claire, les besoins terrain sont bien couverts et les mockups donnent une direction premium crédible.

La décision importante est de rester sur un produit **mobile/tablette uniquement pour le moment**. Cela évite de disperser le design et permet de construire un MVP plus cohérent pour l'usage réel du centre.

## Décision de périmètre

### Inclus en MVP

- Connexion utilisateur.
- Gestion des rôles.
- Tableau de bord mobile/tablette.
- Patients et historique.
- File d'attente.
- Consultation et constantes.
- Prescription d'examens.
- Ordonnance PDF.
- Laboratoire simple.
- Résultat PDF.
- Facturation et reçu PDF.
- Partage WhatsApp manuel ou semi-automatique.
- Paramètres du centre.
- Journal d'audit.

### Exclu pour le moment

- Desktop.
- Portail patient.
- Multi-centres.
- Mobile Money automatique.
- WhatsApp Business API officielle.
- Stock pharmacie.
- Hospitalisation complète.
- Rapports RGFOSA avancés.
- Offline complet.

## Verdict logo

La meilleure base est le logo horizontal MandaCare sur fond blanc, avec l'icône seule comme base d'application mobile. La version fond sombre est utile comme déclinaison secondaire.

À faire avant usage officiel :

- recréer le logo en SVG vectoriel ;
- livrer versions couleur, noir, blanc et monochrome ;
- produire icône app Android, favicon et avatar ;
- vérifier la lisibilité du slogan en petite taille ;
- stabiliser la typographie et les espacements.

## Verdict mockups

Les 9 mockups couvrent correctement les écrans essentiels :

- accueil/dashboard ;
- file d'attente ;
- dossier patient ;
- nouvelle consultation ;
- ordonnance ;
- examens demandés ;
- résultat laboratoire ;
- facturation ;
- partage document.

La direction est bonne : propre, médicale, moderne et rassurante. Les écrans donnent une impression d'application premium, pas de simple formulaire administratif.

À corriger dans la prochaine passe :

- renforcer la lisibilité des petits textes ;
- harmoniser les statuts et couleurs ;
- réduire les zones trop denses sur mobile ;
- prévoir une variante tablette pour chaque écran critique ;
- ajouter des états vides, erreurs, chargement et confirmations ;
- montrer la preview PDF avant envoi ;
- séparer clairement les actions médicales, caisse et administration.

## Priorité UX mobile/tablette

L'application doit fonctionner avec des utilisateurs peu techniques. Les actions fréquentes doivent être visibles sans chercher.

Règles UX :

- une action principale par écran ;
- boutons larges et tactiles ;
- filtres simples ;
- recherche patient accessible partout ;
- statuts visibles par couleur et libellé ;
- formulaires courts, découpés en blocs ;
- confirmation obligatoire pour validation, annulation, envoi et suppression ;
- navigation mobile par barre inférieure ;
- navigation tablette avec plus d'espace mais sans logique desktop.

## Backlog MVP priorisé

### Priorité 1 - Socle

- Authentification.
- Rôles et permissions.
- Paramètres du centre.
- Catalogue des prestations.
- Journal d'audit.

### Priorité 2 - Parcours patient

- Création patient.
- Recherche patient.
- Fiche patient.
- Historique.
- File d'attente.

### Priorité 3 - Médical

- Saisie constantes.
- Consultation.
- Prescription d'examens.
- Ordonnance PDF.
- Validation avec trace.

### Priorité 4 - Laboratoire et caisse

- Demande d'examen.
- Statuts laboratoire.
- Saisie résultat.
- Résultat PDF.
- Facture.
- Paiement.
- Reçu PDF.

### Priorité 5 - Partage et pilotage

- Envoi WhatsApp manuel ou semi-automatique.
- Journal des envois.
- Tableau de bord.
- Rapport journalier simple.

## Risques principaux

1. **MVP trop large** : il faut éviter d'ajouter pharmacie, portail patient ou multi-centres avant stabilisation.
2. **Sécurité sous-estimée** : les données médicales exigent rôles stricts, audit, sauvegardes et consentement.
3. **PDF négligés** : les documents produits sont la vitrine du centre. Ils doivent être beaux et officiels.
4. **Design mobile trop dense** : certains écrans doivent être allégés ou adaptés en tablette.
5. **WhatsApp mal encadré** : chaque envoi doit être consenti, journalisé et vérifié pour éviter les erreurs de destinataire.

## Prochaine étape recommandée

Transformer ce cadrage en dossier de conception :

1. user stories par module ;
2. matrice rôles/permissions ;
3. modèle de données ;
4. wireframes tablette ;
5. templates PDF ;
6. guide de style ;
7. plan de tests MVP.

La bonne trajectoire est de construire un produit mobile/tablette propre, stable et rassurant, puis d'élargir seulement après validation terrain.



