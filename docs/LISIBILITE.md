# Lisibilité et palette — 6 octobre 2026

L'objectif est de rendre les actions et les informations plus faciles à repérer, de réduire le défilement inutile et d'apporter une variété de couleurs sobre. L'audit porte sur les vues SwiftUI : aucun simulateur iOS n'est disponible sur cet hôte Windows. Les gains d'espace décrits sont des changements de disposition, pas des mesures prises sur appareil.

| Écran | Observation dans le code | Modification |
| --- | --- | --- |
| Navigation des quatre onglets | Grand titre et bande SOS permanente sous le contenu | Titres en ligne ; bouton SOS dans la barre supérieure de chaque onglet ; barre d'onglets native conservée |
| Aujourd'hui | Date isolée, accueil en panneau dégradé, cartes de même importance | Accueil simple avec intention dépliable ; check-in sur fond accentué ; geste du jour distingué par un titre ocre |
| Parcours | Six cartes avec descriptions répétées, grande carte de progression | Liste de semaines dans une carte ; progression compacte ; accès direct au premier exercice inexploré ; descriptions conservées dans les semaines |
| Comprendre | Compteur de 52 points, analyses empilées, résumé vide affiché malgré l'absence de saisies | Trois métriques adaptées à Dynamic Type ; état vide sans statistiques inutiles ; émotions/moments et stratégies dépliables ; accès au journal toujours disponible |
| Aide | Grande carte SOS et quatre cartes de liens semblables | Accès SOS compact ; deux groupes de liens : préparer/échanger et aller plus loin ; icônes colorées selon l'usage |
| Exercices | Illustration de 90 points entre titre et texte | Texte et action disponibles plus tôt ; illustration retirée |
| Journal | Titres d'entrées semblables | Symboles et couleurs distincts pour check-in, envie et épisode ; filtres, pagination et détails conservés |
| Plans | Deux intertitres espacés et suppression affichée en permanence | Condition et action rapprochées ; suppression dans un menu accessible |
| SOS | Titres très grands, sauts de ligne imposés, espacements importants | Titres compacts, espacement réduit et carte d'observation bleue ; cadran fonctionnel et commandes inférieures conservés |
| Apparence et réglages | Illustration dans l'aperçu et titre qui répète la navigation | Aperçu compact montrant aussi les couleurs de contenu ; icône de confort et confidentialité différenciées |

## Palette

L'accent Sauge, Brume ou Sable reste appliqué aux boutons et aux sélections. Les couleurs complémentaires portent un rôle stable : bleu pour les repères et l'observation, prune pour le soutien, ocre pour préparer une action. Les surfaces générales sont plus neutres, particulièrement en sombre. Les variantes sont définies dans les assets, et le générateur de ressources contient les mêmes valeurs.

Les journées alignées ont une coche et les épisodes un cercle, repris dans la légende. Les courbes avant/après combinent pointillés/trait continu et losanges/points. La grille des moments affiche les nombres de signaux, avec un tiret pour aucune saisie ; aucune absence de saisie n'est transformée en réussite. Ces choix suivent le principe de lisibilité et de contraste décrit dans les [recommandations Apple sur la couleur](https://developer.apple.com/design/human-interface-guidelines/color).

Les cartes passent de 22 à 18 points de marge intérieure, de 16 à 12 points d'espacement entre leurs contenus et de 24 à 20 points de rayon. L'espacement entre blocs passe de 22 à 16 points. Les contrôles conservent une hauteur minimale de 44 points ; les métriques et légendes passent en colonne aux tailles d'accessibilité, les icônes suivent Dynamic Type et la grille des moments peut défiler horizontalement.

## Validation

- `python -m unittest discover -s tests -v` : 21 tests réussis, dont 5 tests de contraste avec leurs combinaisons clair/sombre, accents, fonds et symboles.
- `python scripts/validate_resources.py` : 42 exercices complets, assets valides, déclaration sans tracking.
- `git diff --check` : aucun défaut d'espacement.
- Le scénario UITest existant ouvre et ferme maintenant le SOS depuis chacun des quatre onglets, vérifie sa zone tactile et joint une capture de chaque onglet en Brume sombre. Il n'a pas été exécuté ici.

À vérifier avec Xcode avant de considérer le rendu natif comme validé : compilation SwiftUI, XCTest/UITest, petit et grand iPhone, paysage/iPad, les trois accents en clair/sombre, Dynamic Type maximal, VoiceOver, contraste augmenté et accès aux formulaires avec clavier ouvert. Le bouton SOS en barre supérieure doit être facile à repérer et à atteindre lors d'un usage réel. Aucun changement de données, de stockage ou de calcul des statistiques n'est requis par cette passe.
