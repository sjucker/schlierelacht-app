import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../utils/external_links.dart';

/// A static legal page rendered from Markdown — the website's Impressum and
/// Datenschutz (`impressum.vue`, `datenschutz.vue`).
class LegalScreen extends StatelessWidget {
  const LegalScreen._(this.title, this.markdown, {super.key});

  const LegalScreen.impressum({Key? key}) : this._('Impressum', _impressum, key: key);

  const LegalScreen.datenschutz({Key? key}) : this._('Datenschutz', _datenschutz, key: key);

  final String title;
  final String markdown;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Markdown(data: markdown, padding: const EdgeInsets.all(16), onTapLink: (_, href, _) => openUrl(href)),
    );
  }
}

const _impressum = '''
### Inhaltliche Verantwortung

eventSCHLIEREN, Organisation Schlierefäscht 2027
Freiestrasse 6, Stadthaus, 8952 Schlieren

**Geschäftsstelle Schlierefäscht 2027**
Charly Mettier
Kampstrasse 6, 8952 Schlieren
[079 456 79 69](tel:+41794567969)
[info@schlierelacht.ch](mailto:info@schlierelacht.ch)

### Haftungsausschluss

Der Autor übernimmt keinerlei Gewähr hinsichtlich der inhaltlichen Richtigkeit, Genauigkeit, Aktualität, Zuverlässigkeit und Vollständigkeit der Informationen. Haftungsansprüche gegen den Autor wegen Schäden materieller oder immaterieller Art, welche aus dem Zugriff oder der Nutzung bzw. Nichtnutzung der veröffentlichten Informationen, durch Missbrauch der Verbindung oder durch technische Störungen entstanden sind, werden ausgeschlossen. Alle Angebote sind unverbindlich. Der Autor behält es sich ausdrücklich vor, Teile der Seiten oder das gesamte Angebot ohne gesonderte Ankündigung zu verändern, zu ergänzen, zu löschen oder die Veröffentlichung zeitweise oder endgültig einzustellen.

### Haftung für Links

Verweise und Links auf Webseiten Dritter liegen ausserhalb unseres Verantwortungsbereichs. Es wird jegliche Verantwortung für solche Webseiten abgelehnt. Der Zugriff und die Nutzung solcher Webseiten erfolgen auf eigene Gefahr des Nutzers oder der Nutzerin.

### Urheberrechte

Die Urheber- und alle anderen Rechte an Inhalten, Bildern, Fotos oder anderen Dateien auf der Website gehören ausschliesslich dem Verein eventSCHLIEREN/Fototeams Schlierefäscht oder den speziell genannten Rechtsinhabern. Für die Reproduktion jeglicher Elemente ist die schriftliche Zustimmung der Urheberrechtsträger im Voraus einzuholen.
''';

// Mirrors the website's privacy statement verbatim. NOTE: it only covers the
// website — the app's push notifications (Firebase) and location use are not
// described yet; that text has to come from the organizers.
const _datenschutz = '''
Wir freuen uns über Ihren Besuch auf unserer Website schlierelacht.ch. Der Schutz Ihrer persönlichen Daten ist uns ein wichtiges Anliegen. Wir behandeln Ihre personenbezogenen Daten vertraulich und entsprechend der gesetzlichen Datenschutzvorschriften (insbesondere dem Schweizer Datenschutzgesetz, DSG) sowie dieser Datenschutzerklärung.

### Verantwortliche Stelle

**Geschäftsstelle Schlierefäscht 2027**
Charly Mettier
Kampstrasse 6, 8952 Schlieren
[079 456 79 69](tel:+41794567969)
[info@schlierelacht.ch](mailto:info@schlierelacht.ch)

Wenn Sie Fragen zum Datenschutz haben, können Sie sich jederzeit an die oben genannte Adresse wenden.

### Datenerhebung beim "Jahrgangstreffen"

Auf unserer Website bieten wir die Möglichkeit, sich für das Jahrgangstreffen anzumelden oder anderweitig mit uns in Kontakt zu treten. Wenn Sie uns in diesem Rahmen personenbezogene Daten (wie z. B. Name, Adresse, E-Mail-Adresse, Telefonnummer oder Jahrgang) übermitteln, gilt Folgendes:

- Zweckbindung: Diese Daten werden ausschliesslich für die direkte Kommunikation und Organisation im Rahmen des Jahrgangstreffens verwendet.
- Keine Weitergabe: Ihre Daten werden streng vertraulich behandelt und nicht an Dritte weitergegeben, verkauft oder für andere Zwecke entfremdet.
- Aufbewahrung: Die Daten werden nur so lange gespeichert, wie es für die Durchführung und Nachbereitung des Anlasses notwendig ist, es sei denn, gesetzliche Aufbewahrungsfristen erfordern eine längere Speicherung.

### Kein Einsatz von Google Analytics oder Tracking-Tools

Ihre Privatsphäre ist uns wichtig. Daher verzichten wir auf dieser Website bewusst auf den Einsatz von Google Analytics oder vergleichbaren Webanalyse- und Tracking-Tools. Ihr Surfverhalten auf unserer Website wird nicht von uns aufgezeichnet oder für Werbezwecke analysiert.

### Einbindung von MapBox

Zur ansprechenden Darstellung unserer Standortinformationen und zur einfachen Auffindbarkeit der angegebenen Orte nutzen wir auf unserer Website interaktive Karten von MapBox, einem Dienst der Mapbox Inc., 740 15th Street NW, 5th Floor, Washington DC 20005, USA.

Wenn Sie eine Seite aufrufen, die eine MapBox-Karte enthält, baut Ihr Browser eine direkte Verbindung zu den Servern von MapBox auf. Dabei wird Ihre IP-Adresse sowie die Information, dass Sie unsere Website besucht haben, an MapBox übermittelt. Wir haben keinen Einfluss auf diese Datenübertragung. Die Nutzung von MapBox erfolgt im Interesse einer ansprechenden Darstellung unserer Online-Angebote. Weitere Informationen zum Umgang mit Nutzerdaten finden Sie in der Datenschutzerklärung von MapBox: [https://www.mapbox.com/privacy](https://www.mapbox.com/privacy)

### Änderungen dieser Datenschutzerklärung

Wir behalten uns vor, diese Datenschutzerklärung gelegentlich anzupassen, damit sie stets den aktuellen rechtlichen Anforderungen entspricht oder um Änderungen unserer Leistungen in der Datenschutzerklärung umzusetzen (z. B. bei der Einführung neuer Funktionen). Für Ihren erneuten Besuch gilt dann die neue Datenschutzerklärung.

Stand: August 2026
''';
