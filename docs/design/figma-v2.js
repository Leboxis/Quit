// Run through use_figma in file 5wrVQf5TcnIVAJmnLN8ePs.
// Editable SwiftUI translation; Inter is the documented Figma-only font fallback.
// Local V1 components are reused; new accents and theme-choice variants are additive.
const page = await figma.getNodeByIdAsync('0:1');
await figma.setCurrentPageAsync(page);
const existing = page.children.find(n => n.name === 'Quit V2 · Design et confort');
if (existing) return { existingRoot: existing.id, message: 'V2 exists; inspect before updating.' };
const created = [], variables = [];
const track = n => { created.push(n.id); return n; };
function trackTree(n) { track(n); for (const child of n.query('*')) created.push(child.id); return n; }
const fonts = await figma.listAvailableFontsAsync();
for (const style of ['Regular', 'Medium', 'Semi Bold', 'Bold']) {
  if (!fonts.some(f => f.fontName.family === 'Inter' && f.fontName.style === style)) throw new Error('Missing Inter ' + style);
  await figma.loadFontAsync({family:'Inter', style});
}
const ids = {background:'VariableID:3:4', surface:'VariableID:3:7', accent:'VariableID:3:10', soft:'VariableID:3:13', text:'VariableID:3:16', secondary:'VariableID:3:19', border:'VariableID:3:25', onAccent:'VariableID:3:28'};
const colors = {};
for (const [key,id] of Object.entries(ids)) colors[key] = await figma.variables.getVariableByIdAsync(id);
const semantic = await figma.variables.getVariableCollectionByIdAsync('VariableCollectionId:3:3');
const primitive = await figma.variables.getVariableCollectionByIdAsync('VariableCollectionId:3:2');
const accents = figma.variables.createVariableCollection('Quit / Accent V2');
accents.renameMode(accents.modes[0].modeId, 'Light');
const light = accents.modes[0].modeId, dark = accents.addMode('Dark');
const rgb = hex => ({r:parseInt(hex.slice(0,2),16)/255, g:parseInt(hex.slice(2,4),16)/255, b:parseInt(hex.slice(4,6),16)/255});
const themes = {
  Sauge:{key:'sage', color:['38574E','BDD1C7'], soft:['E8EEE9','24372F']},
  Brume:{key:'slate', color:['3B5F7A','AFC7DB'], soft:['E7EDF3','1F303D']},
  Sable:{key:'sand', color:['745637','D6BE9A'], soft:['F0E9DF','352C21']}
};
for (const [name,theme] of Object.entries(themes)) {
  for (const key of ['color','soft']) {
    const v = figma.variables.createVariable(name+'/'+(key === 'color'?'Accent':'Soft'), accents, 'COLOR');
    variables.push(v.id); v.scopes=['FRAME_FILL','SHAPE_FILL','TEXT_FILL','STROKE_COLOR'];
    v.setVariableCodeSyntax('iOS', 'AccentTheme.'+theme.key+'.'+key);
    for (const [index,mode] of [[0,light],[1,dark]]) {
      if (name === 'Sauge') v.setValueForMode(mode,{type:'VARIABLE_ALIAS',id:colors[key === 'color'?'accent':'soft'].id});
      else {
        const p = figma.variables.createVariable(name+'/'+(index?'Dark':'Light')+'/'+key,primitive,'COLOR');
        p.scopes=[]; p.setValueForMode(primitive.modes[0].modeId,rgb(theme[key][index]));
        p.setVariableCodeSyntax('iOS', 'Color("'+(name==='Brume'?'Slate':'Sand')+(key==='color'?'Accent':'Soft')+'")');
        variables.push(p.id); v.setValueForMode(mode,{type:'VARIABLE_ALIAS',id:p.id});
      }
    }
    theme[key === 'color'?'accentVar':'softVar'] = v;
  }
}
const styles = {title:'S:ccbd5082fd4237b47ac67e98a2d111a278d8f790,', h2:'S:efaa5957c90292c6589f5b5cc3249b1f4f207b81,', headline:'S:d57ebf89dcdde88673cae2dc4e45701d72f9fdc0,', body:'S:a6b500eaaf93f0b9879a3d6ef3f720dbe49f68dc,', footnote:'S:4f4661aa66696a01dfab23b8315a67c8f36e3913,', caption:'S:174d85c45cfb48c87ccbe32704aab7d00b2ec823,', display:'S:6d2cf22ba28004f5e55dfc5f9f8d5079cbe22440,'};
const sources = {};
for (const [key,id] of Object.entries({status:'4:547', footer:'4:554', primary:'4:496', secondary:'4:498', card:'4:493', slider:'4:516'})) sources[key]=await figma.getNodeByIdAsync(id);
const fontMap=new Map();
for(const source of Object.values(sources)) for(const t of source.query('TEXT')) for(const s of t.getStyledTextSegments(['fontName'])) fontMap.set(JSON.stringify(s.fontName),s.fontName);
await Promise.all([...fontMap.values()].map(f=>figma.loadFontAsync(f)));
function fill(n,v) {n.fills=[figma.variables.setBoundVariableForPaint({type:'SOLID',color:{r:0,g:0,b:0}},'color',v)];}
function recolor(n,theme) {
  for(const item of [n,...n.query('*')]) for(const field of ['fills','strokes']) if(field in item && Array.isArray(item[field])) {
    item[field]=item[field].map(p=>{
      if(p.type!=='SOLID') return p;
      const id=p.boundVariables?.color?.id;
      return id===ids.accent?figma.variables.setBoundVariableForPaint(p,'color',theme.accentVar):id===ids.soft?figma.variables.setBoundVariableForPaint(p,'color',theme.softVar):p;
    });
  }
}
function stack(parent,name,width=358,gap=22,direction='VERTICAL') {
  const n=track(figma.createAutoLayout(direction)); n.name=name; n.fills=[]; n.itemSpacing=gap;
  n.resize(width,50); n.counterAxisSizingMode=direction==='VERTICAL'?'FIXED':'AUTO'; n.primaryAxisSizingMode=direction==='VERTICAL'?'AUTO':'FIXED';
  if(parent)parent.appendChild(n); return n;
}
async function text(parent,label,style='body',token=colors.text,width=358) {
  const t=track(figma.createText());t.name=label.slice(0,70);t.fontName={family:'Inter',style:'Regular'};
  await t.setTextStyleIdAsync(styles[style]); await figma.loadFontAsync(t.fontName);
  t.textAutoResize='NONE';t.resize(width,1);t.textAutoResize='HEIGHT';t.characters=label;fill(t,token);parent.appendChild(t);return t;
}
function box(parent,name,theme,tinted=false) {
  const n=stack(parent,name,358,16);n.paddingTop=22;n.paddingBottom=22;n.paddingLeft=22;n.paddingRight=22;n.cornerRadius=24;
  fill(n,tinted?theme.softVar:colors.surface);
  n.strokes=[figma.variables.setBoundVariableForPaint({type:'SOLID',color:{r:0,g:0,b:0},opacity:0.45},'color',colors.border)];n.strokeWeight=0.5;return n;
}
function wave(parent,theme,width=314,height=70) {
  const paths=Array.from({length:9},(_,i)=>`<path d="M0 ${16+i*4} C70 ${-13+i*5}, 145 ${76-i*3}, 220 ${32+i*3} S300 ${8+i*6}, 340 ${21+i*4}" stroke="#38574e" stroke-width="1" opacity="${0.25+i*0.065}"/>`).join('');
  const n=trackTree(figma.createNodeFromSvg(`<svg xmlns="http://www.w3.org/2000/svg" width="340" height="70" viewBox="0 0 340 70" fill="none">${paths}</svg>`));n.name='ContourArtwork';n.resize(width,height);parent.appendChild(n);
  for(const v of n.query('VECTOR'))v.strokes=v.strokes.map(p=>figma.variables.setBoundVariableForPaint(p,'color',theme.accentVar));return n;
}
function button(parent,label,theme,primary=true) {
  const n=trackTree((primary?sources.primary:sources.secondary).createInstance());n.setProperties({'Label#4:17':label});recolor(n,theme);parent.appendChild(n);n.resize(358,54);return n;
}
async function segment(parent,labels,selected,theme,width=314) {
  const row=stack(parent,'Segmented control',width,3,'HORIZONTAL');row.paddingTop=3;row.paddingBottom=3;row.paddingLeft=3;row.paddingRight=3;row.cornerRadius=10;fill(row,colors.background);
  for(const label of labels){const choice=stack(row,label,(width-6-3*(labels.length-1))/labels.length,0);choice.paddingTop=8;choice.paddingBottom=8;choice.cornerRadius=8;if(label===selected)fill(choice,theme.softVar);const t=await text(choice,label,'footnote',label===selected?theme.accentVar:colors.secondary,choice.width);t.textAlignHorizontal='CENTER';}
  return row;
}
// Adapted createComponentWithVariants helper: same Cartesian matrix and grid flow.
const choiceVariants=[];
for(const [name,theme] of Object.entries(themes))for(const selected of ['No','Yes']) {
  const c=track(figma.createComponent());c.name='Theme='+name+', Selected='+selected;c.resize(96,82);c.layoutMode='VERTICAL';c.primaryAxisSizingMode='FIXED';c.counterAxisSizingMode='FIXED';c.primaryAxisAlignItems='CENTER';c.counterAxisAlignItems='CENTER';c.itemSpacing=9;c.cornerRadius=18;fill(c,selected==='Yes'?theme.softVar:colors.background);
  const e=track(figma.createEllipse());e.resize(34,34);fill(e,theme.accentVar);c.appendChild(e);
  const label=await text(c,name,'footnote',colors.text,90);label.textAlignHorizontal='CENTER';
  if(selected==='Yes') {
    const check=trackTree(figma.createNodeFromSvg('<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18"><path d="M3 9l4 4 8-8" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>'));
    c.appendChild(check);check.layoutPositioning='ABSOLUTE';check.x=39;check.y=20;
    for(const v of check.query('VECTOR')) v.strokes=v.strokes.map(p=>figma.variables.setBoundVariableForPaint(p,'color',colors.onAccent));
  }
  choiceVariants.push(c);
}
const choiceSet=track(figma.combineAsVariants(choiceVariants,page));choiceSet.name='Quit / Theme choice V2';choiceSet.description='AppearanceSettingsView: Sauge, Brume, Sable; selected and idle states. Light/Dark colors use Accent V2 variables.';
choiceSet.x=4260;choiceSet.y=180;
choiceSet.children.forEach((c,i)=>{c.x=20+(i%2)*116;c.y=20+Math.floor(i/2)*102;});choiceSet.resize(252,326);
const root=track(figma.createFrame());root.name='Quit V2 · Design et confort';root.resize(1426,3180);root.x=2750;root.y=-180;root.fills=[];root.clipsContent=false;root.placeholder=true;
const screens={};
async function screen(name,x,y,theme,darkMode=false,footerType='tabs',title='Aujourd’hui') {
  const n=stack(root,name,402,0);n.resize(402,874);n.primaryAxisSizingMode='FIXED';n.cornerRadius=34;n.clipsContent=true;n.x=x;n.y=y;fill(n,colors.background);
  n.setExplicitVariableModeForCollection(semantic,darkMode?'3:2':'3:1');n.setExplicitVariableModeForCollection(accents,darkMode?dark:light);
  const status=trackTree(sources.status.clone());n.appendChild(status);
  const nav=stack(n,'Native navigation title',402,0);nav.paddingTop=8;nav.paddingBottom=12;nav.paddingLeft=22;nav.paddingRight=22;await text(nav,title,title==='Aujourd’hui'?'title':'headline',colors.text,358);
  const footerHeight=footerType==='tabs'?158:footerType==='action'?100:34;
  const viewport=stack(n,'Scroll viewport',402,0);viewport.resize(402,874-status.height-nav.height-footerHeight);viewport.primaryAxisSizingMode='FIXED';viewport.clipsContent=true;viewport.overflowDirection='VERTICAL';
  const content=stack(viewport,'Scroll content',402,22);content.paddingTop=12;content.paddingBottom=28;content.paddingLeft=22;content.paddingRight=22;
  let footer;
  if(footerType==='tabs'){footer=trackTree(sources.footer.clone());n.appendChild(footer);recolor(footer,theme);}
  else {footer=stack(n,'Pinned safe-area commands',402,12);footer.resize(402,footerHeight);footer.primaryAxisSizingMode='FIXED';footer.paddingTop=12;footer.paddingLeft=22;footer.paddingRight=22;fill(footer,colors.background);}
  screens[name]={id:n.id,theme:theme.key,dark:darkMode,width:n.width,height:n.height};return {n,content,footer,theme};
}
async function home(s) {
  const hero=box(s.content,'Welcome hero',s.theme,true);await text(hero,'TON ESPACE PERSONNEL  ·  JOUR 18','caption',s.theme.accentVar,314);
  const row=stack(hero,'Greeting and artwork',314,14,'HORIZONTAL');await text(row,'Bonjour, Alex.','h2',colors.text,218);wave(row,s.theme,82,48);
  const intention=box(s.content,'Mon intention',s.theme);await text(intention,'Ton intention','headline',colors.text,314);await text(intention,'« Retrouver mes soirées et une sexualité qui me ressemble. »','body',colors.text,314);
  button(s.content,'Comment tu te sens ?',s.theme);await text(s.content,'10 secondes, juste pour toi.','footnote',colors.secondary);
  const action=box(s.content,'Un seul prochain geste',s.theme);await text(action,'Un geste pour ce soir','headline',colors.text,314);await text(action,'À 23 h, laisse ton téléphone hors de la chambre.','body',colors.secondary,314);
  button(s.content,'J’ai eu un écart',s.theme,false);
}
async function appearance(s) {
  await text(s.content,'Ton espace,\nà ton image.','title');await text(s.content,'Des teintes douces et juste le mouvement dont tu as besoin.','body',colors.secondary);
  const preview=box(s.content,'Live theme preview',s.theme,true);await text(preview,'APERÇU','caption',s.theme.accentVar,314);wave(preview,s.theme);await text(preview,'Un geste à la fois.','h2',colors.text,314);await text(preview,'Ton parcours continue, à ton rythme.','footnote',colors.secondary,314);
  const picker=box(s.content,'Three ambience choices',s.theme);await text(picker,'Ton ambiance','headline',colors.text,314);const row=stack(picker,'Theme choices',314,12,'HORIZONTAL');
  for(const name of Object.keys(themes)){const source=choiceVariants.find(v=>v.name==='Theme='+name+', Selected='+(themes[name]===s.theme?'Yes':'No'));const i=trackTree(source.createInstance());row.appendChild(i);}
  const mode=box(s.content,'Color scheme',s.theme);await text(mode,'Clair ou sombre','headline',colors.text,314);await segment(mode,['Auto','Clair','Sombre'],'Clair',s.theme);
}
async function comfort(s) {
  const mode=box(s.content,'Color scheme',s.theme);await text(mode,'Clair ou sombre','headline',colors.text,314);await segment(mode,['Auto','Clair','Sombre'],'Sombre',s.theme);await text(mode,'Automatique suit le réglage de ton appareil.','footnote',colors.secondary,314);
  const options=box(s.content,'Sensory comfort',s.theme);await text(options,'Moins de stimulation','headline',colors.text,314);
  for(const [label,on] of [['Réduire les animations',true],['Vibrations discrètes',false]]){
    const row=stack(options,label,314,12,'HORIZONTAL');await text(row,label,'body',colors.text,250);const toggle=track(figma.createRectangle());toggle.resize(50,30);toggle.cornerRadius=15;fill(toggle,on?s.theme.accentVar:colors.border);row.appendChild(toggle);
    const thumb=track(figma.createEllipse());thumb.resize(24,24);fill(thumb,colors.onAccent);row.appendChild(thumb);thumb.layoutPositioning='ABSOLUTE';thumb.x=on?285:267;thumb.y=3;
  }
  await text(options,'Le réglage Réduire les animations d’iOS reste prioritaire.','footnote',colors.secondary,314);
  const duration=box(s.content,'Preferred SOS duration',s.theme);await text(duration,'Ton temps d’observation','headline',colors.text,314);await segment(duration,['90 s','3 min','5 min'],'3 min',s.theme);await text(duration,'Tu peux toujours passer à une action avant la fin.','footnote',colors.secondary,314);
}
async function progress(parent,label,theme) {const n=stack(parent,'SOS progress',358,10);await text(n,'À TON RYTHME                              '+label,'caption',colors.secondary);const bar=track(figma.createRectangle());bar.resize(358,3);bar.cornerRadius=2;fill(bar,theme.softVar);n.appendChild(bar);const active=track(figma.createRectangle());active.resize(label.startsWith('1')?60:179,3);active.cornerRadius=2;fill(active,theme.accentVar);n.appendChild(active);active.layoutPositioning='ABSOLUTE';active.x=0;active.y=bar.y;}
async function sosStart(s) {
  await progress(s.content,'1 / 6',s.theme);await text(s.content,'Une envie n’est\npas un ordre.','title');await text(s.content,'On peut créer un peu d’espace avant le prochain geste.','body',colors.secondary);
  const slider=trackTree(sources.slider.createInstance());s.content.appendChild(slider);recolor(slider,s.theme);
  await segment(s.content,['90 s','3 min','5 min'],'3 min',s.theme,358);
  await text(s.content,'Juste avant, tu te sentais…','headline');const row=stack(s.content,'Emotion choices',358,10,'HORIZONTAL');
  for(const label of ['Stressé','Seul','Fatigué']){const chip=stack(row,label,112,0);chip.paddingTop=12;chip.paddingBottom=12;chip.cornerRadius=24;fill(chip,label==='Stressé'?s.theme.accentVar:colors.surface);await text(chip,label,'footnote',label==='Stressé'?colors.onAccent:colors.text,112);}
  button(s.footer,'Créer une pause',s.theme);
}
async function sosObserve(s) {
  await progress(s.content,'3 / 6',s.theme);await text(s.content,'Laisse passer\nla vague.','title');
  const dial=track(figma.createFrame());dial.name='ObservationDial';dial.resize(358,206);dial.fills=[];s.content.appendChild(dial);
  const ring=trackTree(figma.createNodeFromSvg('<svg xmlns="http://www.w3.org/2000/svg" width="194" height="194" viewBox="0 0 194 194"><circle cx="97" cy="97" r="91" fill="#1F303D"/><circle cx="97" cy="97" r="94" fill="none" stroke="#AFC7DB" stroke-width="3" opacity=".14"/><path d="M97 3 A94 94 0 1 1 26 35" fill="none" stroke="#AFC7DB" stroke-width="3" stroke-linecap="round"/></svg>'));dial.appendChild(ring);ring.x=82;ring.y=6;
  const labels=stack(dial,'Timer and prompt',194,6);labels.x=82;labels.y=66;const time=await text(labels,'02:41','display',s.theme.accentVar,194);time.textAlignHorizontal='CENTER';const prompt=await text(labels,'Observe, simplement.','caption',colors.secondary,194);prompt.textAlignHorizontal='CENTER';
  await text(s.content,'Respire naturellement. Remarque les sensations, les pensées et leurs changements.','body',colors.secondary);
  const defusion=box(s.content,'Prendre de la distance',s.theme,true);await text(defusion,'Prendre de la distance','headline',colors.text,314);await text(defusion,'« Je remarque que mon esprit me propose de regarder. »','body',colors.text,314);
  await text(s.content,'Tu peux passer à une action à tout moment.','footnote',colors.secondary);button(s.footer,'Choisir mon prochain geste',s.theme);
}
async function checkin(s) {
  await text(s.content,'Comment ça va,\naujourd’hui ?','title');await text(s.content,'Quelques repères, sans avoir à tout raconter.','body',colors.secondary);
  const card=box(s.content,'Daily energy and stress',s.theme);await text(card,'Ton énergie','headline',colors.text,314);await segment(card,['Faible','Moyenne','Bonne'],'Moyenne',s.theme);await text(card,'Ton stress','headline',colors.text,314);await segment(card,['Faible','Moyen','Élevé'],'Moyen',s.theme);
  const slider=trackTree(sources.slider.createInstance());s.content.appendChild(slider);recolor(slider,s.theme);await text(s.content,'Un mot pour ce moment','headline');await segment(s.content,['Calme','Stressé','Seul'],'Calme',s.theme,358);button(s.footer,'Conserver mon check-in',s.theme);
}
const cover=stack(root,'V2 cover',1326,12);cover.x=50;cover.y=0;await text(cover,'Quit V2 · Un espace à ton rythme.','title',colors.text,1326);await text(cover,'DESIGN ET CONFORT · 3 AMBIANCES · PRÉFÉRENCES LOCALES · SOS À DURÉE CHOISIE','footnote',colors.secondary,1326);await text(cover,'Maquettes éditables. Inter dans Figma ; SF Pro et contrôles système dans SwiftUI. États de démonstration.','footnote',colors.secondary,1326);
await home(await screen('V2 / Aujourd’hui / Sauge',50,220,themes.Sauge));
await appearance(await screen('V2 / Apparence / Sable',512,220,themes.Sable,false,'none','Apparence et confort'));
await sosStart(await screen('V2 / SOS / Départ',974,220,themes.Sauge,false,'action','On la traverse'));
await home(await screen('V2 / Aujourd’hui / Brume sombre',50,1214,themes.Brume,true));
await comfort(await screen('V2 / Confort / Brume sombre',512,1214,themes.Brume,true,'none','Apparence et confort'));
await sosObserve(await screen('V2 / SOS / Observer sombre',974,1214,themes.Brume,true,'action','On la traverse'));
await checkin(await screen('V2 / Check-in / Sable',50,2208,themes.Sable,false,'action','Petit check-in'));
root.placeholder=false;
const evidence={createdNodeIds:created,variableIds:variables,collectionId:accents.id,modes:{light,dark},rootId:root.id,themeChoiceSet:choiceSet.id,screens,editableTexts:root.query('TEXT').length,instances:root.query('INSTANCE').length};
await root.screenshot({scale:0.6});
return evidence;
