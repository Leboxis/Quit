# Quit

Un compagnon iOS privé pour changer son usage de pornographie, construit en **Swift 6 et SwiftUI**. Observer, traverser une envie, apprendre d'un écart et retrouver de la liberté dans ses choix.

## Installer et mettre à jour

- [Télécharger le dernier IPA](https://github.com/Leboxis/Quit/releases/latest/download/Quit.ipa)
- [Releases et sommes SHA-256](https://github.com/Leboxis/Quit/releases)
- **Source à ajouter dans SideStore ou LiveContainer :**

```text
https://raw.githubusercontent.com/Leboxis/Quit/catalog/source.json
```

L'IPA est **non signé**, arm64, pour iOS 18 et versions suivantes. SideStore le signe avec votre méthode habituelle ; LiveContainer le prépare selon son mode de fonctionnement. Quit conserve un identifiant stable (`fr.leboxis.quit`) pour les mises à jour. Faites un export volontaire avant un changement de conteneur.

## V2 · Design et confort

Trois ambiances cohérentes dans toute l'app : **Sauge**, **Brume**, **Sable**. Apparence automatique, claire ou sombre ; aperçu immédiat depuis Réglages → Apparence et confort. Choix des vibrations et des animations, avec priorité au réglage d'accessibilité iOS. Les contrastes des cartes sont renforcés lorsque l'appareil le demande.

Le SOS offre 90 secondes, 3 ou 5 minutes, un cadran discret et une progression lisible. Ses commandes et l'enregistrement du check-in restent accessibles dans une barre inférieure, indépendamment du défilement. L'accueil gagne une carte de bienvenue douce et les choix d'émotion une transition courte.

Les préférences sont conservées localement, exportées avec la sauvegarde et réappliquées au lancement. **Les données et exports V1 restent compatibles**, sans nouvelle inscription ni remise à zéro du parcours.

## Ce que contient l'app

| Espace | Contenu |
| --- | --- |
| Aujourd'hui | Intention personnelle, check-in court, un geste utile |
| SOS permanent | Pause, observation de 90 s, 3 ou 5 min, action, réévaluation |
| Parcours | 42 micro-exercices originaux sur six semaines, à son rythme |
| Comprendre | Jours connus/inconnus, intensités, stratégies, moments sensibles, retour au plan |
| Aide | Plans Si → Alors, contact choisi, ressources professionnelles et sources |
| Confidentialité | Stockage local protégé, cache quand l'app devient inactive, verrouillage facultatif, export/import/suppression |

Un écart ne remet pas les apprentissages à zéro. Aucun jour sans saisie n'est automatiquement compté comme aligné. Pas de compte, serveur, publicité, analytics, classement ou IA conversationnelle. Les données ne sont pas incluses dans les sauvegardes système ; l'export JSON volontaire contient des informations personnelles en clair.

## Design iOS 27

[Figma : écrans éditables et prototype](https://www.figma.com/design/5wrVQf5TcnIVAJmnLN8ePs?node-id=14-232)

TabView, NavigationStack et contrôles SwiftUI natifs ; Liquid Glass pour les commandes sur iOS 26/27, alternative matérielle pour iOS 18 et versions antérieures à iOS 26. SF Pro, Dynamic Type, VoiceOver, mode sombre et Réduire les animations/transparences. Le look système évolue avec iOS ; aucune barre d'onglets n'est redessinée dans l'app. La CI sélectionne Xcode 27 s'il est présent sur le runner, sinon elle déclare son repli Xcode 26 dans le résumé.

Les maquettes Figma utilisent Inter pour la prévisualisation : le connecteur annonce SF Pro mais ses calques restent marqués `hasMissingFont` et ne se rendent pas. L'app utilise la police système SF Pro. L'import de la bibliothèque Apple iOS 27 est également refusé par le connecteur ; les composants Figma sont locaux et éditables.

## Limites utiles

- **Cette build ne bloque pas les apps/sites** : Family Controls exige une signature et des entitlements adaptés ; LiveContainer ne prend pas en charge les extensions iOS. Les protections proposées sont volontaires et manuelles.
- Notifications locales, authentification et composition de SMS dépendent des possibilités de l'installation. Aucune de ces fonctions n'est nécessaire pour le parcours de base.
- Les exercices sont éducatifs, inspirés notamment de l'ACT et des TCC. Cette app et son programme n'ont pas été validés comme traitement. Les associations dans les graphiques ne sont pas des preuves de causalité ou des prédictions de rechute.
- Quit ne pose aucun diagnostic et ne considère pas la masturbation comme un échec. Une souffrance importante ou une perte de contrôle persistante mérite un accompagnement professionnel.

## Construire localement sur Mac

```sh
brew install xcodegen
xcodegen generate
open Quit.xcodeproj
```

Xcode 26 ou 27 requis. `project.yml` est la source du projet Xcode ; le `.xcodeproj` est généré. Aucun package tiers n'est nécessaire à l'exécution. Pour votre propre signature, remplacez les réglages `CODE_SIGNING_*` dans votre configuration locale.

```sh
python3 -m unittest discover -s tests -v
python3 scripts/validate_resources.py
xcodebuild test -project Quit.xcodeproj -scheme Quit -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO
```

## Publication automatique

Chaque **push sur main** exécute validation du catalogue, tests XCTest et parcours UI, compilation pour appareil et contrôle des signatures. La release `v0.2.<run_number>` contient `Quit.ipa`, `source.json` et `SHA256SUMS.txt`. Version du catalogue, identifiant, iOS minimum et poids sont lus dans l'IPA réel. Les 30 versions les plus récentes sont conservées dans la source.

La branche `catalog` porte `source.json` et ne déclenche pas le workflow. Les builds historiques produisent leur release ; seul le commit encore en tête de main actualise le catalogue. Un échec de build laisse la dernière version publiée disponible. Les pull requests sont testées et ne publient pas de release. La relance d'un workflow conserve sa version et remplace ses assets.

[Spécification](docs/PRODUCT.md) · [Implémentation](docs/IMPLEMENTATION.md)

## Références

- [Apple : SwiftUI et design iOS 27, WWDC26](https://developer.apple.com/videos/play/wwdc2026/269/)
- [Apple : Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [SideStore : spécification de source](https://sidestore.io/sidestore-source-types/interfaces/App.html)
- [LiveContainer : projet et limitations](https://github.com/LiveContainer/LiveContainer)
- [ACT : essai randomisé, Crosby & Twohig (2016)](https://pubmed.ncbi.nlm.nih.gov/27157029/)
- [Revue des traitements de l'usage problématique de pornographie (2023)](https://pubmed.ncbi.nlm.nih.gov/37880509/)
- [CSAPA : accueil spécialisé, Drogues Info Service](https://www.drogues-info-service.fr/Tout-savoir-sur-les-drogues/Se-faire-aider/L-aide-specialisee-ambulatoire)
