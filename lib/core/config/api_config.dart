class ApiConfig {
  /// Direct REST API Endpoint connected to AWS RDS MySQL
  /// Direct Wi-Fi LAN IP accessible by physical phones on local network: http://172.16.1.119:8001
  /// Database Host: database-1.c1o0ygcs2cex.ap-south-1.rds.amazonaws.com
  /// Database Name: aceassignmenthelp_db
  static const String baseUrl = 'https://ace-assignment-helps-three.vercel.app/';

  static Future<void> init() async {}

  static String get portalApiEndpoint => '$baseUrl/portal_api.php';
}
