# MandaCare Mobile

Application Flutter mobile/tablette du MVP MandaCare.

## Commandes

```powershell
flutter pub get
flutter analyze
flutter run
```

## Règles de conception

- Aucun fichier métier ou UI ne doit dépasser 500 lignes.
- Les écrans restent dans `features/<module>/presentation/screens`.
- Les composants réutilisables restent dans `widgets`.
- Le thème premium est centralisé dans `lib/app/theme`.
- Les règles métier critiques restent côté backend.
- L'interface cible mobile/tablette uniquement.

