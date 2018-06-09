onmessage = function(event) {
  importScripts("/javascripts/highlight.js");
  var result = self.hljs.highlightAuto(event.data);
  postMessage(result.value);
}
