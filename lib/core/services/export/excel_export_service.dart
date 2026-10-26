import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../features/dashboard/services/performance_analytics_service.dart';
import '../../../features/questions/models/question_model.dart';

class ExcelExportService {
  /// Ekspor daftar rekapitulasi leaderboard seluruh petugas ke file Excel (.xlsx)
  static Future<String> exportStaffLeaderboardToExcel(
    List<StaffPerformanceStat> staffList, {
    String? teamFilter,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Leaderboard Kinerja';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 1. Judul & Informasi Header
    sheet.appendRow([
      TextCellValue('LEADERBOARD KINERJA PETUGAS & STAF ADMIN - BOSDM CONNECT BRIN'),
    ]);
    sheet.appendRow([
      TextCellValue('Tanggal Unduh: $formattedDate | Filter Tim: ${teamFilter ?? "Semua Tim"} | Total Petugas: ${staffList.length}'),
    ]);
    sheet.appendRow([TextCellValue('')]); // Baris kosong

    // 2. Baris Header Kolom
    final headers = [
      TextCellValue('Peringkat'),
      TextCellValue('Nama Petugas'),
      TextCellValue('Peran / Jabatan'),
      TextCellValue('Tim / Kawasan'),
      TextCellValue('Total Tiket Ditangani'),
      TextCellValue('Tiket Selesai'),
      TextCellValue('Rata-rata Rating CSAT'),
      TextCellValue('Total Ulasan'),
      TextCellValue('Respon Cepat (<=2 Jam)'),
      TextCellValue('Persentase Gercep'),
      TextCellValue('Total Jawaban Balasan'),
    ];
    sheet.appendRow(headers);

    // Styling baris header
    final headerRowIdx = 3;
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.grey200,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIdx)).cellStyle = headerStyle;
    }

    // 3. Isi Data Baris
    for (int i = 0; i < staffList.length; i++) {
      final staff = staffList[i];
      final row = [
        IntCellValue(i + 1),
        TextCellValue(staff.name),
        TextCellValue(staff.role),
        TextCellValue(staff.teamOrLksdm),
        IntCellValue(staff.ticketsHandledCount),
        IntCellValue(staff.ticketIdsHandled.length),
        DoubleCellValue(double.parse(staff.averageRating.toStringAsFixed(2))),
        IntCellValue(staff.ratingCount),
        IntCellValue(staff.gercepCount),
        TextCellValue('${(staff.gercepRate * 100).toStringAsFixed(0)}%'),
        IntCellValue(staff.answerCount),
      ];
      sheet.appendRow(row);
    }

    // 4. Simpan ke File Lokal
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final fileName = 'Laporan_Kinerja_Petugas_BOSDM_$timestamp.xlsx';

    return await _saveAndGetPath(excel, fileName);
  }

  /// Ekspor rincian tiket yang ditangani oleh staf tertentu ke file Excel (.xlsx)
  static Future<String> exportStaffTicketHistoryToExcel({
    required StaffPerformanceStat staff,
    required List<QuestionModel> tickets,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Riwayat Tiket';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 1. Header Informasi Staf
    sheet.appendRow([
      TextCellValue('LAPORAN RINCIAN KINERJA PETUGAS - BOSDM CONNECT BRIN'),
    ]);
    sheet.appendRow([
      TextCellValue('Nama Petugas: ${staff.name} | Peran: ${staff.role} | Tim/Kawasan: ${staff.teamOrLksdm}'),
    ]);
    sheet.appendRow([
      TextCellValue('Tiket Ditangani: ${staff.ticketsHandledCount} | CSAT Rata-rata: ${staff.averageRating.toStringAsFixed(2)} / 5.0 | Respon Cepat: ${staff.gercepCount} | Tanggal Unduh: $formattedDate'),
    ]);
    sheet.appendRow([TextCellValue('')]); // Baris kosong

    // 2. Baris Header Kolom
    final headers = [
      TextCellValue('No'),
      TextCellValue('No. Tiket'),
      TextCellValue('Judul Pertanyaan'),
      TextCellValue('Tugas & Fungsi (Tusi)'),
      TextCellValue('Kawasan / Asal Pemohon'),
      TextCellValue('Tanggal Masuk'),
      TextCellValue('Tanggal Selesai'),
      TextCellValue('Status Tiket'),
      TextCellValue('Rating CSAT'),
      TextCellValue('Ulasan / Feedback Pegawai'),
    ];
    sheet.appendRow(headers);

    final headerRowIdx = 4;
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.grey200,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIdx)).cellStyle = headerStyle;
    }

    // 3. Isi Data Tiket yang Ditangani Staf
    final staffTickets = tickets.where((q) {
      if (q.id != null && staff.ticketIdsHandled.contains(q.id)) return true;
      final answers = q.answers ?? [];
      return answers.any((a) => a.penjawabNama.trim().toLowerCase() == staff.name.trim().toLowerCase());
    }).toList();

    for (int i = 0; i < staffTickets.length; i++) {
      final q = staffTickets[i];
      final row = [
        IntCellValue(i + 1),
        TextCellValue(q.ticketNumber ?? 'TKT-${q.id ?? i + 1}'),
        TextCellValue(q.judul),
        TextCellValue(q.tugasFungsiNama ?? '-'),
        TextCellValue(q.lksdmKawasan ?? q.authorAsalLksdm),
        TextCellValue(q.createdAt != null ? _formatDateTime(q.createdAt!) : '-'),
        TextCellValue(q.resolvedAt != null ? _formatDateTime(q.resolvedAt!) : (q.isClosed ? 'Selesai' : '-')),
        TextCellValue(q.ticketStatus.label),
        q.rating != null ? IntCellValue(q.rating!) : TextCellValue('-'),
        TextCellValue(q.ratingFeedback ?? '-'),
      ];
      sheet.appendRow(row);
    }

    // 4. Simpan ke File Lokal
    final safeName = staff.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final fileName = 'Kinerja_${safeName}_$timestamp.xlsx';

    return await _saveAndGetPath(excel, fileName);
  }

  /// Helper untuk menyimpan berkas Excel ke direktori penyimpanan lokal perangkat
  static Future<String> _saveAndGetPath(Excel excel, String fileName) async {
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Gagal membuat berkas Excel binary.');
    }

    Directory? targetDir;
    try {
      if (Platform.isAndroid) {
        targetDir = await getExternalStorageDirectory();
      }
    } catch (_) {}

    targetDir ??= await getApplicationDocumentsDirectory();

    final filePath = '${targetDir.path}/$fileName';
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    debugPrint('Berkas Excel berhasil disimpan: $filePath');
    return filePath;
  }

  /// Buka berkas Excel menggunakan aplikasi spreadsheet terpasang di perangkat
  static Future<OpenResult> openExportedFile(String filePath) async {
    try {
      return await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint('Error membuka file: $e');
      return OpenResult(type: ResultType.error, message: e.toString());
    }
  }

  static String _formatDateTime(String rawIso) {
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawIso;
    }
  }
}
