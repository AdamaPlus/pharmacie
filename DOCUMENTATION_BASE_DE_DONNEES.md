# Documentation de la base de données PharmaGuinée

Dernière mise à jour : 29 août 2026

## 1. Présentation

PharmaGuinée utilise une base locale **SQLite** pour conserver les données de gestion de la pharmacie. L’accès est centralisé dans `lib/services/database_service.dart` et l’état fonctionnel de l’application est géré par `lib/providers/app_state_provider.dart`.

Sur Windows, SQLite est utilisé avec `sqflite_common_ffi`. Les données restent disponibles après la fermeture ou la mise à jour de l’application.

## 2. Emplacement du fichier

Le fichier porte le nom :

```text
pharma_guinee.db
```

Emplacements principaux :

- Windows : `%APPDATA%\PharmaGuinee\pharma_guinee.db` ;
- Linux : `~/Documents/Pharma Guinée/pharma_guinee.db` ;
- macOS : `~/Documents/Pharma Guinée/pharma_guinee.db` ;
- emplacement de secours : dossier de documents fourni par le système.

Sous Windows, l’application crée automatiquement le premier dossier utilisable dans cet ordre : `%APPDATA%`, `%LOCALAPPDATA%`, `USERPROFILE\AppData\Roaming`, puis `USERPROFILE\Documents`. Ainsi, l’absence initiale du dossier ou de la variable `%APPDATA%` ne bloque pas l’installation ni l’ouverture de la base. Si aucun profil utilisateur n’est fourni par Windows, un dossier `PharmaGuinee` est créé dans le répertoire temporaire du système en dernier recours.

Lors d’une mise à jour Windows, une ancienne base située dans `Documents\Pharma Guinée` ou `Documents\pharmaguinee` est copiée automatiquement vers le nouveau dossier de données si aucune base plus récente n’y existe.

## 3. Organisation générale

La base contient une table de paramètres, onze tables métier et une table de journalisation.

### Table `pharmacy_settings`

| Colonne | Type | Rôle |
|---|---|---|
| `key` | TEXT, clé primaire | Nom unique du paramètre |
| `value` | TEXT, obligatoire | Valeur sérialisée |

Paramètres enregistrés :

- `pharmacyName` ;
- `pharmacyQuartier` ;
- `pharmacyPassword` ;
- `pharmacyPinCode` ;
- `pharmacyLogoBase64` ;
- `pharmacyContact1` et `pharmacyContact2` ;
- `hasSeenOnboarding` ;
- `firstLaunchDate` ;
- `isLicensed` ;
- `workingYear` ;
- `activeTab` ;
- `debtReminderDismissedDate` ;
- `currentUsername` et `currentUserRole`.

### Tables métier

Les tables métier utilisent une structure commune :

| Colonne | Type | Rôle |
|---|---|---|
| `id` | TEXT, clé primaire | Identifiant unique de l’enregistrement |
| `data` | TEXT, obligatoire | Objet métier sérialisé en JSON |

| Table | Contenu |
|---|---|
| `products` | Produits, prix, catégorie, seuil d’alerte et quantité totale |
| `lots` | Lots, quantités et dates d’expiration |
| `stock_movements` | Entrées, sorties et ajustements de stock |
| `sales` | Ventes et lignes de vente |
| `prescriptions` | Ordonnances |
| `patients` | Patients et fidélité |
| `employees` | Employés et plannings |
| `suppliers` | Fournisseurs et commandes |
| `users` | Comptes utilisateurs et permissions |
| `loans` | Dettes de médicaments |
| `expenses` | Dépenses de la pharmacie |

Pour `users`, la valeur utilisée comme identifiant SQLite est le nom d’utilisateur.

### Table `audit_logs`

| Colonne | Type | Rôle |
|---|---|---|
| `id` | TEXT, clé primaire | Identifiant du journal |
| `timestamp` | TEXT, obligatoire | Date ISO 8601 de l’action |
| `data` | TEXT, obligatoire | Détails sérialisés en JSON |

Le journal conserve au maximum les 2 000 entrées les plus récentes lors d’une sauvegarde.

## 4. Initialisation et compatibilité

Au démarrage, le service effectue les opérations suivantes :

1. activation du moteur SQLite FFI sur Windows, Linux et macOS ;
2. création du dossier de données si nécessaire ;
3. ouverture de `pharma_guinee.db` ;
4. création des tables absentes ;
5. migration éventuelle de l’ancienne base JSON ;
6. chargement des paramètres et collections en mémoire.

