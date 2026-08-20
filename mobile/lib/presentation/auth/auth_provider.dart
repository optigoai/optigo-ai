import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/models/business_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/business_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AppAuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo;
  final BusinessRepository _bizRepo;

  AuthStatus _status = AuthStatus.unauthenticated;
  UserModel? _user;
  BusinessModel? _currentBusiness;
  List<BusinessModel> _businesses = [];
  String? _errorMessage;

  AppAuthProvider(this._authRepo, this._bizRepo);

  AuthStatus get status => _status;
  UserModel? get user => _user;
  BusinessModel? get currentBusiness => _currentBusiness;
  List<BusinessModel> get businesses => _businesses;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final token = await _authRepo.getSavedAccessToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _user = await _authRepo.getMe();
      await _loadBusinesses();
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.login(email: email, password: password);
      _user = result['user'] as UserModel;
      await _loadBusinesses();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    required String organizationName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.signup(
        email: email,
        password: password,
        fullName: fullName,
        organizationName: organizationName,
      );
      _user = result['user'] as UserModel;
      await _loadBusinesses();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _user = null;
    _currentBusiness = null;
    _businesses = [];
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _loadBusinesses() async {
    try {
      _businesses = await _bizRepo.getBusinesses();
      if (_businesses.isNotEmpty) {
        _currentBusiness = _businesses.first;
      }
    } catch (_) {}
  }

  Future<BusinessModel?> createBusinessAndOnboard({
    required String name,
    String? category,
    String? location,
    String? website,
    String? phone,
    String? description,
    required String targetCustomers,
    required String services,
    required String businessGoals,
    required String marketingChannels,
  }) async {
    _errorMessage = null;
    try {
      final newBiz = await _bizRepo.createBusiness(
        name: name,
        category: category,
        location: location,
        website: website,
        phone: phone,
        description: description,
      );

      final onboarded = await _bizRepo.submitOnboarding(
        businessId: newBiz.id,
        targetCustomers: targetCustomers,
        services: services,
        businessGoals: businessGoals,
        marketingChannels: marketingChannels,
      );

      _currentBusiness = onboarded;
      _businesses = [onboarded, ..._businesses];
      notifyListeners();
      return onboarded;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
