import 'dart:html' as html;
import 'dart:ui_web' as ui;

class WebVideoPlayerHelper {
  static void registerWebPlayer(String viewId, String videoUrl) {
    final videoElement = html.VideoElement()
      ..src = videoUrl
      ..controls = true
      ..autoplay = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.backgroundColor = '#000000';

    videoElement.setAttribute('preload', 'metadata');
    videoElement.setAttribute('controlsList', 'nodownload');

    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) => videoElement,
    );
  }

  static void addErrorListener(String viewId, Function(dynamic) onError) {
    // Implementation for web-specific error handling
  }

  static void addLoadedListener(String viewId, Function(dynamic) onLoaded) {
    // Implementation for web-specific loaded handling
  }
}
