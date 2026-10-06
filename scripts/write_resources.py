import json
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
colors = {'Background': ('F7F6F2','101513'), 'Surface': ('FFFFFF','19211D'), 'AccentColor': ('346451','AACBB1'), 'AccentSoft': ('E7EEE6','23362B'), 'TextPrimary': ('18231D','F3F4EF'), 'TextSecondary': ('59675F','A5B1A8'), 'Amber': ('8C632E','D9BB8C'), 'Border': ('E0E5DD','354039'), 'OnAccent': ('FFFFFF','101513'), 'SlateAccent': ('3B5F7A','AFC7DB'), 'SlateSoft': ('E7EDF3','1F303D'), 'SandAccent': ('745637','D6BE9A'), 'SandSoft': ('F0E9DF','352C21')}
assets=root/'Quit/Resources/Assets.xcassets'
assets.mkdir(parents=True,exist_ok=True)
(assets/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}},indent=2)+'\n')
for name,pair in colors.items():
    folder=assets/(name+'.colorset'); folder.mkdir(exist_ok=True)
    entries=[]
    for i,h in enumerate(pair):
        rgb={c:f'{int(h[j:j+2],16)/255:.6f}' for c,j in [('red',0),('green',2),('blue',4)]}
        entry={'idiom':'universal','color':{'color-space':'srgb','components':{'alpha':'1.000',**rgb}}}
        if i: entry['appearances']=[{'appearance':'luminosity','value':'dark'}]
        entries.append(entry)
    (folder/'Contents.json').write_text(json.dumps({'colors':entries,'info':{'author':'xcode','version':1}},indent=2)+'\n')
icon=assets/'AppIcon.appiconset';icon.mkdir(exist_ok=True)
for dark in (False,True):
    scale=3; im=Image.new('RGB',(1024*scale,1024*scale),'#101513' if dark else '#346451');draw=ImageDraw.Draw(im)
    color='#AACBB1' if dark else '#EDF1E8'
    for offset,width in ((0,24),(54,8),(99,5)):
        box=tuple(int(x*scale) for x in (230-offset,210-offset,790+offset,770+offset))
        draw.arc(box,32,348,fill=color,width=width*scale)
    draw.line([(int(x*scale),int(y*scale)) for x,y in [(618,640),(787,804)]],fill=color,width=25*scale)
    draw.ellipse((775*scale,792*scale,799*scale,816*scale),fill=color)
    im.resize((1024,1024),Image.Resampling.LANCZOS).save(icon/('IconDark.png' if dark else 'Icon.png'))
