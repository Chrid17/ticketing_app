/// Named routes used with GetX navigation (also become URLs on the web).
class Routes {
  static const home = '/';
  static const newTicket = '/new-ticket';
  static String ticket(String id) => '/ticket/$id';
  static String editTicket(String id) => '/ticket/$id/edit';
}
