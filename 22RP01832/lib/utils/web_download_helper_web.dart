// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void triggerWebDownload(String url) {
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = url.split('/').last;
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