(icon/'Contents.json').write_text(json.dumps({'images':[{'filename':'Icon.png','idiom':'universal','platform':'ios','size':'1024x1024'},{'filename':'IconDark.png','idiom':'universal','platform':'ios','size':'1024x1024','appearances':[{'appearance':'luminosity','value':'dark'}]}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
(root/'docs/design/icon.png').write_bytes((icon/'Icon.png').read_bytes())

source_act='https://pubmed.ncbi.nlm.nih.gov/27157029/'
source_review='https://pubmed.ncbi.nlm.nih.gov/37880509/'
# Original educational copy. These are not a validated treatment protocol.
weeks=[
[
('Une envie n’est pas un ordre','Une envie peut être forte sans décider de ton prochain geste. Remarquer une sensation et choisir une action sont deux événements différents. Aujourd’hui, il suffit de repérer cet espace, même s’il te semble très court.','Quand ai-je déjà choisi une autre action malgré une envie ?','Complète : « Je remarque une envie, et je choisis de… »'),
('Mon objectif m’appartient','Arrêter ou réduire peut prendre différentes formes. Choisis un objectif qui améliore ta vie plutôt qu’un chiffre imposé. Tu peux réviser cet objectif. Ta sexualité et la masturbation ne sont pas des échecs : ce parcours concerne l’usage de pornographie que tu veux changer.','Qu’est-ce que je souhaite retrouver dans mon quotidien ?','Note une raison personnelle, précise et bienveillante.'),
('Observer mon cycle','Un épisode commence souvent par une suite de petites étapes : un contexte, une émotion, une pensée, un geste. Observer cette chaîne aide à trouver un endroit où intervenir. Il ne s’agit pas de chercher une faute.','Quelle suite de gestes a précédé mon dernier épisode ?','Reconstitue trois étapes : avant, pendant, après.'),
('Le soulagement à court terme','Certains comportements apportent un soulagement immédiat mais ont un coût plus tard. Les deux peuvent être vrais. Comprendre ce que le comportement t’apporte aide à chercher une alternative qui répond au même besoin.','Quel besoin cherchais-je à satisfaire ?','Note un bénéfice immédiat et un coût à plus long terme.'),
('Un check-in sans jugement','Un check-in est une photographie, pas une note. Stress, énergie et intensité peuvent changer dans la journée. Une réponse difficile n’est pas un mauvais résultat : elle donne une information utile pour choisir un geste adapté.','Qu’est-ce que je ressens maintenant ?','Fais un check-in sans chercher la « bonne » réponse.'),
('Les jours inconnus','Une journée sans saisie reste inconnue. L’app ne devine ni réussite ni épisode. Mieux vaut quelques observations honnêtes qu’un historique parfait inventé. Tu peux aussi choisir de moins suivre si cela te préoccupe trop.','Quel rythme de suivi me semble utile et supportable ?','Choisis un moment simple pour ton prochain bilan.'),
('Mon premier bilan','Cherche une chose apprise cette semaine, même petite. Le but est de mieux comprendre tes choix et de revenir à ton plan. Un compteur de jours ne décrit pas à lui seul ce que tu as acquis.','Qu’est-ce que j’ai compris sur mon cycle ?','Garde un repère utile et une action à essayer la semaine prochaine.')
],
[
('Les lieux qui reviennent','Certains lieux facilitent un automatisme : le lit, un bureau isolé ou un espace où le téléphone est toujours proche. Le lieu ne cause pas forcément l’épisode, mais il peut offrir une occasion de changer le contexte.','Dans quel lieu ai-je le plus besoin d’une pause ?','Choisis un autre endroit où aller pendant une envie.'),
('Les moments sensibles','Fatigue et habitudes horaires peuvent rendre un moment plus difficile. Tes enregistrements décrivent ce qui s’est passé ; ils ne prédisent pas l’avenir. Prépare une action pour une fenêtre qui revient dans ton expérience.','Quelle période de la journée revient souvent ?','Prépare un geste dix minutes avant cette fenêtre.'),
('Le scrolling comme première étape','Un contenu suggestif peut apparaître bien avant une recherche volontaire. Repérer le premier geste de scrolling offre une interruption possible. Une modification de l’environnement peut rendre cette interruption plus facile.','Quel compte, écran ou geste me fait continuer à scroller ?','Retire une notification ou un abonnement que tu choisis.'),
('Stress : repérer le besoin','Quand le stress monte, une envie peut devenir une façon de chercher du soulagement. Prends un instant pour identifier ce qui pèse sur toi. Une action très courte peut répondre au besoin de repos ou de soutien.','Qu’est-ce qui me met sous pression aujourd’hui ?','Choisis une pause ou une petite demande d’aide concrète.'),
('Solitude : chercher du lien','Se sentir seul ne se résout pas toujours par une distraction. Un contact léger peut être plus adapté : parler, rejoindre un espace partagé, ou prévoir un moment avec quelqu’un. Tu n’as pas besoin d’expliquer tout ton parcours.','Qui puis-je contacter sans devoir tout expliquer ?','Prépare un message : « Tu as cinq minutes pour parler ? »'),
('Ennui : rendre une alternative visible','L’ennui peut laisser de la place à un automatisme. Une alternative fonctionne mieux si elle est déjà accessible et te plaît un minimum. Une activité simple est parfois plus utile qu’un grand programme.','Quelle activité courte ai-je envie de rendre facile ?','Place un livre, une musique ou une tâche légère à portée.'),
('Ma carte personnelle','Regroupe un moment, une émotion et un contexte qui reviennent. Il n’est pas nécessaire d’avoir un grand nombre de données pour préparer un geste. Garde les conclusions provisoires et révise-les avec ton expérience.','Quel motif me semble le plus utile à préparer ?','Écris un plan Si → Alors pour un seul motif.')
],
[
('Créer une rupture physique','Changer de pièce ou poser le téléphone peut interrompre une séquence avant qu’elle devienne automatique. Cette pause ne supprime pas forcément l’envie. Elle sert à retrouver une possibilité de choisir.','Quel geste physique est faisable en moins de dix secondes ?','Essaie maintenant de te lever et de poser le téléphone.'),
('Observer la vague','L’intensité d’une envie peut changer avec le temps. Observe les sensations sans chercher à les forcer à disparaître. Si l’exercice t’inconforte, reviens à ce qui t’entoure ou choisis une autre stratégie.','Où est-ce que je ressens l’envie dans mon corps ?','Observe pendant une minute, avec une respiration naturelle.'),
('Rester avec une sensation','Décris une sensation avec des mots simples : chaleur, tension, agitation. Cette description n’est ni une approbation ni une obligation d’agir. Tu peux garder les yeux ouverts et t’arrêter si cela ne t’aide pas.','Quels mots décrivent ce que je ressens ?','Nomme trois sensations sans les évaluer.'),
('Retarder le prochain geste','Un délai court peut créer un espace de décision. Il n’est pas nécessaire de promettre que l’envie aura disparu à la fin. Choisis un geste pour les prochaines minutes, puis réévalue ce dont tu as besoin.','Qu’est-ce que je peux faire pendant les cinq prochaines minutes ?','Prépare une alternative avant de remettre le téléphone en main.'),
('Choisir une action adaptée','Une stratégie a plus de chances d’être utilisée si elle correspond au besoin : lien quand tu te sens seul, repos quand tu es épuisé, mouvement quand tu tournes en rond. Tes préférences comptent.','Quelle action répond le mieux à mon besoin maintenant ?','Essaie une action et note l’intensité avant et après.'),
('Quand l’envie reste forte','Une envie qui reste forte ne veut pas dire que tu as mal fait l’exercice. Change de contexte, essaie un autre geste ou demande du soutien. Le but est d’élargir tes possibilités, pas de réussir un test.','Quel est mon deuxième geste si le premier ne suffit pas ?','Prépare deux options simples et une personne à contacter.'),
('Ce qui semble m’aider','Les chiffres avant et après une action donnent un repère personnel. Peu d’observations ne suffisent pas à prouver une efficacité. Cherche aussi ce qui rend une stratégie faisable dans ta vraie journée.','Quelle stratégie puis-je répéter facilement ?','Garde une stratégie utile et une solution de secours.')
],
[
('Je remarque une pensée','Une pensée peut se présenter comme un ordre : « Il faut que je regarde. » Ajouter « je remarque la pensée que… » peut créer une distance. La pensée reste présente ; ton action n’est pas décidée pour autant.','Quelle pensée apparaît souvent avant l’automatisme ?','Reformule-la avec « Je remarque la pensée que… »'),
('Mes valeurs, en pratique','Une valeur est une direction : présence, liberté, intimité, soin de soi. Elle devient utile quand elle se traduit en un petit geste. Ce geste peut être choisi aujourd’hui, sans attendre de te sentir parfaitement motivé.','Quelle direction voudrais-je suivre dans ma vie ?','Associe une valeur à un geste de deux minutes.'),
('Accueillir une émotion','Une émotion difficile peut mériter attention, repos ou soutien. La faire disparaître n’est pas toujours possible immédiatement. Tu peux reconnaître ce qui est là et choisir une réponse qui prend soin de toi.','De quoi cette émotion me signale-t-elle le besoin ?','Dis-toi : « C’est difficile, et je peux choisir un geste utile. »'),
('Le piège du tout ou rien','« Tout est perdu » peut apparaître après un écart. Cette pensée ne décrit pas l’ensemble de ton parcours. Les journées, les stratégies et les apprentissages restent là. Un prochain geste est possible maintenant.','Quelle phrase tout ou rien me vient après un épisode ?','Remplace-la par une description précise de ce qui s’est passé.'),
('Me parler comme à un ami','La manière dont tu te parles peut faciliter ou compliquer ton retour au plan. Un ton bienveillant peut reconnaître les conséquences sans transformer un épisode en jugement sur ta personne.','Que dirais-je à un ami dans cette situation ?','Écris cette même phrase pour toi.'),
('Une sexualité qui me ressemble','Ce parcours ne classe pas la sexualité comme bonne ou mauvaise. Il vise les comportements que tu veux changer et leurs conséquences. Si la honte ou un conflit de valeurs prennent beaucoup de place, en parler à un professionnel peut aider.','Quels choix sexuels me semblent libres et respectueux de moi ?','Note une question à explorer sans te juger.'),
('Ma direction cette semaine','Relis ton intention personnelle. Si elle sonne comme une punition, tu peux la reformuler autour de ce que tu veux retrouver. Une direction utile reste compréhensible dans une journée ordinaire.','Mon intention me soutient-elle encore ?','Réécris-la si nécessaire dans les réglages.')
],
[
('Une place pour mon téléphone','Le téléphone peut rester disponible tout en ayant une place choisie hors d’un contexte sensible. Préparer cette place avant le soir demande moins de décisions pendant une envie. Ce geste reste volontaire.','Où puis-je charger mon téléphone hors de la chambre ?','Prépare cet endroit aujourd’hui.'),
('Ma fenêtre sensible','Un plan peut commencer avant le moment le plus difficile. Choisis une heure et un geste modeste. Le plan n’a pas besoin de couvrir toute ta journée ni de restreindre toutes tes activités.','Quel geste puis-je préparer avant cette fenêtre ?','Crée un plan Si → Alors avec une heure précise.'),
('Les limites iOS comme friction','Temps d’écran peut ajouter des limites et des restrictions volontaires. Cette version de Quit ne les active pas automatiquement. Un blocage ne remplace pas l’apprentissage ni l’aide humaine et peut être contourné.','Quelle friction volontaire me serait utile ?','Explore Temps d’écran dans Réglages, sans te promettre une protection absolue.'),
('Réduire les premières occasions','Une notification ou un raccourci visible peut relancer une habitude. Tu peux retirer une occasion sans chercher à contrôler tous les contenus possibles. Préserve aussi les outils et contacts utiles dans ta vie.','Quel déclencheur numérique puis-je rendre moins visible ?','Désactive une notification ou déplace une app que tu choisis.'),
('Préparer une soirée simple','Une soirée structurée n’a pas besoin d’être chargée. Repas, repos, lien ou activité légère peuvent créer un cadre prévisible. La fatigue mérite parfois surtout du sommeil et moins d’écrans.','Quel petit rituel m’aiderait à terminer la journée ?','Prépare une séquence de deux gestes pour ce soir.'),
('Mon contact de soutien','Le soutien ne doit pas devenir de la surveillance. Tu choisis quoi partager et avec qui. Un contact peut simplement offrir une conversation ou de la présence, sans recevoir tes données personnelles.','Quel soutien ai-je envie de demander ?','Prépare un contact et un message dans l’onglet Aide.'),
('Un environnement ajustable','Un plan qui ne tient pas dans ta vie mérite un ajustement. Observe ce qui a été difficile à appliquer : horaire, effort, lieu ou besoin mal identifié. Réduire la taille d’un geste peut le rendre plus utile.','Quel plan gagnerait à être plus simple ?','Révise un plan à partir de ce que tu as essayé.')
],
[
('Comprendre un écart','Reconstituer un épisode sert à apprendre, pas à te punir. Choisis quelques informations : émotion, contexte, déclencheur et premier geste. Une analyse courte suffit souvent pour préparer la suite.','À quel moment aurais-je pu interrompre la chaîne ?','Utilise le journal pour trouver une interruption précise.'),
('Reprendre le jour même','Un épisode n’oblige pas à poursuivre pendant des jours. Tu peux revenir à un geste ordinaire : fermer un écran, changer de pièce, manger ou contacter quelqu’un. Le retour au plan se fait à ton rythme.','Quel geste marque pour moi le retour à mon plan ?','Choisis ce geste et note le retour quand il a réellement eu lieu.'),
('Mon plan de secours','Prévoir une option de secours réduit le nombre de décisions à prendre pendant un moment difficile. Une stratégie peut ne pas être disponible : pluie, absence d’un ami, fatigue. Prépare une autre possibilité.','Que puis-je faire si ma première option est impossible ?','Écris une alternative faisable sans matériel ni connexion.'),
('Quand demander davantage d’aide','Si la perte de contrôle persiste ou affecte nettement ta vie, un accompagnement professionnel peut être utile. Tu n’as pas besoin d’atteindre un score ou une gravité arbitraire pour demander de l’aide.','Quel point aimerais-je discuter avec un professionnel ?','Explore les ressources d’Aide ou prépare une question pour un rendez-vous.'),
('Des progrès qui restent','Observe plusieurs dimensions : fréquence des épisodes, intensité des envies, actions essayées et retour au plan. Une amélioration ne se produit pas forcément partout en même temps. Les données restent des repères, pas un verdict.','Quel progrès vois-je au-delà d’un compteur ?','Note un apprentissage et un changement concret dans ta vie.'),
('Avoir moins besoin de l’app','L’app est un outil, pas une activité à entretenir pour elle-même. Quand tes gestes deviennent plus naturels, tu peux réduire le suivi ou les rappels. Le soutien humain et les activités qui comptent gardent leur place.','Quel rythme de suivi me serait utile à présent ?','Choisis moins de suivi si cela te convient.'),
('Mon prochain chapitre','Relis ce que tu as appris et garde quelques outils simples. Ton parcours peut continuer avec des ajustements, du soutien et des retours ponctuels. Une difficulté future ne rendra pas ces apprentissages inexistants.','Quels trois repères ai-je envie de conserver ?','Garde une intention, un geste pour les envies et un plan de retour.')
]]
lessons=[]
for week in weeks:
    for title,body,prompt,action in week:
        lessons.append({'id':len(lessons)+1,'title':title,'body':body,'prompt':prompt,'action':action,'source':source_act if len(lessons)//7 in (2,3) else source_review})
(root/'Quit/Resources/lessons.json').write_text(json.dumps(lessons,ensure_ascii=False,indent=2)+'\n')
print(f'Created {len(lessons)} lessons, {len(colors)} semantic colors, light/dark icons.')
