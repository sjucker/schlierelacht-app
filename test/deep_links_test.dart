// Website paths → app screens (App Links / Universal Links). Paths the app does
// not claim must map to null so they keep opening in the browser.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/screens/attraction_detail_screen.dart';
import 'package:schlierelacht_app/screens/festplan_screen.dart';
import 'package:schlierelacht_app/screens/jahrgangstreffen_screen.dart';
import 'package:schlierelacht_app/screens/location_detail_screen.dart';
import 'package:schlierelacht_app/screens/news_detail_screen.dart';
import 'package:schlierelacht_app/screens/programm_screen.dart';
import 'package:schlierelacht_app/utils/deep_links.dart';

void main() {
  test('claimed website paths map to their screens', () {
    expect(deepLinkPage('/programm'), isA<ProgrammScreen>());
    expect(deepLinkPage('/programm/'), isA<ProgrammScreen>(), reason: 'trailing slash');

    final act = deepLinkPage('/programm/A12') as AttractionDetailScreen;
    expect(act.externalId, 'A12');
    expect(act.section, AttractionSection.programm);

    final stand = deepLinkPage('/gastro/G3/') as AttractionDetailScreen;
    expect(stand.externalId, 'G3');
    expect(stand.section, AttractionSection.gastro);

    expect((deepLinkPage('/news/42') as NewsDetailScreen).newsId, 42);
    expect(deepLinkPage('/news'), isA<Scaffold>());
    expect((deepLinkPage('/locations/L1') as LocationDetailScreen).externalId, 'L1');
    expect(deepLinkPage('/festplan?x=1'), isA<FestplanScreen>(), reason: 'query ignored');
    expect(deepLinkPage('/jahrgangstreffen/liste'), isA<JahrgangstreffenScreen>());
  });

  test('push routes may omit the slash or be a full website URL', () {
    expect(deepLinkPage('news'), isA<Scaffold>(), reason: 'the admin hint suggests "news"');
    expect((deepLinkPage('programm/A12') as AttractionDetailScreen).externalId, 'A12');
    expect((deepLinkPage('https://schlierelacht.ch/news/7') as NewsDetailScreen).newsId, 7);
  });

  test('unclaimed or malformed paths map to null', () {
    expect(deepLinkPage('/jahrgangstreffen'), isNull, reason: 'registration stays on the website');
    expect(deepLinkPage('/datenschutz'), isNull);
    expect(deepLinkPage('/locations'), isNull, reason: 'the app has no locations list');
    expect(deepLinkPage('/news/abc'), isNull);
    expect(deepLinkPage('/'), isNull);
    expect(deepLinkPage(null), isNull);
  });
}
