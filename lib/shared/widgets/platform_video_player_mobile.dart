// Mobile stub - web video player not needed on mobile
class WebVideoPlayerHelper {
  static void registerWebPlayer(String viewId, String videoUrl) {
    // Not used on mobile
    throw UnsupportedError('Web video player is not supported on mobile');
  }

  static void addErrorListener(String viewId, Function(dynamic) onError) {
    // Not used on mobile
  }

  static void addLoadedListener(String viewId, Function(dynamic) onLoaded) {
    // Not used on mobile
  }
}
