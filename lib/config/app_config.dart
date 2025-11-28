class AppConfig {
  // Update this URL to match your Laravel backend
  // For local development with XAMPP
   static const String baseUrl = 'http://ticketsystem.local/api';

  //static const String baseUrl = 'https://ticket.caffedesign.in/api';
  
  // For Android emulator, use 10.0.2.2 instead of localhost
  static const String androidBaseUrl = 'http://10.0.2.2/ticketSystem/public/api';
  
  // For physical device, use your computer's IP address
  // Example: static const String deviceBaseUrl = 'http://192.168.1.100/ticketSystem/public/api';
  
  // Get the appropriate URL based on platform
  static String get apiBaseUrl {
    // You can add platform detection here if needed
    // For now, using localhost for simplicity
    return baseUrl;
  }
  
  // API endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String userEndpoint = '/user';
  static const String googleLoginEndpoint = '/auth/google';
  
  // Request timeout in seconds
  static const int requestTimeout = 30;
}






