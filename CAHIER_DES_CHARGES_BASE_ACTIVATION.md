# Cahier des charges — Base de données des licences

## 1. Objet

Créer une base de données sécurisée pour une application séparée de génération et de gestion des licences de PharmaGuinée.

Le système doit garantir que :

- une suite de caractères choisie au hasard ne puisse jamais activer l’application ;
- seules les clés créées et enregistrées par l’application d’administration soient acceptées ;
- une clé puisse être limitée à une pharmacie et, si souhaité, à une machine ;
- une clé désactivée, expirée, supprimée ou déjà utilisée au-delà de sa limite soit refusée ;
- chaque génération, activation, révocation et vérification soit traçable ;
- aucun secret de génération ne soit enregistré dans l’application cliente.

## 2. Architecture recommandée

Le système comprend trois parties :

1. **Application d’administration** : crée, consulte, suspend et révoque les licences.
2. **Serveur d’activation sécurisé** : reçoit les demandes et décide si une activation est autorisée.
3. **Application PharmaGuinée** : envoie la clé et l’identifiant de la machine, puis conserve uniquement un justificatif d’activation signé.

Pour une utilisation sur plusieurs postes ou depuis plusieurs lieux, PostgreSQL est recommandé. La base ne doit pas être directement accessible depuis l’application PharmaGuinée : toutes les opérations passent par une API HTTPS.

## 3. Utilisateurs et droits

### Administrateur principal

- créer et désactiver les comptes gestionnaires ;
- générer, suspendre, renouveler et révoquer toutes les licences ;
- consulter le journal complet ;
- configurer les limites d’activation.

### Gestionnaire de licences

- enregistrer une pharmacie ou un client ;
- créer une licence selon ses permissions ;
- consulter les licences qu’il a créées ;
- désactiver une licence avec justification.

### Application cliente

- vérifier une clé ;
- activer une machine ;
- vérifier périodiquement le statut de la licence ;
- ne jamais créer, modifier ou supprimer une licence.

## 4. Modèle de données

### Table `administrators`

| Champ | Type | Règle |
|---|---|---|
| `id` | UUID | Clé primaire |
| `full_name` | VARCHAR(150) | Obligatoire |
| `username` | VARCHAR(80) | Unique, obligatoire |
| `password_hash` | TEXT | Hachage Argon2id ou bcrypt, jamais le mot de passe brut |
| `role` | VARCHAR(30) | `SUPER_ADMIN` ou `LICENSE_MANAGER` |
| `is_active` | BOOLEAN | `true` par défaut |
| `created_at` | TIMESTAMP UTC | Obligatoire |
| `last_login_at` | TIMESTAMP UTC | Facultatif |

### Table `customers`

| Champ | Type | Règle |
|---|---|---|
| `id` | UUID | Clé primaire |
| `pharmacy_name` | VARCHAR(200) | Obligatoire |
| `owner_name` | VARCHAR(150) | Obligatoire |
| `phone` | VARCHAR(30) | Indexé |
| `email` | VARCHAR(200) | Facultatif |
| `address` | TEXT | Facultatif |
| `created_at` | TIMESTAMP UTC | Obligatoire |
| `updated_at` | TIMESTAMP UTC | Obligatoire |

### Table `licenses`

| Champ | Type | Règle |
|---|---|---|
| `id` | UUID | Clé primaire |
| `customer_id` | UUID | Référence `customers.id` |
| `key_hash` | CHAR(64) | SHA-256 ou HMAC-SHA-256 de la clé normalisée, unique |
| `key_last_four` | CHAR(4) | Uniquement pour identifier visuellement la clé |
| `edition` | VARCHAR(50) | Exemple : `STANDARD` ou `PRO` |
| `status` | VARCHAR(20) | `CREATED`, `ACTIVE`, `SUSPENDED`, `REVOKED` ou `EXPIRED` |
| `max_devices` | INTEGER | Minimum 1 |
| `issued_at` | TIMESTAMP UTC | Date de création |
| `starts_at` | TIMESTAMP UTC | Début de validité |
| `expires_at` | TIMESTAMP UTC | Facultatif pour une licence permanente |
| `activated_at` | TIMESTAMP UTC | Première activation, facultatif |
| `created_by` | UUID | Référence `administrators.id` |
| `revoked_at` | TIMESTAMP UTC | Facultatif |
| `revocation_reason` | TEXT | Obligatoire en cas de révocation |

La clé complète ne doit pas être conservée en clair. Elle est affichée une seule fois lors de sa création. La base conserve uniquement son empreinte cryptographique et ses quatre derniers caractères.

### Table `devices`

| Champ | Type | Règle |
|---|---|---|
| `id` | UUID | Clé primaire |
| `device_fingerprint_hash` | CHAR(64) | Empreinte hachée de la machine |
| `device_name` | VARCHAR(150) | Nom lisible, facultatif |
| `os_version` | VARCHAR(100) | Facultatif |
| `first_seen_at` | TIMESTAMP UTC | Obligatoire |
| `last_seen_at` | TIMESTAMP UTC | Obligatoire |

L’identifiant matériel brut ne doit pas être stocké. Il faut enregistrer uniquement une empreinte hachée stable, construite sans collecter de donnée personnelle inutile.

### Table `license_activations`

| Champ | Type | Règle |
|---|---|---|
| `id` | UUID | Clé primaire |
| `license_id` | UUID | Référence `licenses.id` |
| `device_id` | UUID | Référence `devices.id` |
| `status` | VARCHAR(20) | `ACTIVE`, `DEACTIVATED` ou `BLOCKED` |
| `activated_at` | TIMESTAMP UTC | Obligatoire |
| `last_check_at` | TIMESTAMP UTC | Dernière vérification réussie |
| `deactivated_at` | TIMESTAMP UTC | Facultatif |
| `activation_token_id` | UUID | Identifiant du justificatif signé |

