import 'package:intern_link/models/user_model.dart';
import 'package:intern_link/services/json_data_service.dart';

class AuthService {
  static Future<User?> login(String email, String password) async {
    final users = await JsonDataService.loadUsers();
    try {
      return users.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<bool> register(User newUser) async {
    try {
      final users = await JsonDataService.loadUsers();
      
      // Check if email already exists
      if (users.any((user) => user.email == newUser.email)) {
        return false;
      }
      
      users.add(newUser);
      // In a real app, you would save this back to your JSON/database
      return true;
    } catch (e) {
      return false;
    }
  }
}