import 'package:flutter/material.dart';

import '../l10n.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _code = TextEditingController();
  bool _signUp = false;
  bool _createGroup = false; // sign-up: make a new group instead of joining
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = _signUp
        ? await AuthService.signUp(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _pass.text,
            createGroup: _createGroup,
            code: _code.text)
        : await AuthService.signIn(_email.text.trim(), _pass.text);
    if (!mounted) return; // success: the app already switched screens
    setState(() {
      _busy = false;
      if (res == null) {
        _error = null;
      } else if (res == 'bad_invite' || res == 'error_generic') {
        _error = t(context, res);
      } else {
        _error = res;
      }
    });
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? t(context, 'required') : null;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => setAppLanguage(isAr ? 'en' : 'ar'),
                        child: Text(isAr ? 'English' : 'العربية'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(child: BrandLogo(size: 96)),
                    const SizedBox(height: 16),
                    Text(t(context, 'app_name'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(t(context, 'tagline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.muted)),
                    const SizedBox(height: 28),
                    if (_signUp) ...[
                      TextFormField(
                        controller: _name,
                        decoration: fieldDec(label: t(context, 'name')),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: fieldDec(label: t(context, 'email')),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: fieldDec(label: t(context, 'password')),
                      validator: _required,
                    ),
                    if (_signUp) ...[
                      const SizedBox(height: 16),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                              value: false, label: Text(t(context, 'have_code'))),
                          ButtonSegment(
                              value: true, label: Text(t(context, 'new_group'))),
                        ],
                        selected: {_createGroup},
                        onSelectionChanged: (s) =>
                            setState(() => _createGroup = s.first),
                      ),
                      const SizedBox(height: 12),
                      if (_createGroup)
                        Text(t(context, 'new_group_hint'),
                            style: TextStyle(color: context.muted))
                      else
                        TextFormField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          decoration: fieldDec(label: t(context, 'invite')),
                          validator: _required,
                        ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style:
                              TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(t(context, _signUp ? 'sign_up' : 'sign_in')),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _signUp = !_signUp;
                                _error = null;
                              }),
                      child: Text(t(context, _signUp ? 'have_account' : 'no_account')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
