import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_themes.dart';
import '../widgets/common.dart';
import '../widgets/starfield.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  bool _signUp = false;
  bool _busy = false;

  final _usernameRule = RegExp(r'^[a-z0-9._]{3,30}$');

  Future<void> _submit() async {
    final auth = Supabase.instance.client.auth;
    final email = _email.text.trim();
    final password = _password.text;
    final username = _username.text.trim().toLowerCase();

    if (_signUp && !_usernameRule.hasMatch(username)) {
      showSnack(context, 'Pseudo : 3 à 30 caractères, lettres minuscules, chiffres, point ou tiret bas.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_signUp) {
        await auth.signUp(email: email, password: password, data: {'username': username});
        if (mounted && auth.currentSession == null) {
          showSnack(context, 'Compte créé. Confirme ton adresse mail puis connecte-toi.');
          setState(() => _signUp = false);
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Connexion impossible. Vérifie ta connexion internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Starfield(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                          BoxShadow(color: p.secondary.withValues(alpha: 0.6), blurRadius: 50, spreadRadius: 6),
                        ]),
                        child: const PlanetAvatar(name: 'O', size: 84),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('COSMEROS',
                        textAlign: TextAlign.center,
                        style: displayStyle(context, 30, weight: FontWeight.w700)
                            .copyWith(letterSpacing: 6)),
                    const SizedBox(height: 8),
                    Text('Films, séries et musique, dans ton propre univers.',
                        textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
                    const SizedBox(height: 36),
                    if (_signUp) ...[
                      TextField(
                        controller: _username,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Pseudo'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Adresse mail'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: p.accent,
                          foregroundColor: p.space,
                          shape: const StadiumBorder(),
                        ),
                        child: _busy
                            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: p.space))
                            : Text(_signUp ? 'Créer mon compte' : 'Me connecter',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
                      child: Text(_signUp ? "J'ai déjà un compte" : 'Créer un compte',
                          style: TextStyle(color: p.accent)),
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
