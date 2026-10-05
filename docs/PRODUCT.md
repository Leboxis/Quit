# Quit · Spécification V1

Quit aide à observer ses habitudes, traverser une envie et apprendre d'un écart. L'objectif est choisi par la personne : arrêter ou réduire la pornographie. L'app ne diagnostique pas un trouble, ne moralise pas la sexualité et ne promet pas une guérison.

## Expérience

- Aujourd'hui : intention personnelle, check-in de dix secondes, une action utile.
- Parcours : 42 exercices courts répartis en six semaines, disponibles à son rythme.
- Comprendre : mesures descriptives sur les données réellement enregistrées, aucun score prédictif.
- Aide : plans Si → Alors, outils, contact choisi, ressources et sources.
- SOS permanent : intensité initiale → changer de contexte → observer pendant 90 secondes → choisir une alternative → réévaluer → noter le résultat. L'exercice peut être écourté ou prolongé.
- Écart : émotion, contexte, déclencheur, point d'interruption et plan concret. Aucun historique n'est remis à zéro.

## Design

SF Pro dynamique, marges 20–24 pt, cartes de 24 pt, contrôles de 44 pt minimum. Fond ivoire, accent vert profond, ambre discret. Mode sombre et Réduire les animations/transparences. SwiftUI TabView et NavigationStack conservent le comportement natif des versions d'iOS ; Liquid Glass est réservé aux commandes et à la navigation. iOS 18 minimum, look iOS 27 sur iOS 27. Pas de feed, de classement, d'IA conversationnelle ni de données fictives dans l'expérience normale.

## Données et compatibilité

Données Codable stockées atomiquement dans Application Support, protection complète iOS, exclues des sauvegardes système. Pas de serveur, publicité, analytics ou URL de navigation collectée. Verrouillage biométrique optionnel et cache de confidentialité quand l'app devient inactive. Export/import JSON volontaire et suppression avec confirmation. Les erreurs de lecture/écriture restent visibles : un fichier illisible n'est jamais remplacé silencieusement.

Une seule app sans extensions ni entitlements restreints : compatible avec la redistribution non signée. Screen Time automatique est exclu de cette build : Family Controls exige des droits de signature adaptés et LiveContainer ne charge pas les extensions. Les plans d'environnement sont manuels et l'interface le dit. Notifications locales facultatives : l'autorisation peut être indisponible dans LiveContainer.

## Livraison

Chaque push sur main déclenche tests, build pour appareil arm64, emballage Payload/Quit.app dans Quit.ipa, vérification de l'absence de signature/provisioning, puis GitHub Release. Versions croissantes 0.1.<run_number>, build <run_number>. Relancer un même workflow est idempotent. Le JSON source est publié avec le même IPA, puis copié dans une branche catalog ; les commits catalog ne relancent pas le build. URL pérenne : https://raw.githubusercontent.com/Leboxis/Quit/catalog/source.json. Publication sérialisée ; seul le push le plus récent met à jour le catalogue.

## Validation

Tests de calendrier (jours inconnus, jours multiples, frontières et fuseaux), métriques, validation/import, persistance atomique, SOS et progression. Tests des scripts contre de vrais ZIP/Info.plist, catalogue/version/poids cohérents, rejet des signatures et des extensions. Compilation et tests iOS sur GitHub Actions macOS. Les screenshots Figma illustrent un état de démonstration explicitement nommé.
