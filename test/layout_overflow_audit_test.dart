import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/widgets/question_card.dart';
import 'package:forum_brin_mobile/features/dashboard/widgets/audit_question_card.dart';
import 'package:forum_brin_mobile/features/questions/widgets/ticket_timeline_tracker.dart';
import 'package:forum_brin_mobile/features/questions/widgets/forum_discussion_card.dart';
import 'package:forum_brin_mobile/features/questions/screens/question_detail_screen.dart';
import 'package:forum_brin_mobile/features/auth/screens/login_screen.dart';
import 'package:forum_brin_mobile/features/auth/cubits/auth_cubit.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  final testUser = UserModel(
    id: 'usr_pegawai_1',
    name: 'Fathurrahman Adam Rahadian',
    email: 'fathurrahman@brin.go.id',
    role: 'member',
    unit: 'Direktorat Pengelolaan Fasilitas Riset',
    tim: 'Pengelolaan Lab Riset Fisika',
    jabatan: 'Analis Kebijakan Ahli Muda',
    lksdm: 'LKSDM KAWASAN BANDUNG',
  );

  final sampleQuestion = QuestionModel(
    id: 31,
    ticketNumber: 'TKT-2026-00031',
    judul: 'Kendala Pengajuan Angka Kredit dan Integrasi Penilaian SKP Tahunan',
    isi: 'Apakah pengajuan PAK terintegrasi sudah diverifikasi oleh tim penilai pusat LKSDM?',
    status: 'waiting_user', // Menunggu Konfirmasi Pegawai
    assignedTo: 'Maria Fernanda De Vega',
    isPublic: true,
    originalJudul: 'Teks asli pegawai judul awal',
    originalIsi: 'Teks asli pegawai isi awal',
    lksdmKawasan: 'LKSDM KAWASAN BANDUNG',
    targetTim: 'Perencanaan dan Pengembangan Karir SDM',
    targetTimPusat: 'Perencanaan dan Pengembangan Karir SDM',
    createdAt: DateTime.now().subtract(const Duration(hours: 36)).toIso8601String(),
    user: testUser,
  );

  testWidgets('Test QuestionCard on 360px device without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: QuestionCard(
              question: sampleQuestion,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('TKT-2026-00031'), findsOneWidget);
  });

  testWidgets('Test TicketTimelineTracker on 360px device without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TicketTimelineTracker(
              question: sampleQuestion,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Perjalanan Tiket & SLA'), findsOneWidget);
  });

  testWidgets('Test AuditQuestionCard on 360px device without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AuditQuestionCard(
              question: sampleQuestion,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('TKT-2026-00031'), findsOneWidget);
  });

  testWidgets('Test ForumDiscussionCard on 360px device without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ForumDiscussionCard(
              question: sampleQuestion,
              onTap: () {},
              onTogglePin: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Telah Dibakukan'), findsOneWidget);
  });

  testWidgets('Test LoginScreen on 360px device without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AuthCubit(),
          child: const LoginScreen(),
        ),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Test QuestionDetailScreen on 360px device without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QuestionDetailScreen(
          question: sampleQuestion,
          currentUser: testUser,
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(QuestionDetailScreen), findsOneWidget);
  });
}
