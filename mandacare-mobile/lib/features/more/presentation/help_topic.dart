import 'package:flutter/material.dart';

class HelpTopic {
  const HelpTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.imageAssetPath,
    required this.steps,
    required this.rules,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String imageAssetPath;
  final List<String> steps;
  final List<String> rules;

  static const List<HelpTopic> catalog = [
    HelpTopic(
      id: 'dashboard',
      title: 'Accueil & File d\'attente',
      description: 'Vue globale de l\'activité, KPIs et gestion de la file d\'attente du jour.',
      icon: Icons.dashboard_rounded,
      imageAssetPath: 'assets/help/mockup-dashboard.png',
      steps: [
        'Consultez les KPIs en haut de l\'écran pour voir le nombre de patients par état (attente, consultation, caisse, laboratoire, sortis).',
        'Faites un glissement de doigt vers le bas (Pull-to-refresh) pour actualiser la liste des patients.',
        'Utilisez les raccourcis d\'accès rapide pour enregistrer un nouveau patient ou lancer une consultation.',
        'Cliquez sur la carte d\'un patient de la file d\'attente pour accéder directement à son dossier.'
      ],
      rules: [
        'La file d\'attente liste uniquement les visites du jour en cours.',
        'Un badge couleur associe le statut et le niveau d\'urgence de chaque patient.'
      ],
    ),
    HelpTopic(
      id: 'patient_list',
      title: 'Registre des Patients',
      description: 'Recherche multicritère, filtrage rapide et admission de nouveaux dossiers.',
      icon: Icons.groups_rounded,
      imageAssetPath: 'assets/help/mockup-patient-list.png',
      steps: [
        'Saisissez un nom, numéro de téléphone ou de dossier dans la barre de recherche.',
        'Cochez un filtre (Attente, Urgents, Caisse, Labo) pour isoler les dossiers.',
        'Cliquez sur "+" pour enregistrer un nouveau patient : saisissez son nom complet (prénom + nom obligatoires), âge (0 à 130), sexe, téléphone et motif.',
        'Validez l\'enregistrement pour insérer le patient dans la file d\'attente.'
      ],
      rules: [
        'Le nom complet doit comporter au moins deux mots (un prénom et un nom).',
        'Seuls les champs essentiels sont obligatoires pour accélérer l\'admission en urgence.'
      ],
    ),
    HelpTopic(
      id: 'patient_detail',
      title: 'Dossier Patient & Workflow Stepper',
      description: 'Suivi des étapes cliniques, actions contextuelles et historique des visites.',
      icon: Icons.folder_shared_rounded,
      imageAssetPath: 'assets/help/mockup-patient-detail.png',
      steps: [
        'Suivez l\'état du patient via le stepper horizontal interactif : Visite ➔ Constantes ➔ Consultation ➔ Caisse ➔ Laboratoire.',
        'Exécutez l\'action recommandée en cliquant sur le gros bouton d\'action en haut de la liste.',
        'Consultez le résumé clinique et l\'historique des visites précédentes.',
        'Accédez aux documents générés (ordonnances, reçus) pour les réimprimer ou les partager.'
      ],
      rules: [
        'Le stepper est interactif : cliquer sur une étape lance directement le formulaire associé si les conditions sont remplies.',
        'Les dossiers cliniques validés sont verrouillés en modification sans motif d\'audit.'
      ],
    ),
    HelpTopic(
      id: 'vitals',
      title: 'Constantes & Calcul d\'IMC',
      description: 'Saisie des signes vitaux, plages de validation et calcul automatique de l\'IMC.',
      icon: Icons.monitor_heart_rounded,
      imageAssetPath: 'assets/help/mockup-consultation-form.png',
      steps: [
        'Renseignez la température (°C), pression artérielle (Systolique/Diastolique), pouls, SpO2 (saturation) et fréquence respiratoire.',
        'Saisissez le poids (kg) et la taille (cm) du patient.',
        'Vérifiez l\'IMC calculé automatiquement dans le cadre d\'information vert.',
        'Enregistrez pour orienter le patient vers la salle de consultation.'
      ],
      rules: [
        'L\'IMC est calculé selon la formule légale : Poids (kg) / Taille (m)2.',
        'Toutes les constantes sont validées selon des seuils physiologiques stricts (ex: 30°C à 45°C pour la température).'
      ],
    ),
    HelpTopic(
      id: 'consultation',
      title: 'La Consultation & Prescription',
      description: 'Fiche d\'observation, rédaction de l\'ordonnance et examens de laboratoire.',
      icon: Icons.assignment_rounded,
      imageAssetPath: 'assets/help/mockup-lab-prescription.png',
      steps: [
        'Saisissez les symptômes, l\'examen clinique et le diagnostic retenu.',
        'Cliquez sur "Ajouter un médicament" pour enrichir la prescription (nom, forme, dosage, durée, quantité).',
        'Choisissez l\'orientation : Libérer le patient ou l\'envoyer au laboratoire.',
        'Si laboratoire est choisi, recherchez et cochez les examens demandés dans le catalogue.',
        'Cliquez sur "Valider" pour verrouiller la consultation et transférer le dossier.'
      ],
      rules: [
        'Les champs Symptômes, Examen clinique et Diagnostic sont obligatoires pour valider.',
        'Pour modifier une consultation validée, un motif de correction auditable est requis.'
      ],
    ),
    HelpTopic(
      id: 'prescription',
      title: 'Ordonnance Médicale (PDF)',
      description: 'Aperçu de la prescription, impression et partage sécurisé.',
      icon: Icons.description_rounded,
      imageAssetPath: 'assets/help/mockup-prescription-pdf.png',
      steps: [
        'À la validation de la consultation, prévisualisez l\'ordonnance générée automatiquement sous forme de PDF.',
        'Vérifiez la présence de l\'en-tête officiel de la clinique, du code-barres et des signatures.',
        'Cliquez sur "Prévisualiser" pour l\'ouvrir dans le visionneur interactif.',
        'Imprimez ou téléchargez le document sur votre terminal.'
      ],
      rules: [
        'L\'ordonnance intègre les informations du médecin connecté et le logo officiel du centre.',
        'Le document est verrouillé et ne peut être modifié après validation clinique.'
      ],
    ),
    HelpTopic(
      id: 'cashdesk',
      title: 'Caisse & Règlements (Facturation)',
      description: 'Visualisation de facture, calculateur de paiement et impression de reçus.',
      icon: Icons.payments_rounded,
      imageAssetPath: 'assets/help/mockup-cashdesk-billing.png',
      steps: [
        'Sélectionnez un dossier en attente d\'encaissement.',
        'Vérifiez le récapitulatif des prestations facturées (examens prescrits, actes de soins).',
        'Saisissez le montant encaissé. L\'application calcule instantanément le solde (compte juste, reste à payer, monnaie à rendre).',
        'Sélectionnez le mode de règlement (Espèces, Mobile Money, Carte) et validez.',
        'Imprimez le reçu de caisse PDF ou renvoyez le patient vers le labo ou la sortie.'
      ],
      rules: [
        'Le caissier peut renvoyer le patient en consultation en cliquant sur "Revenir en consultation".',
        'Chaque paiement validé produit un reçu officiel numéroté et audité.'
      ],
    ),
    HelpTopic(
      id: 'laboratory',
      title: 'Résultats de Laboratoire',
      description: 'Saisie des analyses cliniques, date de prélèvement et conclusions.',
      icon: Icons.science_rounded,
      imageAssetPath: 'assets/help/mockup-lab-result-form.png',
      steps: [
        'Ouvrez la fiche de résultat du patient orienté en laboratoire.',
        'Sélectionnez ou vérifiez la date de prélèvement des échantillons.',
        'Saisissez les résultats textuels pour chaque examen requis (ex: NFS, Glycémie).',
        'Cochez "Normal" pour désactiver la saisie manuelle si le résultat est dans les normes.',
        'Validez pour générer le compte-rendu PDF et renvoyer le dossier au médecin.'
      ],
      rules: [
        'Le dossier d\'analyses est identifié par un code unique : LAB-[NuméroPatient]-[Date du jour].',
        'Seuls les examens réglés en caisse apparaissent comme à renseigner.'
      ],
    ),
    HelpTopic(
      id: 'sharing',
      title: 'Partage de Documents',
      description: 'Partage sécurisé des ordonnances, reçus et résultats via WhatsApp.',
      icon: Icons.share_rounded,
      imageAssetPath: 'assets/help/mockup-document-sharing.png',
      steps: [
        'Ouvrez l\'écran de partage à la fin d\'un workflow clinique ou depuis l\'historique.',
        'Vérifiez le numéro de téléphone WhatsApp du patient (pré-rempli).',
        'Consultez le rappel de consentement affiché.',
        'Appuyez sur "Partager via WhatsApp" pour ouvrir le document dans l\'application de messagerie externe.'
      ],
      rules: [
        'Le consentement du patient pour l\'envoi de données médicales par canal tiers doit être recueilli oralement.',
        'Toutes les actions de partage sont journalisées dans le système d\'audit.'
      ],
    ),
  ];
}
