﻿(function(){var a={ol:1,ul:1};function b(g,h){g.getCommand(this.name).setState(h);};function c(g){var r=this;var h=g.data.path.elements,i,j,k=g.editor;for(var l=0;l<h.length;l++){if(h[l].getName()=='li'){j=h[l];continue;}if(a[h[l].getName()]){i=h[l];break;}}if(i)if(r.name=='outdent')return b.call(r,k,CKEDITOR.TRISTATE_OFF);else{while(j&&(j=j.getPrevious(CKEDITOR.dom.walker.whitespaces(true))))if(j.getName&&j.getName()=='li')return b.call(r,k,CKEDITOR.TRISTATE_OFF);return b.call(r,k,CKEDITOR.TRISTATE_DISABLED);}if(!r.useIndentClasses&&r.name=='indent')return b.call(r,k,CKEDITOR.TRISTATE_OFF);var m=g.data.path,n=m.block||m.blockLimit;if(!n)return b.call(r,k,CKEDITOR.TRISTATE_DISABLED);if(r.useIndentClasses){var o=n.$.className.match(r.classNameRegex),p=0;if(o){o=o[1];p=r.indentClassMap[o];}if(r.name=='outdent'&&!p||r.name=='indent'&&p==k.config.indentClasses.length)return b.call(r,k,CKEDITOR.TRISTATE_DISABLED);return b.call(r,k,CKEDITOR.TRISTATE_OFF);}else{var q=parseInt(n.getStyle(r.indentCssProperty),10);if(isNaN(q))q=0;if(q<=0)return b.call(r,k,CKEDITOR.TRISTATE_DISABLED);return b.call(r,k,CKEDITOR.TRISTATE_OFF);}};function d(g,h,i){var j=h.startContainer,k=h.endContainer;while(j&&!j.getParent().equals(i))j=j.getParent();while(k&&!k.getParent().equals(i))k=k.getParent();if(!j||!k)return;var l=j,m=[],n=false;while(!n){if(l.equals(k))n=true;m.push(l);l=l.getNext();}if(m.length<1)return;var o=i.getParents(true);for(var p=0;p<o.length;p++)if(o[p].getName&&a[o[p].getName()]){i=o[p];break;}var q=this.name=='indent'?1:-1,r=m[0],s=m[m.length-1],t={},u=CKEDITOR.plugins.list.listToArray(i,t),v=u[s.getCustomData('listarray_index')].indent;for(p=r.getCustomData('listarray_index');p<=s.getCustomData('listarray_index');p++)u[p].indent+=q;for(p=s.getCustomData('listarray_index')+1;p<u.length&&u[p].indent>v;p++)u[p].indent+=q;var w=CKEDITOR.plugins.list.arrayToList(u,t,null,g.config.enterMode,0);if(this.name=='outdent'){var x;if((x=i.getParent())&&(x.is('li'))){var y=w.listNode.getChildren(),z=[],A=y.count(),B;for(p=A-1;p>=0;p--)if((B=y.getItem(p))&&(B.is&&B.is('li')))z.push(B);}}if(w)w.listNode.replace(i);if(z&&z.length)for(p=0;p<z.length;p++){var C=z[p],D=C;while((D=D.getNext())&&(D.is&&D.getName() in a))C.append(D);C.insertAfter(x);}CKEDITOR.dom.element.clearAllMarkers(t);};function e(g,h){var p=this;var i=h.createIterator(),j=g.config.enterMode;i.enforceRealBlocks=true;i.enlargeBr=j!=CKEDITOR.ENTER_BR;var k;while(k=i.getNextParagraph())if(p.useIndentClasses){var l=k.$.className.match(p.classNameRegex),m=0;
if(l){l=l[1];m=p.indentClassMap[l];}if(p.name=='outdent')m--;else m++;m=Math.min(m,g.config.indentClasses.length);m=Math.max(m,0);var n=CKEDITOR.tools.ltrim(k.$.className.replace(p.classNameRegex,''));if(m<1)k.$.className=n;else k.addClass(g.config.indentClasses[m-1]);}else{var o=parseInt(k.getStyle(p.indentCssProperty),10);if(isNaN(o))o=0;o+=(p.name=='indent'?1:-1)*(g.config.indentOffset);o=Math.max(o,0);o=Math.ceil(o/g.config.indentOffset)*g.config.indentOffset;k.setStyle(p.indentCssProperty,o?o+g.config.indentUnit:'');if(k.getAttribute('style')==='')k.removeAttribute('style');}};function f(g,h){var j=this;j.name=h;j.useIndentClasses=g.config.indentClasses&&g.config.indentClasses.length>0;if(j.useIndentClasses){j.classNameRegex=new RegExp('(?:^|\\s+)('+g.config.indentClasses.join('|')+')(?=$|\\s)');j.indentClassMap={};for(var i=0;i<g.config.indentClasses.length;i++)j.indentClassMap[g.config.indentClasses[i]]=i+1;}else j.indentCssProperty=g.config.contentsLangDirection=='ltr'?'margin-left':'margin-right';};f.prototype={exec:function(g){var h=g.getSelection(),i=h&&h.getRanges()[0];if(!h||!i)return;var j=h.createBookmarks(true),k=i.getCommonAncestor();while(k&&!(k.type==CKEDITOR.NODE_ELEMENT&&a[k.getName()]))k=k.getParent();if(k)d.call(this,g,i,k);else e.call(this,g,i);g.focus();g.forceNextSelectionCheck();h.selectBookmarks(j);}};CKEDITOR.plugins.add('indent',{init:function(g){var h=new f(g,'indent'),i=new f(g,'outdent');g.addCommand('indent',h);g.addCommand('outdent',i);g.ui.addButton('Indent',{label:g.lang.indent,command:'indent'});g.ui.addButton('Outdent',{label:g.lang.outdent,command:'outdent'});g.on('selectionChange',CKEDITOR.tools.bind(c,h));g.on('selectionChange',CKEDITOR.tools.bind(c,i));},requires:['domiterator','list']});})();CKEDITOR.tools.extend(CKEDITOR.config,{indentOffset:40,indentUnit:'px',indentClasses:null});