Une contrainte unique doit empêcher plusieurs activations actives pour le même couple licence-machine.

### Table `activation_attempts`

| Champ | Type | Règle |
|---|---|---|
| `id` | UUID | Clé primaire |
| `key_hash` | CHAR(64) | Empreinte de la clé présentée |
| `device_fingerprint_hash` | CHAR(64) | Empreinte de la machine |
| `result` | VARCHAR(40) | Motif normalisé du résultat |
| `ip_address` | INET | Facultatif, durée de conservation limitée |
| `attempted_at` | TIMESTAMP UTC | Obligatoire |

Exemples de résultats : `SUCCESS`, `UNKNOWN_KEY`, `EXPIRED`, `REVOKED`, `SUSPENDED`, `DEVICE_LIMIT_REACHED` et `RATE_LIMITED`.

### Table `audit_logs`

| Champ | Type | Règle |
|---|---|---|
| `id` | UUID | Clé primaire |
| `administrator_id` | UUID | Facultatif pour une action automatique |
| `action` | VARCHAR(80) | Obligatoire |
| `entity_type` | VARCHAR(50) | Type d’objet concerné |
| `entity_id` | UUID | Identifiant concerné |
| `details` | JSONB | Détails sans secret ni clé complète |
| `created_at` | TIMESTAMP UTC | Obligatoire |

Le journal d’audit est en ajout uniquement. Un gestionnaire ordinaire ne peut ni le modifier ni le supprimer.

## 5. Règles d’activation

Une activation est acceptée uniquement si toutes les conditions suivantes sont vraies :

1. le format de la clé est valide ;
2. l’empreinte de la clé existe dans `licenses` ;
3. la licence est dans l’état `CREATED` ou `ACTIVE` ;
4. la date courante est comprise dans sa période de validité ;
5. le nombre maximal de machines n’est pas dépassé ;
6. la machine n’est pas bloquée ;
7. la demande n’est pas considérée comme abusive ;
8. le serveur signe la réponse avec une clé privée inaccessible aux clients.

Une validation basée seulement sur le format ou sur une somme de contrôle locale est interdite. Elle permettrait de fabriquer des clés sans autorisation.

## 6. API minimale

- `POST /admin/licenses` : créer une licence.
- `GET /admin/licenses` : rechercher et lister les licences.
- `POST /admin/licenses/{id}/suspend` : suspendre.
- `POST /admin/licenses/{id}/revoke` : révoquer définitivement.
- `POST /admin/licenses/{id}/renew` : renouveler.
- `POST /v1/activations` : activer une machine.
- `POST /v1/activations/check` : vérifier une activation existante.
- `POST /v1/activations/deactivate` : libérer une machine autorisée.

Toutes les réponses d’activation doivent être signées. L’application cliente embarque uniquement la clé publique nécessaire à la vérification de la signature.

## 7. Fonctionnement temporairement hors connexion

Après une activation en ligne réussie, le serveur remet un justificatif signé contenant au minimum :

- l’identifiant de licence ;
- l’empreinte de la machine ;
- l’édition autorisée ;
- la date d’émission ;
- la date limite de prochaine vérification ;
- un identifiant unique anti-rejeu.

Une période hors connexion configurable, par exemple 7 à 30 jours, peut être accordée. À son expiration, une nouvelle vérification auprès du serveur est obligatoire. Une simple valeur booléenne locale ne doit jamais suffire à conserver l’activation.

## 8. Sécurité

- HTTPS obligatoire pour toutes les communications.
- Secrets et clé privée conservés dans un coffre de secrets, jamais dans le code source.
- Authentification multifacteur recommandée pour les administrateurs.
- Limitation du nombre de tentatives par adresse, clé et machine.
- Sauvegardes chiffrées et testées régulièrement.
- Chiffrement des disques et restriction des accès à la base.
- Requêtes paramétrées et validation stricte de toutes les entrées.
- Horodatage en UTC.
- Rotation des secrets avec conservation contrôlée des anciennes clés publiques.
- Aucune clé complète, mot de passe brut ou information matérielle brute dans les journaux.

## 9. Sauvegarde et conservation

- sauvegarde quotidienne automatique ;
- conservation minimale de 30 sauvegardes journalières et 12 sauvegardes mensuelles ;
- test de restauration au moins une fois par trimestre ;
- objectifs recommandés : perte maximale de 24 heures de données et restauration en moins de 4 heures ;
- conservation des journaux d’audit selon la politique de l’entreprise ;
- suppression ou anonymisation des données personnelles devenues inutiles.

## 10. Critères de recette

Le système est accepté lorsque les tests suivants réussissent :

- 1 000 clés aléatoires correctement formatées sont toutes refusées ;
- une clé générée mais absente de la base est refusée ;
- une clé valide active la première machine autorisée ;
- une activation dépassant `max_devices` est refusée ;
- une clé expirée, suspendue ou révoquée est refusée immédiatement en ligne ;
- une même requête répétée ne crée pas plusieurs activations ;
- aucune clé complète n’apparaît dans la base, les journaux ou les sauvegardes ;
- une restauration de sauvegarde récupère les clients, licences, activations et audits ;
- la signature d’un justificatif modifié est rejetée par PharmaGuinée ;
- la perte ou la modification du fichier local d’activation ne permet pas de débloquer l’application.

## 11. Livrables attendus

- schéma relationnel et scripts de migration versionnés ;
- serveur API documenté ;
- application d’administration ;
- gestion sécurisée des clés de signature ;
- tests automatiques des règles d’activation ;
- procédure de sauvegarde et de restauration ;
- guide de déploiement et manuel administrateur ;
- procédure de révocation d’urgence et de rotation des secrets.

