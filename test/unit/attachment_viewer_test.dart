import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/features/auth/models/user_model.dart';
import 'package:forum_brin_mobile/features/questions/models/question_model.dart';
import 'package:forum_brin_mobile/features/questions/screens/full_screen_image_viewer.dart';
import 'package:forum_brin_mobile/features/questions/screens/question_detail_screen.dart';
import 'package:forum_brin_mobile/features/questions/widgets/attachment_viewer_helper.dart';

void main() {
  group('AttachmentViewerHelper Unit Tests', () {
    test('isImageFile correctly identifies image formats and documents', () {
      expect(
        AttachmentViewerHelper.isImageFile(
          'https://storage.supabase.co/bucket/questions/foto.jpg',
          'foto.jpg',
        ),
        isTrue,
      );

      expect(
        AttachmentViewerHelper.isImageFile(
          'https://storage.supabase.co/bucket/questions/dokumen',
          'bukti_slip.PNG',
        ),
        isTrue,
      );

      expect(
        AttachmentViewerHelper.isImageFile(
          'https://storage.supabase.co/bucket/questions/sk_pangkat.pdf',
          'sk_pangkat.pdf',
        ),
        isFalse,
      );

      expect(
        AttachmentViewerHelper.isImageFile(
          'https://storage.supabase.co/bucket/questions/laporan.docx',
          'laporan.docx',
        ),
        isFalse,
      );

      expect(
        AttachmentViewerHelper.isImageFile(
          '/data/user/0/cache/123/screenshot.png',
          'screenshot.png',
        ),
        isTrue,
      );
    });

    test('isLocalPath detects local vs cloud storage URLs', () {
      expect(
        AttachmentViewerHelper.isLocalPath('https://twzvyujhymvbupophtjy.supabase.co/storage/v1/object/public/attachments/test.pdf'),
        isFalse,
      );
      expect(
        AttachmentViewerHelper.isLocalPath('http://forum-brin.test/storage/test.png'),
        isFalse,
      );
      expect(
        AttachmentViewerHelper.isLocalPath('/data/user/0/com.example.forum_brin_mobile/cache/test.jpg'),
        isTrue,
      );
      expect(
        AttachmentViewerHelper.isLocalPath('storage://local/document.pdf'),
        isTrue,
      );
    });
  });

  group('FullScreenImageViewer Widget Tests', () {
    testWidgets('Renders app bar, file name, close button, and interactive viewer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FullScreenImageViewer(
            imageUrl: 'https://example.com/sample_image.png',
            fileName: 'Sample_Image.png',
          ),
        ),
      );

      expect(find.text('Sample_Image.png'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.open_in_browser_rounded), findsOneWidget);

      // Verify tapping close pops the viewer
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(FullScreenImageViewer), findsNothing);
    });
  });

  group('QuestionDetailScreen Attachment Bubbles Tests', () {
    const testUser = UserModel(
      id: 'usr_test_1',
      name: 'Dr. Test User',
      email: 'test@brin.go.id',
      role: 'pegawai',
    );

    testWidgets('Renders document attachment bubble with open_in_new icon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final questionWithDoc = QuestionModel(
        id: 991,
        ticketNumber: 'TKT-DOC-991',
        judul: 'Pertanyaan Dokumen PDF',
        isi: 'Berikut dokumen terlampir mohon dicek',
        status: 'menunggu_lksdm',
        rawUserId: 'usr_test_1',
        user: testUser,
        attachmentUrl: 'https://twzvyujhymvbupophtjy.supabase.co/storage/v1/object/public/attachments/questions/sk_pangkat.pdf',
        attachmentName: 'sk_pangkat_terbaru.pdf',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionDetailScreen(
            question: questionWithDoc,
            currentUser: testUser,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('sk_pangkat_terbaru.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.description_rounded), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    });

    testWidgets('Renders image attachment thumbnail in bubble', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final questionWithImg = QuestionModel(
        id: 992,
        ticketNumber: 'TKT-IMG-992',
        judul: 'Pertanyaan Bukti Foto',
        isi: 'Berikut foto kendala sistem',
        status: 'menunggu_lksdm',
        rawUserId: 'usr_test_1',
        user: testUser,
        attachmentUrl: 'https://twzvyujhymvbupophtjy.supabase.co/storage/v1/object/public/attachments/questions/screenshot_error.png',
        attachmentName: 'screenshot_error.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionDetailScreen(
            question: questionWithImg,
            currentUser: testUser,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClipRRect), findsWidgets);
    });
  });
}
