// Local editable components; Apple library import was refused by connector.
// Component variants follow the bundled createComponentWithVariants pattern.
const created = [];
const page = await figma.getNodeByIdAsync('0:1');
await figma.setCurrentPageAsync(page);
await Promise.all(['Regular','Medium','Semibold','Bold'].map(style => figma.loadFontAsync({family:'SF Pro',style})));
await figma.loadFontAsync({family:'SF Pro Rounded',style:'Medium'});
const colors = {};
for (const [name,id] of Object.entries({background:'VariableID:3:4',surface:'VariableID:3:7',accent:'VariableID:3:10',accentSoft:'VariableID:3:13',text:'VariableID:3:16',secondary:'VariableID:3:19',amber:'VariableID:3:22',border:'VariableID:3:25',onAccent:'VariableID:3:28'})) colors[name] = await figma.variables.getVariableByIdAsync(id);
const styles = {title:'S:ccbd5082fd4237b47ac67e98a2d111a278d8f790,',h2:'S:efaa5957c90292c6589f5b5cc3249b1f4f207b81,',headline:'S:d57ebf89dcdde88673cae2dc4e45701d72f9fdc0,',body:'S:a6b500eaaf93f0b9879a3d6ef3f720dbe49f68dc,',footnote:'S:4f4661aa66696a01dfab23b8315a67c8f36e3913,',caption:'S:174d85c45cfb48c87ccbe32704aab7d00b2ec823,',display:'S:6d2cf22ba28004f5e55dfc5f9f8d5079cbe22440,'};
function track(n) { created.push(n.id); return n; }
function fill(n, token) { n.fills = [figma.variables.setBoundVariableForPaint({type:'SOLID',color:{r:0,g:0,b:0}},'color',colors[token])]; }
function stack(parent, name, direction='VERTICAL', gap=14) {
  const n=track(figma.createAutoLayout(direction)); n.name=name; n.fills=[]; n.itemSpacing=gap;
  if(parent){parent.appendChild(n);n.layoutSizingHorizontal='FILL';}
  return n;
}
async function text(parent, label, style='body', token='text', width=314) {
  const t=track(figma.createText()); t.name=label.slice(0,60);t.fontName={family:'SF Pro',style:'Regular'};
  await t.setTextStyleIdAsync(styles[style]);await figma.loadFontAsync(t.fontName);t.characters=label;fill(t,token);t.textAutoResize='HEIGHT';t.resize(width,25);
  parent.appendChild(t);return t;
}
async function icon(parent, symbol, token='accent', size=22) {
  const t=track(figma.createText()); t.name='SF Symbol / '+symbol;t.fontName={family:'SF Pro',style:'Regular'};t.fontSize=size;
  t.characters=figma.util.getSfSymbolCharacter(symbol);fill(t,token);parent.appendChild(t);return t;
}
const card=track(figma.createComponent());card.name='QuitCard';card.description='SwiftUI QuitCard. Content area, 24 pt radius, no glass.';
card.layoutMode='VERTICAL';card.resize(358,100);card.primaryAxisSizingMode='AUTO';card.counterAxisSizingMode='FIXED';card.itemSpacing=14;
card.paddingTop=22;card.paddingBottom=22;card.paddingLeft=22;card.paddingRight=22;card.cornerRadius=24;fill(card,'surface');card.x=2200;card.y=200;
card.setBoundVariable('cornerRadius',await figma.variables.getVariableByIdAsync('VariableID:3:35'));
const cTitle=await text(card,'Titre de carte','headline');const cBody=await text(card,'Une information utile. Une action à la fois.','body','secondary');
const titleProp=card.addComponentProperty('Title','TEXT','Titre de carte');cTitle.componentPropertyReferences={characters:titleProp};
const bodyProp=card.addComponentProperty('Body','TEXT','Une information utile. Une action à la fois.');cBody.componentPropertyReferences={characters:bodyProp};
async function cardInstance(parent,title,body,tinted=false){const n=track(card.createInstance());parent.appendChild(n);n.layoutSizingHorizontal='FILL';const texts=n.findAllWithCriteria({types:['TEXT']});for(const t of texts){await figma.loadFontAsync(t.fontName);t.characters=t.name==='Titre de carte'?title:body;}if(tinted)fill(n,'accentSoft');return n;}
const variants=[];
for(const state of ['Primary','Secondary','Disabled']){
  const c=track(figma.createComponent());c.name='Style='+state;c.layoutMode='HORIZONTAL';c.resize(358,54);
  c.primaryAxisAlignItems='CENTER';c.counterAxisAlignItems='CENTER';c.cornerRadius=28;c.opacity=state==='Disabled'?0.4:1;
  fill(c,state==='Primary'?'accent':'accentSoft');const t=await text(c,'Continuer','headline',state==='Primary'?'onAccent':'accent',300);t.textAlignHorizontal='CENTER';
  const prop=c.addComponentProperty('Label','TEXT','Continuer');t.componentPropertyReferences={characters:prop};variants.push(c);
}
const buttonSet=track(figma.combineAsVariants(variants,page));buttonSet.name='QuitPrimaryButton';buttonSet.description='Native SwiftUI glassProminent on iOS 26/27, borderedProminent fallback. 44 pt minimum touch target.';
variants.forEach((v,i)=>{v.x=20;v.y=20+i*74;});buttonSet.resize(398,242);buttonSet.x=2200;buttonSet.y=450;
async function button(parent,label,secondary=false){const n=track(variants[secondary?1:0].createInstance());parent.appendChild(n);n.layoutSizingHorizontal='FILL';for(const t of n.findAllWithCriteria({types:['TEXT']})){await figma.loadFontAsync(t.fontName);t.characters=label;}return n;}
const tabs=track(figma.createComponent());tabs.name='QuitTabBar';tabs.description='Representation of system TabView. Runtime uses native iOS 27 chrome.';tabs.layoutMode='HORIZONTAL';tabs.resize(358,64);tabs.primaryAxisAlignItems='SPACE_BETWEEN';tabs.counterAxisAlignItems='CENTER';tabs.paddingLeft=12;tabs.paddingRight=12;tabs.cornerRadius=32;fill(tabs,'surface');tabs.x=2200;tabs.y=730;
const tabTitles=['Aujourd’hui','Parcours','Comprendre','Aide'];const tabSymbols=['sun.max','leaf','chart.xyaxis.line','heart'];
for(let i=0;i<4;i++){const col=stack(tabs,'Tab '+i,'VERTICAL',4);col.layoutSizingHorizontal='HUG';col.counterAxisAlignItems='CENTER';await icon(col,tabSymbols[i],i===0?'accent':'secondary',20);await text(col,tabTitles[i],'caption',i===0?'accent':'secondary',76);}
const slider=track(figma.createComponent());slider.name='IntensitySlider';slider.description='SwiftUI Slider, 0 to 10 by 1. VoiceOver announces value. Always interactive in app.';slider.layoutMode='VERTICAL';slider.resize(314,58);slider.itemSpacing=8;slider.fills=[];slider.x=2200;slider.y=830;
const sliderRow=stack(slider,'Scale','HORIZONTAL',0);sliderRow.resize(314,24);sliderRow.layoutSizingHorizontal='FILL';
const bar=track(figma.createRectangle());bar.resize(260,4);fill(bar,'accent');bar.cornerRadius=2;sliderRow.appendChild(bar);sliderRow.counterAxisAlignItems='CENTER';const thumb=track(figma.createEllipse());thumb.resize(24,24);fill(thumb,'surface');sliderRow.appendChild(thumb);
await text(slider,'Faible                                                Intense','caption','secondary',314);
async function wave(parent,height=118){const f=track(figma.createFrame());f.name='Contour / decorative';f.resize(358,height);f.fills=[];parent.appendChild(f);for(let i=0;i<9;i++){let d='';for(let p=0;p<=60;p++){const x=p*358/60,y=height*.5+Math.sin(p/60*Math.PI*2+i*.12)*height*.16+(i-4)*8;d+=(p?' L':'M')+x.toFixed(2)+' '+y.toFixed(2);}const v=track(figma.createVector());v.vectorPaths=[{windingRule:'NONE',data:d}];v.strokes=[figma.variables.setBoundVariableForPaint({type:'SOLID',color:{r:0,g:0,b:0},opacity:.16+i*.035},'color',colors.accent)];v.strokeWeight=1.2;v.fills=[];f.appendChild(v);}return f;}
const screens={};const actions={};
async function screen(key,title,index,{tab=null,dark=false,subtitle=null}={}){
  const f=stack(null,key);f.resize(402,874);f.layoutSizingHorizontal='FIXED';f.layoutSizingVertical='FIXED';f.primaryAxisSizingMode='FIXED';f.counterAxisSizingMode='FIXED';f.itemSpacing=0;f.cornerRadius=44;f.clipsContent=true;fill(f,'background');f.x=160+(index%4)*462;f.y=180+Math.floor(index/4)*994;
  if(dark)f.setExplicitVariableModeForCollection('VariableCollectionId:3:3','3:2');
  const status=stack(f,'System status','HORIZONTAL',0);status.resize(402,58);status.layoutSizingHorizontal='FILL';status.layoutSizingVertical='FIXED';status.paddingLeft=30;status.paddingRight=30;status.primaryAxisAlignItems='SPACE_BETWEEN';status.counterAxisAlignItems='CENTER';await text(status,'9:41','headline','text',60);await icon(status,'wifi','text',16);await icon(status,'battery.100','text',22);
  const content=stack(f,'Scroll content','VERTICAL',18);content.paddingLeft=22;content.paddingRight=22;content.paddingTop=14;content.paddingBottom=22;content.layoutSizingVertical='FILL';content.clipsContent=true;
  if(subtitle)await text(content,subtitle,'footnote','secondary',358);await text(content,title,'title','text',358);
  screens[key]=f;actions[key]={};
  if(tab!==null){const footer=stack(f,'Persistent SOS & native tabs','VERTICAL',8);footer.paddingLeft=22;footer.paddingRight=22;footer.paddingBottom=24;footer.paddingTop=8;actions[key].sos=await button(footer,'J’ai une envie',true);const n=track(tabs.createInstance());footer.appendChild(n);for(const t of n.findAllWithCriteria({types:['TEXT']})){if(t.name==='SF Symbol / '+tabSymbols[tab]||t.characters===tabTitles[tab])fill(t,'accent');else fill(t,'secondary');}actions[key].tabs=n;}
  return content;
}
let c=await screen('01 · Bienvenue','Reprends\nla main.',0);
await wave(c,170);await text(c,'Un peu plus de liberté.\nUn geste à la fois.','h2','text',358);
await text(c,'Observe tes habitudes, traverse les envies et construis un quotidien qui te ressemble.','body','secondary',358);
await cardInstance(c,'Ton espace, tes choix','Données locales. Aucun compte. Aucun jugement.');actions['01 · Bienvenue'].next=await button(c,'Créer mon parcours');await text(c,'Un soutien personnel, sans diagnostic ni promesse de guérison.','footnote','secondary',358);
c=await screen('02 · Aujourd’hui','Aujourd’hui',1,{tab:0,subtitle:'LUNDI 5 OCTOBRE · ÉTAT DE DÉMONSTRATION'});
await text(c,'Bonjour, Alex.','h2','text',358);await wave(c,86);
await cardInstance(c,'Ton intention','« Retrouver mes soirées et une sexualité qui me ressemble. »',true);
actions['02 · Aujourd’hui'].check=await button(c,'Comment tu te sens ?');await text(c,'10 secondes, juste pour toi.','footnote','secondary',358);
await cardInstance(c,'Un geste pour ce soir','À 23 h, laisse ton téléphone hors de la chambre.');actions['02 · Aujourd’hui'].episode=await button(c,'J’ai eu un écart',true);
c=await screen('03 · Check-in','Comment ça va ?',2,{subtitle:'CHECK-IN · 10 SECONDES'});
await text(c,'Là, tu te sens plutôt…','headline','text',358);const chips=stack(c,'Emotions','HORIZONTAL',8);for(const label of ['Calme','Seul','Fatigué']){const chip=stack(chips,label,'HORIZONTAL',0);chip.paddingTop=12;chip.paddingBottom=12;chip.paddingLeft=12;chip.paddingRight=12;chip.cornerRadius=24;fill(chip,label==='Fatigué'?'accent':'surface');await text(chip,label,'footnote',label==='Fatigué'?'onAccent':'text',80);}
await cardInstance(c,'Énergie · basse','Stress · modéré');await text(c,'Envie maintenant                              4 / 10','headline','text',358);const s1=track(slider.createInstance());c.appendChild(s1);await cardInstance(c,'Ta journée est-elle alignée ?','Tu peux répondre oui, non, ou ne pas encore savoir.');actions['03 · Check-in'].save=await button(c,'Enregistrer');
c=await screen('04 · SOS · Départ','On la traverse.',3,{subtitle:'SOS · À TON RYTHME'});
await text(c,'Une envie n’est pas un ordre.','body','secondary',358);await text(c,'Quelle est son intensité ?','headline','text',358);await text(c,'8 / 10','display','accent',358);const s2=track(slider.createInstance());c.appendChild(s2);await cardInstance(c,'Créer une pause','Pose le téléphone. Change de pièce si tu peux.');actions['04 · SOS · Départ'].next=await button(c,'Je crée une pause');await text(c,'Tu peux sortir de cet exercice à tout moment.','footnote','secondary',358);
c=await screen('05 · SOS · Observer','Laisse passer\nla vague.',4,{dark:true,subtitle:'ÉTAPE 2 · OBSERVER'});
await wave(c,200);await text(c,'01:30','display','accent',358);await text(c,'Respire naturellement. Observe où l’envie se manifeste, sans essayer de la supprimer.','body','secondary',358);await cardInstance(c,'Prendre de la distance','« Je remarque que mon esprit me propose de regarder. »',true);actions['05 · SOS · Observer'].next=await button(c,'Choisir mon prochain geste');
c=await screen('06 · Écart','Ton parcours\ncontinue.',5,{subtitle:'COMPRENDRE UN ÉPISODE'});
await text(c,'Un épisode ne supprime pas ce que tu as appris.','body','secondary',358);await cardInstance(c,'Juste avant','Fatigué · Au lit · Réseaux sociaux');await cardInstance(c,'Où interrompre la séquence ?','Quand j’ai pris le téléphone au lit.');await cardInstance(c,'Si → Alors','Si je prends mon téléphone au lit après 23 h, alors je le pose dans la cuisine.',true);actions['06 · Écart'].save=await button(c,'Enregistrer et reprendre');
c=await screen('07 · Parcours','Parcours',6,{tab:1,subtitle:'6 SEMAINES · À TON RYTHME'});
await cardInstance(c,'Semaine 1 · Observer','Comprendre mon cycle. 2 à 5 minutes par exercice.',true);actions['07 · Parcours'].lesson=await button(c,'Une envie n’est pas un ordre');
for(const [title,body] of [['2 · Mes déclencheurs','Reconnaître ce qui précède l’envie.'],['3 · Traverser','Observer, ralentir, choisir.'],['4 · Pensées et valeurs','Retrouver une direction personnelle.']])await cardInstance(c,title,body);
c=await screen('08 · Exercice','Une envie n’est\npas un ordre.',7,{subtitle:'SEMAINE 1 · 2 MIN'});
await wave(c,100);await text(c,'Une envie peut être forte sans décider de ton prochain geste. Tu peux la remarquer et choisir une action, même si elle reste présente.','body','text',358);await cardInstance(c,'Essaie maintenant','Écris : « Je remarque une envie, et je choisis de… »',true);await cardInstance(c,'Ma réflexion','Je choisis de me lever et de sortir de ma chambre.');actions['08 · Exercice'].save=await button(c,'Garder cette réflexion');
c=await screen('09 · Comprendre','Comprendre',8,{tab:2,subtitle:'30 DERNIERS JOURS · DONNÉES DE DÉMONSTRATION'});
await cardInstance(c,'12 journées alignées','Sur 15 jours renseignés. 15 jours sans saisie.',true);await cardInstance(c,'9 envies traversées','Sur 12 sessions enregistrées · baisse moyenne de 2,1 points.');await text(c,'Mes moments sensibles','headline','text',358);
const heat=stack(c,'Heatmap','VERTICAL',5);for(let row=0;row<4;row++){const r=stack(heat,'Bucket '+row,'HORIZONTAL',5);for(let col=0;col<7;col++){const cell=track(figma.createRectangle());cell.resize(44,22);cell.cornerRadius=5;fill(cell,row===2&&col>3?'accent':'accentSoft');r.appendChild(cell);}}
await text(c,'Signaux enregistrés, sans prédiction de risque.','footnote','secondary',358);await cardInstance(c,'Ce qui semble t’aider','Marcher · 5 observations · baisse moyenne de 3 points.');
c=await screen('10 · Aide','Tu peux être\naccompagné.',9,{tab:3,subtitle:'AIDE'});
await cardInstance(c,'Besoin de parler ?','Une personne de confiance. Tes données restent privées.',true);actions['10 · Aide'].contact=await button(c,'Préparer un message');actions['10 · Aide'].plans=await button(c,'Mes plans Si → Alors',true);await cardInstance(c,'Un soutien professionnel','Trouver un professionnel ou un CSAPA en France.');await cardInstance(c,'Comprendre les outils','Approches ACT et TCC. Preuves et limites accessibles.');
c=await screen('11 · Plans','Préparer\nle moment difficile.',10,{subtitle:'SI → ALORS'});
await cardInstance(c,'Si je suis seul après 23 h','Alors je pose mon téléphone dans la cuisine et je prépare une tisane.',true);await cardInstance(c,'Si l’envie dépasse 7 / 10','Alors je lance SOS et je change de pièce.');await cardInstance(c,'Protéger mon environnement','Ces plans sont des actions volontaires. Ils ne bloquent pas automatiquement des apps.');actions['11 · Plans'].save=await button(c,'Créer un plan');
c=await screen('12 · Aujourd’hui · Sombre','Aujourd’hui',11,{tab:0,dark:true,subtitle:'TON ESPACE PERSONNEL'});
await text(c,'Bonsoir, Alex.','h2','text',358);await wave(c,110);await cardInstance(c,'Ton intention','« Retrouver mes soirées et une sexualité qui me ressemble. »',true);await button(c,'Comment tu te sens ?');await cardInstance(c,'Un geste pour ce soir','Laisse ton téléphone hors de la chambre.');await text(c,'Apprendre. Reprendre. Continuer.','footnote','secondary',358);
async function link(node,dest){let root=node;while(root.parent&&root.parent.type!=='PAGE')root=root.parent;if(root.id===screens[dest].id)return;await node.setReactionsAsync([{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:screens[dest].id,navigation:'NAVIGATE',transition:{type:'DISSOLVE',easing:{type:'EASE_IN_AND_OUT'},duration:.25}}]}]);}
await link(actions['01 · Bienvenue'].next,'02 · Aujourd’hui');await link(actions['02 · Aujourd’hui'].check,'03 · Check-in');await link(actions['03 · Check-in'].save,'02 · Aujourd’hui');await link(actions['02 · Aujourd’hui'].episode,'06 · Écart');await link(actions['06 · Écart'].save,'02 · Aujourd’hui');await link(actions['04 · SOS · Départ'].next,'05 · SOS · Observer');await link(actions['05 · SOS · Observer'].next,'02 · Aujourd’hui');await link(actions['07 · Parcours'].lesson,'08 · Exercice');await link(actions['08 · Exercice'].save,'07 · Parcours');await link(actions['10 · Aide'].plans,'11 · Plans');
for(const [key,value] of Object.entries(actions)){if(value.sos)await link(value.sos,'04 · SOS · Départ');if(value.tabs){for(let i=0;i<4;i++){const target=value.tabs.children[i];await link(target,['02 · Aujourd’hui','07 · Parcours','09 · Comprendre','10 · Aide'][i]);}}}
const cover=stack(null,'Quit · Présentation','VERTICAL',14);cover.x=160;cover.y=-200;cover.resize(1788,260);fill(cover,'accentSoft');cover.paddingLeft=32;cover.paddingTop=28;cover.paddingBottom=28;
await text(cover,'Quit · Reprendre le contrôle','title','text',1200);await text(cover,'iOS 27 · SwiftUI · Un geste à la fois','h2','accent',1200);await text(cover,'Maquettes éditables et prototype. Les chiffres illustrent une démonstration ; l’app démarre sans données fictives.','body','secondary',1300);
figma.viewport.scrollAndZoomIntoView([screens['02 · Aujourd’hui'],screens['04 · SOS · Départ']]);
return {createdNodeIds:created,components:{card:card.id,button:buttonSet.id,tabs:tabs.id,slider:slider.id},screens:Object.fromEntries(Object.entries(screens).map(([key,n])=>[key,{id:n.id,width:n.width,height:n.height}])),nodeCount:created.length,editableTextCount:page.findAllWithCriteria({types:['TEXT']}).length,instanceCount:page.findAllWithCriteria({types:['INSTANCE']}).length};
