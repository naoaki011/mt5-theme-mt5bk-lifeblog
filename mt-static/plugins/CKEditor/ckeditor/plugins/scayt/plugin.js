﻿(function(){var a='scaytcheck',b='',c=function(){var g=this,h=function(){var k={};k.srcNodeRef=g.document.getWindow().$.frameElement;k.assocApp='CKEDITOR.'+CKEDITOR.version+'@'+CKEDITOR.revision;k.customerid=g.config.scayt_customerid||'1:11111111111111111111111111111111111111';k.customDictionaryName=g.config.scayt_customDictionaryName;k.userDictionaryName=g.config.scayt_userDictionaryName;k.defLang=g.scayt_defLang;if(CKEDITOR._scaytParams)for(var l in CKEDITOR._scaytParams)k[l]=CKEDITOR._scaytParams[l];var m=new window.scayt(k),n=d.instances[g.name];if(n){m.sLang=n.sLang;m.option(n.option());m.paused=n.paused;}d.instances[g.name]=m;try{m.setDisabled(m.paused===false);}catch(o){}g.fire('showScaytState');};g.on('contentDom',h);g.on('contentDomUnload',function(){var k=CKEDITOR.document.getElementsByTag('script'),l=/^dojoIoScript(\d+)$/i,m=/^https?:\/\/svc\.spellchecker\.net\/spellcheck\/script\/ssrv\.cgi/i;for(var n=0;n<k.count();n++){var o=k.getItem(n),p=o.getId(),q=o.getAttribute('src');if(p&&q&&p.match(l)&&q.match(m))o.remove();}});g.on('beforeCommandExec',function(k){if((k.data.name=='source'||k.data.name=='newpage')&&(g.mode=='wysiwyg')){var l=d.getScayt(g);if(l){l.paused=!l.disabled;l.destroy();delete d.instances[g.name];}}});g.on('afterSetData',function(){if(d.isScaytEnabled(g))d.getScayt(g).refresh();});g.on('insertElement',function(){var k=d.getScayt(g);if(d.isScaytEnabled(g)){if(CKEDITOR.env.ie)g.getSelection().unlock(true);try{k.refresh();}catch(l){}}},this,null,50);g.on('scaytDialog',function(k){k.data.djConfig=window.djConfig;k.data.scayt_control=d.getScayt(g);k.data.tab=b;k.data.scayt=window.scayt;});var i=g.dataProcessor,j=i&&i.htmlFilter;if(j)j.addRules({elements:{span:function(k){if(k.attributes.scayt_word&&k.attributes.scaytid){delete k.name;return k;}}}});if(g.document)h();};CKEDITOR.plugins.scayt={engineLoaded:false,instances:{},getScayt:function(g){return this.instances[g.name];},isScaytReady:function(g){return this.engineLoaded===true&&'undefined'!==typeof window.scayt&&this.getScayt(g);},isScaytEnabled:function(g){var h=this.getScayt(g);return h?h.disabled===false:false;},loadEngine:function(g){if(this.engineLoaded===true)return c.apply(g);else if(this.engineLoaded==-1)return CKEDITOR.on('scaytReady',function(){c.apply(g);});CKEDITOR.on('scaytReady',c,g);CKEDITOR.on('scaytReady',function(){this.engineLoaded=true;},this,null,0);this.engineLoaded=-1;var h=document.location.protocol;h=h.search(/https?:/)!=-1?h:'http:';var i='svc.spellchecker.net/spellcheck/lf/scayt/scayt1.js',j=g.config.scayt_srcUrl||h+'//'+i,k=d.parseUrl(j).path+'/';
CKEDITOR._djScaytConfig={baseUrl:k,addOnLoad:[function(){CKEDITOR.fireOnce('scaytReady');}],isDebug:false};CKEDITOR.document.getHead().append(CKEDITOR.document.createElement('script',{attributes:{type:'text/javascript',src:j}}));return null;},parseUrl:function(g){var h;if(g.match&&(h=g.match(/(.*)[\/\\](.*?\.\w+)$/)))return{path:h[1],file:h[2]};else return g;}};var d=CKEDITOR.plugins.scayt,e=function(g,h,i,j,k,l,m){g.addCommand(j,k);g.addMenuItem(j,{label:i,command:j,group:l,order:m});},f={preserveState:true,editorFocus:false,exec:function(g){if(d.isScaytReady(g)){var h=d.isScaytEnabled(g);this.setState(h?CKEDITOR.TRISTATE_OFF:CKEDITOR.TRISTATE_ON);var i=d.getScayt(g);i.setDisabled(h);}else if(!g.config.scayt_autoStartup&&d.engineLoaded>=0){this.setState(CKEDITOR.TRISTATE_DISABLED);g.on('showScaytState',function(){this.removeListener();this.setState(d.isScaytEnabled(g)?CKEDITOR.TRISTATE_ON:CKEDITOR.TRISTATE_OFF);},this);d.loadEngine(g);}}};CKEDITOR.plugins.add('scayt',{requires:['menubutton'],beforeInit:function(g){g.config.menu_groups='scayt_suggest,scayt_moresuggest,scayt_control,'+g.config.menu_groups;},init:function(g){var h={},i={},j=g.addCommand(a,f);CKEDITOR.dialog.add(a,CKEDITOR.getUrl(this.path+'dialogs/options.js'));var k='scaytButton';g.addMenuGroup(k);g.addMenuItems({scaytToggle:{label:g.lang.scayt.enable,command:a,group:k},scaytOptions:{label:g.lang.scayt.options,group:k,onClick:function(){b='options';g.openDialog(a);}},scaytLangs:{label:g.lang.scayt.langs,group:k,onClick:function(){b='langs';g.openDialog(a);}},scaytAbout:{label:g.lang.scayt.about,group:k,onClick:function(){b='about';g.openDialog(a);}}});g.ui.add('Scayt',CKEDITOR.UI_MENUBUTTON,{label:g.lang.scayt.title,title:g.lang.scayt.title,className:'cke_button_scayt',onRender:function(){j.on('state',function(){this.setState(j.state);},this);},onMenu:function(){var m=d.isScaytEnabled(g);g.getMenuItem('scaytToggle').label=g.lang.scayt[m?'disable':'enable'];return{scaytToggle:CKEDITOR.TRISTATE_OFF,scaytOptions:m?CKEDITOR.TRISTATE_OFF:CKEDITOR.TRISTATE_DISABLED,scaytLangs:m?CKEDITOR.TRISTATE_OFF:CKEDITOR.TRISTATE_DISABLED,scaytAbout:m?CKEDITOR.TRISTATE_OFF:CKEDITOR.TRISTATE_DISABLED};}});if(g.contextMenu&&g.addMenuItems)g.contextMenu.addListener(function(m){if(!(d.isScaytEnabled(g)&&m))return null;var n=d.getScayt(g),o=n.getWord(m.$);if(!o)return null;var p=n.getLang(),q={},r=window.scayt.getSuggestion(o,p);if(!r||!r.length)return null;for(i in h){delete g._.menuItems[i];delete g._.commands[i];
}for(i in i){delete g._.menuItems[i];delete g._.commands[i];}h={};i={};var s=false;for(var t=0,u=r.length;t<u;t+=1){var v='scayt_suggestion_'+r[t].replace(' ','_'),w=(function(A,B){return{exec:function(){n.replace(A,B);}};})(m.$,r[t]);if(t<g.config.scayt_maxSuggestions){e(g,'button_'+v,r[t],v,w,'scayt_suggest',t+1);q[v]=CKEDITOR.TRISTATE_OFF;i[v]=CKEDITOR.TRISTATE_OFF;}else{e(g,'button_'+v,r[t],v,w,'scayt_moresuggest',t+1);h[v]=CKEDITOR.TRISTATE_OFF;s=true;}}if(s)g.addMenuItem('scayt_moresuggest',{label:g.lang.scayt.moreSuggestions,group:'scayt_moresuggest',order:10,getItems:function(){return h;}});var x={exec:function(){n.ignore(m.$);}},y={exec:function(){n.ignoreAll(m.$);}},z={exec:function(){window.scayt.addWordToUserDictionary(m.$);}};e(g,'ignore',g.lang.scayt.ignore,'scayt_ignore',x,'scayt_control',1);e(g,'ignore_all',g.lang.scayt.ignoreAll,'scayt_ignore_all',y,'scayt_control',2);e(g,'add_word',g.lang.scayt.addWord,'scayt_add_word',z,'scayt_control',3);i.scayt_moresuggest=CKEDITOR.TRISTATE_OFF;i.scayt_ignore=CKEDITOR.TRISTATE_OFF;i.scayt_ignore_all=CKEDITOR.TRISTATE_OFF;i.scayt_add_word=CKEDITOR.TRISTATE_OFF;if(n.fireOnContextMenu)n.fireOnContextMenu(g);return i;});if(g.config.scayt_autoStartup){var l=function(){g.removeListener('showScaytState',l);j.setState(d.isScaytEnabled(g)?CKEDITOR.TRISTATE_ON:CKEDITOR.TRISTATE_OFF);};g.on('showScaytState',l);d.loadEngine(g);}}});})();CKEDITOR.config.scayt_maxSuggestions=5;CKEDITOR.config.scayt_autoStartup=false;
