extension RemoveHtmlTagsExtension on String {
  String removeHtmlTags() {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String removeHtmlTagsAndClean() {
    return removeHtmlTags().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String stripHtmlTags() {
    return replaceAll(
      RegExp(r'<[^>]*>|&[^;]+;'),
      ' ',
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
