import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';

/// Modal de don avec curseur de 1$ à 900$
class DonationModal extends StatefulWidget {
  const DonationModal({super.key});

  @override
  State<DonationModal> createState() => _DonationModalState();
}

class _DonationModalState extends State<DonationModal> {
  final ApiClient _apiClient = ApiClient();
  double _montantUsd = 10.0; // Montant par défaut: 10$
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointsAttribues = (_montantUsd * 10).toInt();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('make_donation'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            context.tr('support_goodly'),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

            const SizedBox(height: 32),

            // Affichage du montant et des points
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    context.tr('donation_amount'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_montantUsd.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.trParams('you_will_receive_points', {'points': pointsAttribues.toString()}),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Curseur
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('adjust_amount'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.tr('points_per_dollar'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: Colors.red.shade100,
                    thumbColor: Colors.red,
                    overlayColor: Colors.red.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 24,
                    ),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: _montantUsd,
                    min: 1,
                    max: 900,
                    divisions: 899,
                    label: '\$${_montantUsd.toInt()}',
                    onChanged: (value) {
                      setState(() {
                        _montantUsd = value;
                      });
                    },
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '1\$',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '900\$',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(context.tr('cancel')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processerDon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  context.trParams('donate_amount', {'amount': _montantUsd.toInt().toString()}),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informations
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('secure_payment_stripe_info'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Future<void> _processerDon() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Utiliser toujours 'mobile' pour obtenir les 2 types de données (checkout_url et PaymentIntent)
      final montantEntier = _montantUsd.toInt();

      print('[DON] Debut du processus de don: $montantEntier USD');

      // Créer la session de paiement
      print('[DON] Appel API creer-session-paiement...');
      final response = await _apiClient
          .post(
        '${ApiConstants.creerSessionPaiementDon}?montant_usd=$montantEntier&platform=mobile',
        data: {},
      )
          .timeout(
        const Duration(seconds: 30),  // Augmente a 30 secondes pour Stripe
        onTimeout: () {
          throw Exception(context.tr('timeout_server'));
        },
      );

      print('[DON] Reponse API recue: ${response.statusCode}');
      print('[DON] Donnees: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(context.tr('payment_session_error'));
      }

      // Traitement pour le web (inclus responsive mobile web)
      if (kIsWeb) {
        final checkoutUrl = response.data['checkout_url'];
        if (checkoutUrl == null) {
          throw Exception(context.tr('payment_url_unavailable'));
        }

        // Ouvrir Stripe Checkout dans le navigateur
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('payment_opened_new_tab'),
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          throw Exception(context.tr('cannot_open_payment_link'));
        }
        return;
      }
      // Traitement pour mobile
      else {
        final clientSecret = response.data['client_secret'];
        final paymentIntentId = response.data['payment_intent_id'];
        final customerId = response.data['customer_id'];
        final ephemeralKey = response.data['ephemeral_key'];

        print('[DON] Donnees Stripe recues:');
        print('[DON] - client_secret: ${clientSecret != null ? "OK" : "MANQUANT"}');
        print('[DON] - payment_intent_id: ${paymentIntentId != null ? "OK" : "MANQUANT"}');
        print('[DON] - customer_id: ${customerId != null ? "OK" : "MANQUANT"}');
        print('[DON] - ephemeral_key: ${ephemeralKey != null ? "OK" : "MANQUANT"}');

        if (clientSecret == null ||
            paymentIntentId == null ||
            customerId == null ||
            ephemeralKey == null) {
          throw Exception(context.tr('missing_payment_data'));
        }

        // Initialiser le Payment Sheet
        print('[DON] Initialisation du Payment Sheet...');
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'GOODLY',
            customerId: customerId,
            customerEphemeralKeySecret: ephemeralKey,
            style: ThemeMode.light,
            appearance: PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(
                primary: Colors.red,
              ),
            ),
          ),
        );

        print('[DON] Payment Sheet initialise avec succes');

        // Afficher le Payment Sheet
        print('[DON] Presentation du Payment Sheet...');
        await Stripe.instance.presentPaymentSheet();

        print('[DON] Payment Sheet ferme avec succes');

        // Confirmer le paiement
        print('[DON] Confirmation du paiement...');
        await _confirmerPaiement(paymentIntentId);
      }
    } on StripeException catch (e) {
      print('[DON] StripeException attrapee:');
      print('[DON] - Code: ${e.error.code}');
      print('[DON] - Message: ${e.error.message}');
      print('[DON] - LocalizedMessage: ${e.error.localizedMessage}');
      print('[DON] - DeclineCode: ${e.error.declineCode}');

      if (mounted) {
        if (e.error.code == FailureCode.Canceled) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('payment_cancelled')),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          final errorMsg = e.error.localizedMessage ?? e.error.message ?? context.tr('unknown_error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.trParams('payment_error', {'error': errorMsg})),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('[DON] Exception generale attrapee:');
      print('[DON] - Type: ${e.runtimeType}');
      print('[DON] - Message: $e');
      print('[DON] - StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                context.trParams('error_message', {'error': e.toString().replaceAll('Exception: ', '')})),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmerPaiement(String paymentIntentId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.confirmerPaiementDon(paymentIntentId),
        data: {},
      );

      if (mounted) {
        if (response.data['success'] == true) {
          Navigator.pop(context, true); // Retourner true pour indiquer le succès

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.trParams('donation_success', {
                  'amount': response.data['montant_usd'].toString(),
                  'points': response.data['points_attribues'].toString()
                }),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          throw Exception(context.tr('payment_not_confirmed'));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                context.trParams('error_message', {'error': e.toString().replaceAll('Exception: ', '')})),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}
