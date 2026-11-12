/// The API version each public endpoint is pinned to.
///
/// The backend versions its resources independently — `/api/v2/attraction` can
/// exist next to `/api/v1/news` — so only the constant whose contract actually
/// broke moves; the rest stay where they are.
///
/// This matters more here than on the website: a released build keeps calling
/// the versions it was compiled against for as long as it stays installed, so
/// the old version has to remain available until that build is gone. Bumping a
/// constant here only ever affects the *next* release.
abstract final class ApiPaths {
  static const String attraction = '/api/v1/attraction';
  static const String faq = '/api/v1/faq';
  static const String location = '/api/v1/location';
  static const String meetup = '/api/v1/meetup';
  static const String message = '/api/v1/message';
  static const String news = '/api/v1/news';
  static const String ok = '/api/v1/ok';
  static const String programm = '/api/v1/programm';
  static const String pushRegister = '/api/v1/push/register';
  static const String sponsoring = '/api/v1/sponsoring';
}
