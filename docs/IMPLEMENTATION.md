# Plan d'implémentation

1. Établir le design system Figma : couleurs clair/sombre, SF Pro, boutons, cartes, onglets, curseur et maquettes des états essentiels. Réutiliser les composants Apple si le connecteur autorise leur import ; sinon documenter la restriction et créer des composants locaux éditables.
2. Définir les modèles Codable et les statistiques pures. Tester les jours connus et inconnus, les intensités et les données invalides. Ajouter une sauvegarde atomique protégée et un AppStore observable avec transactions qui ne modifient l'écran qu'après une écriture réussie.
3. Créer les vues natives : onboarding, Aujourd'hui, SOS, écart, parcours, insights, plans, soutien et réglages. Ajouter Dynamic Type, VoiceOver, mode sombre, cache de confidentialité et authentification optionnelle.
4. Ajouter 42 micro-exercices originaux avec références et limites d'évidence, sans reproduire un questionnaire soumis à licence ni qualifier les exercices de traitement validé.
5. Créer project.yml XcodeGen et tests XCTest. Ajouter une CI macOS choisissant Xcode 27 lorsqu'il est disponible, sinon Xcode 26 avec limitation explicitement enregistrée. Compiler pour simulateur et appareil.
6. Tester puis publier l'IPA non signé et le catalogue à partir du Info.plist compilé. Vérifier sur GitHub le workflow, les assets et l'URL source publique. Réparer toute défaillance avant de déclarer le résultat disponible.
