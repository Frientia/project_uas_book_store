import 'package:book_store/core/services/secure_storage.dart';
import 'package:book_store/features/dashboard/data/models/profile_model.dart';
import 'package:book_store/features/dashboard/domain/repositories/profile_repository.dart';
import 'package:flutter/material.dart';

enum ProfileState { idle, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository repository;

  ProfileProvider({required this.repository});

  ProfileState _state = ProfileState.idle;
  ProfileState get state => _state;

  ProfileModel? _profile;
  ProfileModel? get profile => _profile;

  String? _error;
  String? get error => _error;

  Future<void> loadProfile() async {
    _state = ProfileState.loading;
    notifyListeners();

    try {
      _profile = await repository.fetchProfile();
      _state = ProfileState.loaded;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = ProfileState.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await SecureStorageService.clearAll(); 
    _profile = null;
    _state = ProfileState.idle;
    notifyListeners();
  }
}