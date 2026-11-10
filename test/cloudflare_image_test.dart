// Cloudflare images are requested at the size they are shown, in WebP.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schlierelacht_app/config.dart';
import 'package:schlierelacht_app/widgets/cloudflare_image.dart';

const _base = 'https://imagedelivery.net/08WjJu0y_NwzY_GFS74XCw/abc';

void main() {
  test('URL: public without a size, a flexible variant with one', () {
    expect(cloudflareImageUrl('abc'), '$_base/public');
    expect(cloudflareImageUrl('abc', width: 300, height: 300, cover: true), '$_base/w=300,h=300,fit=cover,quality=80');
    expect(cloudflareImageUrl('abc', width: 600), '$_base/w=600,fit=scale-down,quality=80');
  });

  test('sizes round up to physical pixels in steps of 100, within 100..2000', () {
    expect(cloudflareSize(96, 3), 300);
    expect(cloudflareSize(96, 2.75), 300, reason: '264 px rounds up');
    expect(cloudflareSize(20, 1), 100);
    expect(cloudflareSize(1000, 3), 2000);
  });

  Future<CachedNetworkImage> pump(WidgetTester tester, Widget image, {double dpr = 3}) async {
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: image)));
    return tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
  }

  testWidgets('a thumbnail asks for its box, cropped, in WebP', (tester) async {
    final image = await pump(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 96, height: 96, child: CloudflareImage(cloudflareId: 'abc')),
      ),
    );
    expect(image.imageUrl, '$_base/w=300,h=300,fit=cover,quality=80');
    expect(image.httpHeaders, cloudflareImageHeaders);
  });

  testWidgets('a contained logo is scaled down, not cropped', (tester) async {
    final image = await pump(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 160,
          height: 80,
          child: CloudflareImage(cloudflareId: 'abc', fit: BoxFit.contain),
        ),
      ),
      dpr: 2,
    );
    expect(image.imageUrl, '$_base/w=400,h=200,fit=scale-down,quality=80');
  });

  testWidgets('a full-width detail image keeps the public variant', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    final image = await pump(tester, ListView(children: const [CloudflareImage(cloudflareId: 'abc', natural: true)]));
    expect(image.imageUrl, '$_base/public', reason: '1200 physical px is about public size; re-encoding saves nothing');
    expect(image.httpHeaders, cloudflareImageHeaders, reason: 'still WebP');
  });

  testWidgets('a narrow natural image asks for its width only', (tester) async {
    final image = await pump(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 250, child: CloudflareImage(cloudflareId: 'abc', natural: true)),
      ),
      dpr: 2,
    );
    expect(image.imageUrl, '$_base/w=500,fit=scale-down,quality=80');
  });
}
