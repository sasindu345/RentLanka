const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5021',
);

/// Turns API-relative paths (`/uploads/...`) into full URLs for local dev storage.
String resolveMediaUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  final base = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;
  return url.startsWith('/') ? '$base$url' : '$base/$url';
}

const List<String> categories = [
  'Photography',
  'Tools',
  'Camping',
  'Electronics',
  'Sports',
  'Other',
];

const List<String> districts = [
  'Colombo',
  'Gampaha',
  'Kalutara',
  'Kandy',
  'Galle',
  'Matara',
  'Jaffna',
  'Negombo',
];
