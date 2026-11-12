import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../api/problem_report_api.dart';
import '../services/geolocation.dart';
import '../services/prefs.dart';

/// A photo picked for a problem report: its bytes and file name.
typedef PickedPhoto = ({Uint8List bytes, String name});

/// Opens the camera or the gallery; null when the visitor cancels. Throws a
/// [PlatformException] (`camera_access_denied`, …) when access is not allowed.
typedef PhotoPicker = Future<PickedPhoto?> Function(ImageSource source);

enum _AccessChoice { retry, settings }

/// "Problem melden" (app only): visitors report a problem on the festival
/// grounds — overflowing toilet, unsecured cables, … — with their name and a
/// description (both required), optionally a phone number, a photo and their
/// current position. The backend mails it to the OK (`POST /api/v1/problem-report`);
/// nothing is stored. Name and phone are remembered for the next report.
class ProblemReportScreen extends StatefulWidget {
  const ProblemReportScreen({super.key, this.api, this.pickPhoto, this.currentPosition, this.openSettings});

  /// Overridable for tests.
  final ProblemReportApi? api;
  final PhotoPicker? pickPhoto;
  final Future<Position?> Function()? currentPosition;
  final Future<bool> Function()? openSettings;

  @override
  State<ProblemReportScreen> createState() => _ProblemReportScreenState();
}

/// Photos are scaled down on the device, so even a camera shot uploads in a
/// few hundred KB over the festival's weak connection.
Future<PickedPhoto?> _pickPhoto(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
  if (file == null) return null;
  return (bytes: await file.readAsBytes(), name: file.name);
}

