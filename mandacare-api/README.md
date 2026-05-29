# MandaCare API

Backend Spring Boot du MVP mobile/tablette MandaCare.

## Stack

- Java 21
- Spring Boot 3.4.1
- Maven
- PostgreSQL
- Flyway
- Spring Security
- OpenAPI

## Commandes

```powershell
mvn -DskipTests compile
mvn test
mvn spring-boot:run
```

## Règles clean code

- Aucun fichier ne doit dépasser 500 lignes.
- Les contrôleurs ne contiennent pas de logique métier.
- Les services portent les transactions et règles métier.
- Les DTO sont séparés des entités.
- Toute action sensible doit passer par l'audit.
- Les logs ne doivent jamais exposer de données médicales sensibles.

