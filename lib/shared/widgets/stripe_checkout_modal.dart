import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Modal WebView pour afficher le checkout Stripe
class StripeCheckoutModal extends StatefulWidget {
  final String checkoutUrl;
  final String sessionId;
  final String successUrl;
  final String cancelUrl;

  const StripeCheckoutModal({
    super.key,
    required this.checkoutUrl,
    required this.sessionId,
    required this.successUrl,
    required this.cancelUrl,
  });

  @override
  State<StripeCheckoutModal> createState() => _StripeCheckoutModalState();
}

class _StripeCheckoutModalState extends State<StripeCheckoutModal> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });

            // Vérifier si l'URL contient le succès ou l'annulation
            if (url.contains('promotion-success') || url.contains('donation-success')) {
              Navigator.pop(context, 'success');
            } else if (url.contains('promotion-cancel') || url.contains('donation-cancel')) {
              Navigator.pop(context, 'cancel');
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erreur de chargement: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paiement sécurisé'),
          backgroundColor: Colors.orange,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, 'cancel'),
          ),
        ),
        body: Stack(
          children: [
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _controller.reload();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            else
              WebViewWidget(controller: _controller),

            // Loading indicator
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chargement du paiement sécurisé...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
