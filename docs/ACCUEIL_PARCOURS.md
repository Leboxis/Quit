# Accueil, calendrier et choix des parcours — 6 octobre 2026

## Changements appliqués

- Accueil : « Jour X » centré sous le titre natif Aujourd'hui ; date et formule « à ton rythme » retirées ; intention et chevron centrés, contenu dépliable ; bloc « Un geste pour aujourd'hui » retiré. L'accès à l'analyse d'un écart conserve un libellé de fonction court.
- Check-in : bilan du jour avec humeur, énergie, stress, envie et réponse sur l'objectif. Un bouton d'information explique le fonctionnement sans imposer les explications dans l'accueil.
- Calendrier : sélection des jours, navigation par mois, détails de chaque bilan et lien vers le journal filtré sur les check-ins. Les bilans incertains sont présents ; une coche indique une saisie, pas un objectif atteint. Les journées futures sont désactivées. Le check-in du jour peut être modifié ; la consultation des jours historiques ne déplace aucune date.
- Parcours : choix entre Les fondamentaux (42 étapes et six semaines), Traverser une envie (exercices 15–21), Mon environnement (29–35) et Après un écart (36–42). Chaque parcours ouvre sa description, sa progression, son prochain exercice et ses étapes. Les parcours ciblés réutilisent les exercices existants ; ils ne sont pas des programmes cliniques nouveaux.
- Comprendre : explications retirées des blocs au profit de titres, légendes, unités et horaires. Les détails sur les données manquantes, les moyennes et leurs limites sont conservés dans « Lire mes graphiques ». Un check-in incertain ne déclenche plus le message demandant une première saisie. Le calendrier reste accessible même dans l'état vide.
- SOS : déroulement, commandes et durées conservés ; le sélecteur est intitulé « Temps pour observer l'envie », avec la possibilité de choisir une action avant la fin.

## Propositions pour compléter l'accueil

Ces options restent au choix, sans bloc supplémentaire imposé :

1. **Sept derniers check-ins** : une rangée de sept jours, avec indicateur de saisie et accès au calendrier. Option recommandée pour rendre le suivi visible sans ajouter un paragraphe.
2. **Reprendre un parcours** : une carte avec le titre du parcours, le prochain exercice et sa progression. Elle peut demander ultérieurement de conserver le parcours préféré de l'utilisateur.
3. **Trois repères** : bilans renseignés, envies traversées et exercices terminés, sur une période explicitement affichée. Plus dense et partiellement redondant avec Comprendre.

## Check-in et temps d'observation

Le check-in conserve une observation quotidienne et la réponse facultative sur l'objectif. La réponse alimente le bilan des journées dans Comprendre ; l'humeur, l'énergie, le stress et l'envie se retrouvent dans le détail du calendrier. Le journal était déjà capable de montrer et de filtrer les check-ins. Le calendrier est une vue du stockage local existant, sans nouveau schéma ni export différent.

Les 90 secondes, 3 minutes et 5 minutes sont des durées choisies pour la phase d'observation. Elles n'indiquent ni la durée nécessaire de toute la séance ni un délai garanti de disparition de l'envie. Recommandation : garder 90 secondes par défaut et les durées plus longues comme préférences de confort. La [fiche du VA sur l'observation d'une envie](https://www.mirecc.va.gov/MIRECC/visn5/EBT/CBT-SUD/Urge-Surfing.asp) décrit le principe général dans le contexte des usages de substances ; elle ne valide pas ces trois durées pour la pornographie ou pour Quit.

## Validation et limites

- Les 21 tests Python de distribution, sélection de simulateur et contraste passent. Le validateur des ressources confirme les 42 exercices et les assets existants.
- Dix tests XCTest ajoutés : calendrier et jours locaux, changement d'heure, année bissextile, historique et dates futures, cohérence des parcours, ordre des exercices, progression partagée, JSON et actualisation de doublons importés.
- Un scénario UITest ajouté : centrage du jour, intention, aide au check-in, bilan incertain dans le calendrier, progression d'un parcours ciblé après relancement et correspondance avec le parcours complet.
- XCTest/UITest, compilation SwiftUI et vérification du rendu restent non exécutés : Swift/Xcode ne sont pas installés sur l'hôte Windows.
- Aucun exercice existant, réflexion, identifiant d'exercice ou schéma de sauvegarde n'est réinitialisé. Les parcours utilisent les identifiants d'exercice existants ; aucun identifiant de parcours n'est ajouté aux données personnelles.

La vue mensuelle utilise le calendrier local, et peut défiler horizontalement sur un écran étroit ou avec de grandes polices pour conserver des zones tactiles d'au moins 44 points. La comparaison sur simulateur doit vérifier ces dispositions, l'ouverture des feuilles et le retour aux onglets.
