String generateErrorSvg(String message, {String? subMessage}) {
  final escapedMessage = message.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  final escapedSub = subMessage?.replaceAll('<', '&lt;').replaceAll('>', '&gt;') ?? '';

  return '''
<svg width="400" height="200" xmlns="http://www.w3.org/2000/svg">
  <rect width="100%" height="100%" fill="#f0f0f0"/>
  <text x="50%" y="50%" font-family="monospace" font-size="14" fill="red" text-anchor="middle" dy=".3em">
    $escapedMessage
  </text>
  ${subMessage != null ? '''
  <text x="50%" y="70%" font-family="monospace" font-size="12" fill="#555" text-anchor="middle" dy=".3em">
    $escapedSub
  </text>
  ''' : ''}
</svg>
''';
}
