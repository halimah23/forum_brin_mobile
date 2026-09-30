import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/auth/models/user_role.dart';
import 'package:forum_brin_mobile/features/questions/models/category_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';

void main() {
  group('Supabase Model Mapping & Payload Tests', () {
    test('UserModel handles Supabase UUID and profile JSON correctly', () {
      final json = {
        'id': 'b3f5c71d-8e4a-4e2b-91c8-123456789abc',
        'name': 'Budi BRIN',
        'email': 'budi@brin.go.id',
        'role': 'super_admin',
        'unit': 'Direktori IT',
        'tim': 'DevSecOps',
        'jabatan': 'Perekayasa Ahli Muda',
      };

      final user = UserModel.fromJson(json, token: 'mock-jwt-token');

      expect(user.id, 'b3f5c71d-8e4a-4e2b-91c8-123456789abc');
      expect(user.name, 'Budi BRIN');
      expect(user.email, 'budi@brin.go.id');
      expect(user.role, 'super_admin');
      expect(user.userRole, UserRole.superAdmin);
      expect(user.token, 'mock-jwt-token');
    });

    test('UserRole parser handles all 4 role variations correctly', () {
      expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
      expect(UserRole.fromString('Super Admin'), UserRole.superAdmin);

      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('Admin Layanan'), UserRole.admin);

      expect(UserRole.fromString('ketua_tim'), UserRole.ketuaTim);
      expect(UserRole.fromString('Ketua Tim'), UserRole.ketuaTim);

      expect(UserRole.fromString('member'), UserRole.member);
      expect(UserRole.fromString('pegawai'), UserRole.member);
      expect(UserRole.fromString(''), UserRole.member);
      expect(UserRole.fromString(null), UserRole.member);
    });

    test('CategoryModel handles Supabase tugas_fungsi JSON', () {
      final json = {'id': 1, 'nama': 'Pelayanan SDM'};

      final category = CategoryModel.fromJson(json);

      expect(category.id, 1);
      expect(category.nama, 'Pelayanan SDM');
    });

    test('QuestionModel parses Supabase join payload with profiles and question_tugas_fungsi', () {
      final supabaseJoinJson = {
        'id': 101,
        'judul': 'Bagaimana cara pengajuan cuti riset?',
        'isi': 'Mohon informasi alur pengajuan cuti riset untuk tim SDM.',
        'status': 'diajukan',
        'is_public': true,
        'created_at': '2026-09-27T10:00:00Z',
        'profiles': {
          'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'name': 'Dr. Siti',
          'email': 'siti@brin.go.id',
          'role': 'member',
          'unit': 'Pusat Riset AI',
        },
        'question_tugas_fungsi': [
          {
            'tugas_fungsi': {'id': 1, 'nama': 'Pelayanan SDM'}
          },
          {
            'tugas_fungsi': {'id': 2, 'nama': 'Fasilitas Riset'}
          }
        ]
      };

      final question = QuestionModel.fromJson(supabaseJoinJson);

      expect(question.id, 101);
      expect(question.judul, 'Bagaimana cara pengajuan cuti riset?');
      expect(question.user?.name, 'Dr. Siti');
      expect(question.user?.userRole, UserRole.member);
      expect(question.user?.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(question.tugasFungsi?.length, 2);
      expect(question.tugasFungsi?[0].nama, 'Pelayanan SDM');
      expect(question.tugasFungsi?[1].nama, 'Fasilitas Riset');
    });
  });
}
