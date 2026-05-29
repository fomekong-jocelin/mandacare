# Modèle de Données MVP - MandaCare

## Objectif

Ce modèle décrit les entités nécessaires au MVP mobile/tablette. Il doit servir de base à la base de données, aux API et aux écrans.

## Entités d'administration

### Centre

Champs principaux :

- `id`
- `nom`
- `adresse`
- `ville`
- `telephone`
- `email`
- `logoUrl`
- `slogan`
- `responsableNom`
- `cachetUrl`
- `createdAt`, `updatedAt`

### Utilisateur

Champs principaux :

- `id`
- `nom`
- `prenom`
- `telephone`
- `email`
- `identifiant`
- `motDePasseHash`
- `roleId`
- `statut` : actif, inactif
- `lastLoginAt`
- `createdAt`, `updatedAt`

### Role

Champs principaux :

- `id`
- `code` : ADMIN, ACCUEIL_CAISSE, MEDECIN, INFIRMIER, LABO
- `libelle`
- `description`

### Permission

Champs principaux :

- `id`
- `roleId`
- `module`
- `action` : lire, créer, modifier, valider, annuler, exporter, envoyer, administrer

## Entités patient et parcours

### Patient

Champs principaux :

- `id`
- `numeroPatient`
- `nom`
- `prenom`
- `sexe`
- `dateNaissance`
- `ageDeclare`
- `telephone`
- `telephoneWhatsapp`
- `quartier`
- `ville`
- `profession`
- `personneContact`
- `telephoneContact`
- `groupeSanguin`
- `allergies`
- `antecedentsMedicaux`
- `antecedentsChirurgicaux`
- `antecedentsFamiliaux`
- `consentementNumerique`
- `createdAt`, `updatedAt`

### Visite

Champs principaux :

- `id`
- `patientId`
- `motif`
- `serviceCible` : consultation, laboratoire, soins, caisse
- `statut` : attente, consultation, laboratoire, caisse, termine, annule, urgence
- `heureArrivee`
- `heureFin`
- `createdBy`
- `createdAt`, `updatedAt`

### Constantes

Champs principaux :

- `id`
- `patientId`
- `visiteId`
- `temperature`
- `tensionSystolique`
- `tensionDiastolique`
- `pouls`
- `frequenceRespiratoire`
- `saturationOxygene`
- `poids`
- `taille`
- `imc`
- `glycemie`
- `createdBy`
- `createdAt`

### Consultation

Champs principaux :

- `id`
- `patientId`
- `visiteId`
- `medecinId`
- `motif`
- `symptomes`
- `histoireMaladie`
- `examenClinique`
- `diagnosticProvisoire`
- `diagnosticFinal`
- `conseils`
- `notesConfidentielles`
- `statut` : brouillon, valide, corrige
- `validatedAt`
- `createdAt`, `updatedAt`

## Entités prescription et laboratoire

### Ordonnance

Champs principaux :

- `id`
- `patientId`
- `consultationId`
- `numeroOrdonnance`
- `prescripteurId`
- `statut` : brouillon, valide, envoye, imprime
- `pdfUrl`
- `qrCode`
- `createdAt`, `validatedAt`

### LigneOrdonnance

Champs principaux :

- `id`
- `ordonnanceId`
- `medicament`
- `forme`
- `dosage`
- `frequence`
- `duree`
- `quantite`
- `instructions`

### Examen

Champs principaux :

- `id`
- `code`
- `nom`
- `categorie`
- `prix`
- `actif`

### DemandeExamen

Champs principaux :

- `id`
- `patientId`
- `consultationId`
- `numeroDemande`
- `statut` : prescrit, attente_paiement, paye, preleve, resultat_en_cours, valide, envoye
- `urgence` : normal, urgent
- `createdBy`
- `createdAt`

### LigneDemandeExamen

Champs principaux :

- `id`
- `demandeExamenId`
- `examenId`
- `prix`
- `commentaire`

### ResultatExamen

Champs principaux :

- `id`
- `demandeExamenId`
- `numeroResultat`
- `statut` : brouillon, attente_validation, valide
- `conclusion`
- `validatedBy`
- `validatedAt`
- `pdfUrl`
- `createdAt`, `updatedAt`

### LigneResultatExamen

Champs principaux :

- `id`
- `resultatExamenId`
- `parametre`
- `valeur`
- `unite`
- `valeurReference`
- `commentaire`

## Entités caisse et documents

### Prestation

Champs principaux :

- `id`
- `code`
- `nom`
- `categorie`
- `prix`
- `actif`

### Facture

Champs principaux :

- `id`
- `patientId`
- `visiteId`
- `numeroFacture`
- `montantTotal`
- `remise`
- `montantNet`
- `montantPaye`
- `resteAPayer`
- `statut` : brouillon, partiel, paye, annule
- `createdBy`
- `createdAt`

### LigneFacture

Champs principaux :

- `id`
- `factureId`
- `prestationId`
- `designation`
- `quantite`
- `prixUnitaire`
- `montant`

### Paiement

Champs principaux :

- `id`
- `factureId`
- `montant`
- `mode` : especes, mobile_money_manuel
- `reference`
- `statut` : valide, annule
- `createdBy`
- `createdAt`

### Recu

Champs principaux :

- `id`
- `paiementId`
- `numeroRecu`
- `pdfUrl`
- `qrCode`
- `createdAt`

### Document

Champs principaux :

- `id`
- `patientId`
- `type` : ordonnance, demande_examen, resultat_labo, facture, recu, fiche_patient, rapport
- `sourceId`
- `titre`
- `pdfUrl`
- `statut` : genere, envoye, imprime, archive
- `createdBy`
- `createdAt`

### MessageEnvoye

Champs principaux :

- `id`
- `patientId`
- `documentId`
- `canal` : whatsapp, email, telechargement
- `destinataire`
- `consentementVerifie`
- `statut` : prepare, envoye, erreur
- `sentBy`
- `sentAt`

### AuditLog

Champs principaux :

- `id`
- `userId`
- `action`
- `module`
- `entityType`
- `entityId`
- `oldValue`
- `newValue`
- `motif`
- `createdAt`

## Relations clés

- Un patient possède plusieurs visites.
- Une visite peut avoir des constantes, une consultation, une facture et des documents.
- Une consultation peut générer une ordonnance et une ou plusieurs demandes d'examens.
- Une demande d'examen possède plusieurs lignes d'examens et peut générer un résultat.
- Une facture possède plusieurs lignes et plusieurs paiements.
- Un paiement génère un reçu.
- Tout PDF généré est référencé dans Document.
- Toute action sensible génère une entrée AuditLog.

