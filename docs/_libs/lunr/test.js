"use strict";var LUNR_CONFIG={resultsElementId:"searchResults",countElementId:"resultCount"};function getParameterByName(e){var n=window.location.href;e=e.replace(/[\[\]]/g,"\\$&");var t=new RegExp("[?&]"+e+"(=([^&#]*)|&|#|$)").exec(n);return t?t[2]?decodeURIComponent(t[2].replace(/\+/g," ")):"":null}function parseLunrResults(e){for(var n=[],t=0;t<e.length;t++){var r=e[t].ref,l=PREVIEW_LOOKUP[r],u=l.t,a=(l.p,'<li><span class="result-title"><a href="'+l.l.replace("__site/","")+'">'+u+"</a></span>");n.push(a)}return n.length?(n.join(""),"<ul>"+n+"</ul>"):""}function escapeHtml(e){return e.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#039;")}function showResultCount(e){var n=document.getElementById(LUNR_CONFIG.countElementId);null!==n&&(n.innerHTML=e+".")}function searchLunr(e){var n=lunr.Index.load(LUNR_DATA).search(e),t=parseLunrResults(n),r=LUNR_CONFIG.resultsElementId;document.getElementById(r).innerHTML=t,showResultCount(n.length)}window.onload=function(){var e=getParameterByName("q");""!=e&&null!=e?(document.forms.lunrSearchForm.q.value=e,searchLunr(e)):showResultCount("0 (empty query)"),document.getElementById("focus").focus()};