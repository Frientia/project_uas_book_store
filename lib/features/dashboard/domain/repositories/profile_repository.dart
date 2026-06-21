import 'package:book_store/core/constants/api_constants.dart';
import 'package:book_store/core/services/dio_client.dart';
import 'package:book_store/features/dashboard/data/models/profile_model.dart';
import 'package:dio/dio.dart';

class ProfileRepository {
  Future<ProfileModel> fetchProfile() async {
    try {
      final response = await DioClient.instance.get(ApiConstants.profile);
      
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data') && response.data['data'] != null) {
          return ProfileModel.fromJson(response.data['data']);
        }
        return ProfileModel.fromJson(response.data);
      }
      
      throw Exception('Format respons API tidak sesuai (Bukan JSON Object)');
      
    } on DioException catch (e) {
      String errorMessage = 'Gagal memuat profil';
      
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Endpoint /profile tidak ditemukan (404)';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Terjadi kesalahan parsing: $e');
    }
  }
}