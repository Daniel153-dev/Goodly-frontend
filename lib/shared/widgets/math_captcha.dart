import 'dart:math';
import 'package:flutter/material.dart';

/// Widget CAPTCHA mathématique pour vérifier que l'utilisateur est humain
class MathCaptcha extends StatefulWidget {
  final Function(bool) onValidated;
  final VoidCallback? onRefresh;

  const MathCaptcha({
    super.key,
    required this.onValidated,
    this.onRefresh,
  });

  @override
  State<MathCaptcha> createState() => MathCaptchaState();
}

class MathCaptchaState extends State<MathCaptcha> {
  final TextEditingController _controller = TextEditingController();
  final Random _random = Random();

  late int _number1;
  late int _number2;
  late String _operator;
  late int _correctAnswer;
  bool _isValid = false;
  bool _hasAttempted = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _controller.addListener(_validateAnswer);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    // Générer deux nombres aléatoires entre 1 et 10
    _number1 = _random.nextInt(10) + 1;
    _number2 = _random.nextInt(10) + 1;

    // Choisir un opérateur aléatoire (+, -, *)
    final operators = ['+', '-', '*'];
    _operator = operators[_random.nextInt(operators.length)];

    // Calculer la réponse correcte
    switch (_operator) {
      case '+':
        _correctAnswer = _number1 + _number2;
        break;
      case '-':
        // S'assurer que le résultat est positif
        if (_number1 < _number2) {
          final temp = _number1;
          _number1 = _number2;
          _number2 = temp;
        }
        _correctAnswer = _number1 - _number2;
        break;
      case '*':
        _correctAnswer = _number1 * _number2;
        break;
    }

    if (mounted) {
      setState(() {
        _hasAttempted = false;
        _isValid = false;
      });
    } else {
      _hasAttempted = false;
      _isValid = false;
    }

    // Utiliser addPostFrameCallback pour éviter l'appel pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValidated(false);
    });
  }

  void _validateAnswer() {
    final userAnswer = int.tryParse(_controller.text);
    final isValid = userAnswer == _correctAnswer;
    final hasAttempted = _controller.text.isNotEmpty;

    setState(() {
      _hasAttempted = hasAttempted;
      _isValid = isValid;
    });

    // Appeler le callback après le setState pour éviter les conflits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValidated(isValid);
    });
  }

  void refresh() {
    _controller.clear();
    _generateCaptcha();

    // Appeler le callback après le frame actuel
    if (widget.onRefresh != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRefresh?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasAttempted
              ? (_isValid ? Colors.green : Colors.red)
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Vérification humaine',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: refresh,
                tooltip: 'Nouvelle question',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question CAPTCHA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Combien font ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '$_number1 $_operator $_number2',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  ' ?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Champ de réponse
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Votre réponse',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    prefixIcon: Icon(
                      _hasAttempted
                          ? (_isValid ? Icons.check_circle : Icons.cancel)
                          : Icons.edit,
                      color: _hasAttempted
                          ? (_isValid ? Colors.green : Colors.red)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Message de validation
          if (_hasAttempted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isValid ? Icons.check_circle : Icons.error,
                  color: _isValid ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isValid
                      ? 'Correct ! Vous êtes humain ✓'
                      : 'Réponse incorrecte. Réessayez.',
                  style: TextStyle(
                    color: _isValid ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
