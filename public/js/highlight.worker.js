onmessage = function(event) {
  importScripts("/js/highlight.pack.js");
  var result = self.hljs.highlightAuto(unescapeHtml(event.data));
  postMessage(result.value);
}

function unescapeHtml(safe) {
  return safe.replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'");
}
