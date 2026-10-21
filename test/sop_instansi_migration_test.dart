import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/auth/models/user_role.dart';
import 'package:forum_brin_mobile/features/questions/models/category_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';

void main() {
  group('SOP Instansi Database Model & Migration Tests', () {
    test('UserRole parser correctly identifies Admin Pusat vs Admin LKSDM based on eskalasi', () {
      expect(
        UserRole.fromString('Staff Admin', eskalasi: 'Pusat'),
        UserRole.adminPusat,
      );
      expect(
        UserRole.fromString('Staff Admin', eskalasi: 'LKSDM'),
        UserRole.adminLksdm,
      );
      expect(
        UserRole.fromString('Super Admin'),
        UserRole.superAdmin,
      );
      expect(
        UserRole.fromString('Executive'),
        UserRole.eksekutif,
      );
      expect(
        UserRole.fromString('Ketua Tim'),
        UserRole.ketuaTim,
      );
      expect(
        UserRole.fromString('Member'),
        UserRole.member,
      );
    });

    test('UserModel correctly parses SOP instansi payload with joined teams', () {
      final userJson = {
        'id_user': 'usr_007',
        'first_name': 'Syifaniar Ramadhanny',
        'username': 'syif007',
        'email': 'syifaniar.ramadhanny@brin.go.id',
        'external_email': 'syifaniar.ramadhanny@gmail.com',
        'phone': '081234567890',
        'sex': 'Perempuan',
        'satuan_kerja': 'Biro Organisasi dan Sumber Daya Manusia',
        'id_tim': 'tim_02',
        'kawasan': 'Pusat',
        'jabatan': 'Analis Sumber Daya Manusia Aparatur Ahli Muda',
        'role': 'Staff Admin',
        'teams': {
          'id_tim': 'tim_02',
          'tim': 'Tim PKSPU',
          'detail_nama_tim': 'Tim Perencanaan, Kesejahteraan SDM, Pelayanan Umum dan Keuangan',
          'eskalasi': 'Pusat',
        },
      };

      final user = UserModel.fromJson(userJson);

      expect(user.id, 'usr_007');
      expect(user.name, 'Syifaniar Ramadhanny');
      expect(user.username, 'syif007');
      expect(user.email, 'syifaniar.ramadhanny@brin.go.id');
      expect(user.satuanKerja, 'Biro Organisasi dan Sumber Daya Manusia');
      expect(user.idTim, 'tim_02');
      expect(user.tim, 'Tim PKSPU');
      expect(user.eskalasi, 'Pusat');
      expect(user.userRole, UserRole.adminPusat);
    });

    test('CategoryModel correctly parses tugas_fungsi payload with id_tusi and detail_nama_tim', () {
      final categoryJson = {
        'id_tusi': 'tusi_001',
        'tugas_fungsi': 'Penyusunan Rencana Kebutuhan SDM',
        'detail_nama_tim': 'Tim Perencanaan, Kesejahteraan SDM, Pelayanan Umum dan Keuangan',
      };

      final category = CategoryModel.fromJson(categoryJson);

      expect(category.id, 1);
      expect(category.idTusi, 'tusi_001');
      expect(category.nama, 'Penyusunan Rencana Kebutuhan SDM');
      expect(category.teamName, 'Tim Perencanaan, Kesejahteraan SDM, Pelayanan Umum dan Keuangan');
    });

    test('QuestionModel correctly parses author from users join', () {
      final questionJson = {
        'id': 101,
        'ticket_number': 'TKT-2026-0001',
        'judul': 'Konsultasi Kenaikan Pangkat Ahli Muda',
        'isi': 'Mohon konfirmasi dokumen kelengkapan.',
        'status': 'menunggu_lksdm',
        'is_public': true,
        'users': {
          'id_user': 'usr_240',
          'first_name': 'Manda Talita Taruli Hasibuan',
          'username': 'mand001',
          'email': 'manda.talita.taruli.hasibuan.@brin.go.id',
          'role': 'Member',
          'satuan_kerja': 'Badan Riset dan Inovasi Nasional',
          'teams': {
            'id_tim': 'tim_00',
            'tim': 'Pegawai BRIN',
            'detail_nama_tim': 'Pegawai BRIN (Non-Pengelola BOSDM)',
            'eskalasi': '-',
          },
        },
        'question_tugas_fungsi': [
          {
            'tugas_fungsi': {
              'id_tusi': 'tusi_005',
              'tugas_fungsi': 'Kenaikan Pangkat Jabatan Fungsional',
            }
          }
        ],
      };

      final question = QuestionModel.fromJson(questionJson);

      expect(question.id, 101);
      expect(question.ticketNumber, 'TKT-2026-0001');
      expect(question.author?.id, 'usr_240');
      expect(question.author?.name, 'Manda Talita Taruli Hasibuan');
      expect(question.author?.userRole, UserRole.member);
      expect(question.tugasFungsi, isNotEmpty);
      expect(question.tugasFungsi!.first.idTusi, 'tusi_005');
    });

    test('SQL migration file exists and contains all required SOP tables and seed rows', () {
      final sqlFile = File('lib/core/network/supabase_migration_sop_instansi.sql');
      expect(sqlFile.existsSync(), isTrue);

      final content = sqlFile.readAsStringSync();
      expect(content, contains('CREATE TABLE public.teams'));
      expect(content, contains('CREATE TABLE public.tugas_fungsi'));
      expect(content, contains('CREATE TABLE public.team_tusi'));
      expect(content, contains('CREATE TABLE public.users'));
      expect(content, contains('usr_001'));
      expect(content, contains('usr_240'));
      expect(content, contains('tim_022'));
      expect(content, contains('ts_091'));
    });
  });
}
