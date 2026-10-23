/// Countdown and setup labels in the app's plain style: `0:30`, not `00:30`.
String clockLabel(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final rest = safe % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

/// A rough session length such as `8m 30s`, used before starting so the user
/// knows what they are committing to.
String sessionLengthLabel(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  if (safe < 60) return '${safe}s';
  final minutes = safe ~/ 60;
  final rest = safe % 60;
  return rest == 0 ? '${minutes}m' : '${minutes}m ${rest}s';
}
