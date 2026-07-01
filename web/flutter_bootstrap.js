{{flutter_js}}
{{flutter_build_config}}

// We define this globally so index.html can call it when a button is clicked.
window.initFlutterApp = function() {
  _flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine({
        hostElement: document.querySelector('#flutter-app-host')
      });
      await appRunner.runApp();
    }
  });
};
