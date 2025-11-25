import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/services/app_lock_service.dart';

/// Lock screen that appears when app lock is enabled.
/// User must enter correct PIN to access the app.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  final _appLockService = AppLockService();

  var _isVerifying = false;
  var _hasError = false;
  var _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    // Auto-focus the PIN field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (_isVerifying) return;

    final pin = _pinController.text;
    if (pin.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter your PIN';
      });
      _shakeController.forward().then((_) => _shakeController.reset());
      return;
    }

    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    final isValid = await _appLockService.verifyPin(pin);

    if (isValid) {
      widget.onUnlocked();
    } else {
      setState(() {
        _isVerifying = false;
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Please try again.';
        _pinController.clear();
      });
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();
    }
  }

  void _onPinChanged(String value) {
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }
    // Auto-submit when 4+ digits entered
    if (value.length >= 4) {
      _verifyPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                minHeight: size.height * 0.5,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'kivixa is locked',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your PIN to continue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // PIN input with shake animation
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          _shakeAnimation.value *
                              ((_shakeController.value * 10).toInt().isEven
                                  ? 1
                                  : -1),
                          0,
                        ),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _pinController,
                        focusNode: _focusNode,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 8,
                        style: const TextStyle(fontSize: 24, letterSpacing: 8),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '••••',
                          hintStyle: TextStyle(
                            color: colorScheme.outline,
                            letterSpacing: 8,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _hasError
                                  ? colorScheme.error
                                  : colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.error,
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: _onPinChanged,
                        onSubmitted: (_) => _verifyPin(),
                      ),
                    ),
                  ),

                  // Error message
                  if (_hasError) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: colorScheme.error, fontSize: 14),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Unlock button
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isVerifying ? null : _verifyPin,
                      child: _isVerifying
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Unlock'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PIN setup dialog for creating a new PIN
class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({super.key, this.isChanging = false});

  final bool isChanging;

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _appLockService = AppLockService();

  var _step = 0; // 0: current (if changing), 1: new, 2: confirm
  var _isProcessing = false;
  var _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isChanging) {
      _step = 1; // Skip current PIN step if setting up for first time
    }
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    setState(() {
      _errorMessage = '';
    });

    if (_step == 0) {
      // Verify current PIN
      if (_currentPinController.text.length < 4) {
        setState(() => _errorMessage = 'PIN must be at least 4 digits');
        return;
      }

      setState(() => _isProcessing = true);
      final isValid = await _appLockService.verifyPin(
        _currentPinController.text,
      );
      setState(() => _isProcessing = false);

      if (!isValid) {
        setState(() => _errorMessage = 'Incorrect PIN');
        return;
      }

      setState(() => _step = 1);
    } else if (_step == 1) {
      // Validate new PIN
      if (_newPinController.text.length < 4) {
        setState(() => _errorMessage = 'PIN must be at least 4 digits');
        return;
      }

      setState(() => _step = 2);
    } else if (_step == 2) {
      // Confirm and save PIN
      if (_confirmPinController.text != _newPinController.text) {
        setState(() => _errorMessage = 'PINs do not match');
        return;
      }

      setState(() => _isProcessing = true);

      bool success;
      if (widget.isChanging) {
        success = await _appLockService.changePin(
          _currentPinController.text,
          _newPinController.text,
        );
      } else {
        success = await _appLockService.setPin(_newPinController.text);
      }

      setState(() => _isProcessing = false);

      if (success) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _errorMessage = 'Failed to save PIN. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    String hint;
    TextEditingController controller;

    if (_step == 0) {
      title = 'Enter Current PIN';
      hint = 'Current PIN';
      controller = _currentPinController;
    } else if (_step == 1) {
      title = widget.isChanging ? 'Enter New PIN' : 'Create PIN';
      hint = 'New PIN (min 4 digits)';
      controller = _newPinController;
    } else {
      title = 'Confirm PIN';
      hint = 'Re-enter PIN';
      controller = _confirmPinController;
    }

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 8,
            autofocus: true,
            style: const TextStyle(fontSize: 20, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _onNext(),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _onNext,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_step == 2 ? 'Save' : 'Next'),
        ),
      ],
    );
  }
}

/// Dialog to remove PIN (requires PIN verification)
class RemovePinDialog extends StatefulWidget {
  const RemovePinDialog({super.key});

  @override
  State<RemovePinDialog> createState() => _RemovePinDialogState();
}

class _RemovePinDialogState extends State<RemovePinDialog> {
  final _pinController = TextEditingController();
  final _appLockService = AppLockService();
  var _isProcessing = false;
  var _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _removePin() async {
    if (_pinController.text.length < 4) {
      setState(() => _errorMessage = 'Please enter your PIN');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    final success = await _appLockService.removePin(_pinController.text);

    setState(() => _isProcessing = false);

    if (success) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = 'Incorrect PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Remove App Lock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your current PIN to disable app lock.'),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 8,
            autofocus: true,
            style: const TextStyle(fontSize: 20, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: 'PIN',
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _removePin(),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _removePin,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Remove'),
        ),
      ],
    );
  }
}