class _ProblemReportScreenState extends State<ProblemReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: Prefs.instance.reporterName);
  late final _phone = TextEditingController(text: Prefs.instance.reporterPhone);
  final _description = TextEditingController();
  late final _api = widget.api ?? ProblemReportApi();

  PickedPhoto? _photo;
  bool _sendLocation = false;
  bool _sending = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _name.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  /// The source to open again when the visitor comes back from the system
  /// settings, where they went to allow camera / photo access.
  ImageSource? _retryOnResume;

  Future<void> _choosePhoto(ImageSource source) async {
    try {
      final photo = await (widget.pickPhoto ?? _pickPhoto)(source);
      if (photo != null && mounted) setState(() => _photo = photo);
    } on PlatformException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'camera_access_denied' || 'photo_access_denied':
          await _askForAccess(source);
        case 'camera_access_restricted' || 'photo_access_restricted':
          // Blocked by device management / parental controls: settings won't help.
          _snack('Der Zugriff auf ${_what(source)} ist auf diesem Gerät gesperrt.');
        default:
          _snack('${source == ImageSource.camera ? 'Die Kamera' : 'Die Galerie'} konnte nicht geöffnet werden.');
      }
    } catch (_) {
      if (mounted) _snack('${source == ImageSource.camera ? 'Die Kamera' : 'Die Galerie'} konnte nicht geöffnet werden.');
    }
  }

  static String _what(ImageSource source) => source == ImageSource.camera ? 'die Kamera' : 'deine Fotos';

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Access was declined: explain why the app needs it and let the visitor
  /// allow it right away. Android shows its permission prompt again on a new
  /// attempt (until "Don't ask again"); iOS asks only once, after that only the
  /// system settings can allow it.
  Future<void> _askForAccess(ImageSource source) async {
    final canAskAgain = defaultTargetPlatform == TargetPlatform.android;
    final choice = await showDialog<_AccessChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(source == ImageSource.camera ? 'Zugriff auf die Kamera' : 'Zugriff auf deine Fotos'),
        content: Text(
          'Damit du ein Foto zum Problem ${source == ImageSource.camera ? 'aufnehmen' : 'anhängen'} kannst, braucht die App Zugriff auf ${_what(source)}. '
          '${canAskAgain ? 'Erlaube ihn beim nächsten Versuch oder in den Einstellungen.' : 'Du kannst ihn in den Einstellungen erlauben.'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          if (canAskAgain) TextButton(onPressed: () => Navigator.pop(context, _AccessChoice.retry), child: const Text('Erneut versuchen')),
          FilledButton(onPressed: () => Navigator.pop(context, _AccessChoice.settings), child: const Text('Einstellungen öffnen')),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _AccessChoice.retry:
        await _choosePhoto(source);
      case _AccessChoice.settings:
        _retryOnResume = source;
        // iOS ends the app when a privacy permission is changed in the
        // settings: keep the input so the form comes back filled in.
        await _saveDraft();
        await (widget.openSettings ?? openAppSettings)();
      case null:
        break;
    }
  }

  void _onResume() {
    final source = _retryOnResume;
    _retryOnResume = null;
    if (source != null && mounted) _choosePhoto(source);
  }

  Future<void> _saveDraft() => Prefs.instance.setProblemReportDraft(
    jsonEncode({'name': _name.text, 'phone': _phone.text, 'description': _description.text, 'sendLocation': _sendLocation}),
  );

  /// Restores the input saved before the visitor went to the settings (and
  /// clears it, so a later report starts empty).
  void _restoreDraft() {
    final saved = Prefs.instance.problemReportDraft;
    if (saved == null) return;
    unawaited(Prefs.instance.setProblemReportDraft(null));
    try {
      final draft = jsonDecode(saved) as Map<String, dynamic>;
      _name.text = draft['name'] as String? ?? _name.text;
      _phone.text = draft['phone'] as String? ?? _phone.text;
      _description.text = draft['description'] as String? ?? '';
      _sendLocation = draft['sendLocation'] as bool? ?? false;
    } catch (_) {}
  }

  Future<void> _send() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final position = _sendLocation ? await (widget.currentPosition ?? GeolocationService.instance.currentPosition)() : null;
      final name = _name.text.trim();
      final phone = _phone.text.trim();
      await _api.send(
        name: name,
        description: _description.text.trim(),
        phone: phone.isEmpty ? null : phone,
        latitude: position?.latitude,
        longitude: position?.longitude,
        photo: _photo?.bytes,
        photoName: _photo?.name ?? 'foto.jpg',
      );
      await Prefs.instance.setReporter(name: name, phone: phone);
      await Prefs.instance.setProblemReportDraft(null);
      messenger.showSnackBar(const SnackBar(content: Text('Danke! Deine Meldung ist beim OK eingegangen.')));
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Senden fehlgeschlagen – bitte später erneut versuchen.')));
      if (mounted) setState(() => _sending = false);
    }
  }

  static String? _required(String? value, String message) => (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = _photo;
    return Scaffold(
      appBar: AppBar(title: const Text('Problem melden')),
      body: Form(
        key: _formKey,
        // Not a lazy ListView: Form.validate() only checks fields that are built.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ist dir auf dem Festgelände etwas aufgefallen, das wir beheben sollten – zum Beispiel ein volles WC '
                'oder ungesicherte Kabel? Melde es uns, das OK kümmert sich darum.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Bei Notfällen direkt anrufen: Sanität 144 · Polizei 117 · Feuerwehr 118',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                validator: (v) => _required(v, 'Bitte gib deinen Namen an.'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Telefon (optional)', helperText: 'Für Rückfragen', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 100,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung *',
                  hintText: 'Was ist das Problem und wo genau?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 10,
                maxLength: 4000,
                validator: (v) => _required(v, 'Bitte beschreibe das Problem.'),
              ),
              const SizedBox(height: 8),
              Text('Foto (optional)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (photo != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(photo.bytes, height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    IconButton.filledTonal(tooltip: 'Foto entfernen', icon: const Icon(Icons.close), onPressed: () => setState(() => _photo = null)),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _choosePhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Foto aufnehmen'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _choosePhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Aus Galerie'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Meinen Standort mitsenden'),
                subtitle: const Text('Hilft uns, die Stelle zu finden'),
                value: _sendLocation,
                onChanged: (on) => setState(() => _sendLocation = on),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                label: Text(_sending ? 'Wird gesendet …' : 'Senden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
