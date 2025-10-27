// Minimal bootstrap for GitHub Pages: load flutter.js then main.dart.js
(function(){
  function loadScript(src, onload){
    var s = document.createElement('script');
    s.src = src;
    s.async = false;
    if(onload) s.onload = onload;
    document.head.appendChild(s);
  }

  // First load flutter loader, then the compiled app
  loadScript('flutter.js', function(){
    loadScript('main.dart.js');
  });
})();