Le schéma est actuellement en version SQLite `1`. La méthode de vérification du schéma recrée toute table manquante sans effacer les données existantes.

## 5. Migration de l’ancienne base JSON

Si un fichier `pharmaguinee_db.json` est présent et que SQLite ne contient encore aucun paramètre, ses données sont importées. Après une migration réussie, le fichier est renommé :

```text
pharmaguinee_db.json.migrated.bak
```

Si SQLite est déjà initialisée, le JSON est uniquement archivé afin d’éviter une deuxième importation.

## 6. Écriture et intégrité des données

Les appels de sauvegarde sont placés dans une file afin d’empêcher deux écritures SQLite simultanées.

Chaque sauvegarde complète est exécutée dans un **batch atomique** :

1. mise à jour des paramètres ;
2. synchronisation complète des tables métier avec les listes en mémoire ;
3. remplacement du journal d’audit par les 2 000 entrées les plus récentes ;
4. validation unique du batch.

Cette synchronisation garantit qu’un produit, une vente, un utilisateur, une dette ou un autre élément supprimé ne réapparaît pas après le redémarrage de l’application.

Les identifiants étant des clés primaires, une insertion portant un identifiant existant remplace la version précédente.

## 7. Relations fonctionnelles

SQLite ne déclare pas de clés étrangères physiques, car les objets sont stockés en JSON. Les relations sont contrôlées par l’application :

- un lot référence un produit par `productId` ;
- un mouvement de stock référence un produit ;
- une ligne de vente référence un produit ;
- une vente peut référencer un patient ;
- une dette créée depuis une vente peut référencer cette vente par `saleId` ;
- les commandes sont incluses dans les objets fournisseurs ;
- les plannings sont inclus dans les objets employés.

Les ventes et dettes de médicaments diminuent le stock par lots. Les sorties utilisent en priorité les lots qui expirent le plus tôt.

## 8. Années de travail

Le paramètre `workingYear` conserve l’année sélectionnée par l’utilisateur. Au premier démarrage effectué pendant une année civile plus récente, l’application avance automatiquement cette valeur jusqu’à l’année courante. Elle ne supprime et ne déplace aucune donnée : les ventes, dépenses, dettes et mouvements restent enregistrés avec leur date et sont affichés uniquement pour l’année sélectionnée.

Le catalogue des produits et son stock ne sont pas remis à zéro lors du passage d’année : ils restent disponibles pour poursuivre l’activité. L’utilisateur peut sélectionner une année précédente dans le tableau de bord afin de consulter ses opérations. Une année future choisie manuellement n’est jamais ramenée en arrière par le démarrage automatique.

L’onglet actif est conservé dans `activeTab`, ce qui permet de retrouver l’espace de travail utilisé lors de la dernière session.

## 9. Sauvegarde et restauration

L’application peut exporter une sauvegarde JSON contenant :

- toutes les tables métier ;
- le journal d’audit ;
- les informations de la pharmacie ;
- la licence locale ;
- l’année de travail.

Avant une restauration, le fichier est décodé et ses collections sont validées. Les tables ne sont vidées qu’après cette validation. La restauration remplace ensuite les données SQLite dans un batch puis recharge l’état de l’application.

Le fichier de sauvegarde doit contenir au minimum `products`, `sales`, `users` et `pharmacyName` pour être reconnu comme une sauvegarde PharmaGuinée.

## 10. Recommandations d’exploitation

- effectuer régulièrement une sauvegarde depuis l’application ;
- conserver une copie sur un support différent de l’ordinateur principal ;
- ne jamais modifier directement le fichier SQLite pendant que l’application fonctionne ;
- ne pas supprimer les fichiers SQLite `-wal` ou `-shm` lorsque la base est ouverte ;
- tester périodiquement la restauration d’une sauvegarde ;
- fermer normalement l’application avant de déplacer manuellement la base.

## 11. Vérifications techniques effectuées

- création automatique des tables ;
- chargement et sérialisation des modèles ;
- file d’attente des écritures ;
- synchronisation atomique des ajouts, modifications et suppressions ;
- conservation de l’année et de l’onglet de travail ;
- passage automatique à une nouvelle année sans perte des anciennes opérations ni des produits ;
- création du dossier de données Windows lorsque `%APPDATA%` est absent ;
- migration JSON vers SQLite ;
- export et restauration des sauvegardes ;
- compilation Flutter Release réussie.
