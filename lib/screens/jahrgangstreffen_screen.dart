import 'package:flutter/material.dart';

import '../api/meetup_api.dart';
import '../models/meetup.dart';
import 'teilnehmerliste_screen.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Jahrgangstreffen registration (website: `jahrgangstreffen/index.vue`):
/// intro, a link to the participant list, and the sign-up form posted to
/// `POST /api/v1/meetup`.
class JahrgangstreffenScreen extends StatefulWidget {
  const JahrgangstreffenScreen({super.key});

  @override
  State<JahrgangstreffenScreen> createState() => _JahrgangstreffenScreenState();
}

class _JahrgangstreffenScreenState extends State<JahrgangstreffenScreen> {
  final _api = MeetupApi();
  final _formKey = GlobalKey<FormState>();
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _email = TextEditingController();
  MeetupJahrgang? _jahrgang;
  bool _showOnList = true;

  bool _submitting = false;
  bool _submitted = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    // Re-evaluate the submit button's enabled state as the user types.
    for (final c in [_firstname, _lastname, _email]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _required(String? v, String message) => (v == null || v.trim().isEmpty) ? message : null;

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'E-Mail ist erforderlich';
    if (!_emailPattern.hasMatch(v.trim())) return 'Ungültige E-Mail-Adresse';
    return null;
  }

  /// Mirrors the website, which keeps "Anmelden" disabled until valid.
  bool get _isValid => _firstname.text.trim().isNotEmpty && _lastname.text.trim().isNotEmpty && _validateEmail(_email.text) == null && _jahrgang != null;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _jahrgang == null) {
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await _api.register(
        MeetupRegistration(
          firstname: _firstname.text.trim(),
          lastname: _lastname.text.trim(),
          email: _email.text.trim(),
          jahrgang: _jahrgang!,
          showOnList: _showOnList,
        ),
      );
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        setState(() => _submitError = 'Die Anmeldung konnte nicht gespeichert werden. Bitte versuche es später erneut.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() => setState(() {
    _firstname.clear();
    _lastname.clear();
    _email.clear();
    _jahrgang = null;
    _showOnList = true;
    _submitted = false;
    _submitError = null;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Jahrgangstreffen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Image.asset('assets/logo-widerluege.png', width: 160)),
          const SizedBox(height: 16),
          const Text(
            'Das Schlierefäscht bietet den perfekten Rahmen für ein Wiedersehen '
            'mit alten Schulkameraden und Freunden. Beim Jahrgangstreffen kommen '
            'alle Jahrgänge zusammen – für einen unvergesslichen Abend voller '
            'Erinnerungen.',
          ),
          const SizedBox(height: 8),
          const Text('Melde dich an und sei dabei!'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeilnehmerlisteScreen())),
              icon: const Icon(Icons.arrow_forward),
              iconAlignment: IconAlignment.end,
              label: const Text('Zur Teilnehmerliste'),
            ),
          ),
          const SizedBox(height: 24),
          if (_submitted) ..._success(theme) else ..._form(theme),
        ],
      ),
    );
  }

  List<Widget> _success(ThemeData theme) => [
    Card(
      color: Colors.green.shade50,
      child: const ListTile(
        leading: Icon(Icons.check_circle_outline, color: Colors.green),
        title: Text('Anmeldung erfolgreich!'),
        subtitle: Text('Vielen Dank für deine Anmeldung. Wir freuen uns auf dich!'),
      ),
    ),
    const SizedBox(height: 16),
    Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(onPressed: _resetForm, icon: const Icon(Icons.add), label: const Text('Weitere Anmeldung vornehmen')),
    ),
  ];

  List<Widget> _form(ThemeData theme) => [
    Text(
      'Anmeldung',
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
    ),
    const SizedBox(height: 12),
    if (_submitError != null) ...[
      Card(
        color: theme.colorScheme.errorContainer,
        child: ListTile(
          leading: Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          title: const Text('Fehler beim Senden'),
          subtitle: Text(_submitError!),
        ),
      ),
      const SizedBox(height: 12),
    ],
    Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _firstname,
            decoration: const InputDecoration(labelText: 'Vorname *', hintText: 'Max'),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) => _required(v, 'Vorname ist erforderlich'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastname,
            decoration: const InputDecoration(labelText: 'Nachname *', hintText: 'Muster'),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) => _required(v, 'Nachname ist erforderlich'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'E-Mail *', hintText: 'max.muster@example.com'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: _validateEmail,
          ),
          const SizedBox(height: 8),
          Text(
            'Die Angabe Deiner Mail-Adresse benötigen wir einzig, um Dich '
            'zu informieren, wo Dein Jahrgangstreffen stattfinden wird. '
            'Nach diesem Info-Mail werden sämtliche Mail-Adressen bei uns '
            'wieder gelöscht.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MeetupJahrgang>(
            // Keyed on the selection so "Weitere Anmeldung" resets it.
            key: ValueKey(_jahrgang),
            initialValue: _jahrgang,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Jahrgang *'),
            hint: const Text('Bitte wählen…'),
            items: [
              for (final j in MeetupJahrgang.values)
                DropdownMenuItem(
                  value: j,
                  child: Text(j.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            validator: (v) => v == null ? 'Jahrgang ist erforderlich' : null,
            onChanged: (v) => setState(() => _jahrgang = v),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _showOnList,
            title: const Text('Ich möchte auf der Teilnehmerliste erscheinen'),
            onChanged: (v) => setState(() => _showOnList = v ?? true),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isValid && !_submitting ? _submit : null,
            child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Anmelden'),
          ),
        ],
      ),
    ),
  ];
}
