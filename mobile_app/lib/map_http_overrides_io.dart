import 'dart:io';

void installMapHttpOverrides() {
  HttpOverrides.global = _MapHttpOverrides();
}

/// OSM tile hosts reject clients with an empty or generic User-Agent.
class _MapHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.userAgent =
        'Drishti/1.0 (com.sih.audit.sih_inspector_app; SIH prototype; contact=sih@local)';
    client.idleTimeout = const Duration(seconds: 15);
    return client;
  }
}
