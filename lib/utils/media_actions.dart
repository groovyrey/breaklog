import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/index.dart';
import '../models/media.dart';

/// Opens an attachment: local photos in the viewer, local clips in the player,
/// remote values in the browser.
void openMedia(BuildContext context, MoveMedia media) {
  if (media.isRemote) {
    launchUrl(Uri.parse(media.value), mode: LaunchMode.externalApplication);
    return;
  }
  switch (media.kind) {
    case MediaKind.photo:
      showBrkImageViewer(context, media.value);
    case MediaKind.video:
    case MediaKind.record:
      showBrkVideoViewer(context, media.value);
    case MediaKind.link:
      break;
  }
}
