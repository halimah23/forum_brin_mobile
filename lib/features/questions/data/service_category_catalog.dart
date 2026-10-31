import '../models/service_category_model.dart';

class ServiceCategoryCatalog {
  static const List<ServiceCategoryModel> defaultCategories = [
    ServiceCategoryModel(
      id: 1,
      nama: 'Kehadiran',
      kode: 'KEHADIRAN',
      deskripsi: 'Presensi, absensi, cuti, dinas luar, dan jam kerja pegawai',
      sortOrder: 1,
    ),
    ServiceCategoryModel(
      id: 2,
      nama: 'Mutasi Unit',
      kode: 'MUTASI_UNIT',
      deskripsi: 'Perpindahan penempatan kerja antar unit / satuan kerja di BRIN',
      sortOrder: 2,
    ),
    ServiceCategoryModel(
      id: 3,
      nama: 'Mutasi Jabatan',
      kode: 'MUTASI_JABATAN',
      deskripsi: 'Pengalihan, pelantikan, penugasan, atau pergeseran jabatan',
      sortOrder: 3,
    ),
    ServiceCategoryModel(
      id: 4,
      nama: 'Mutasi Golongan',
      kode: 'MUTASI_GOLONGAN',
      deskripsi: 'Kenaikan pangkat dan penyesuaian ijazah / golongan ruang',
      sortOrder: 4,
    ),
    ServiceCategoryModel(
      id: 5,
      nama: 'Talenta',
      kode: 'TALENTA',
      deskripsi: 'Manajemen talenta, pemetaan suksesi, penilaian potensi dan kinerja',
      sortOrder: 5,
    ),
    ServiceCategoryModel(
      id: 6,
      nama: 'Disiplin',
      kode: 'DISIPLIN',
      deskripsi: 'Penegakan disiplin ASN, kode etik, sanksi, dan pemeriksaan integritas',
      sortOrder: 6,
    ),
    ServiceCategoryModel(
      id: 7,
      nama: 'Ukom',
      kode: 'UKOM',
      deskripsi: 'Uji kompetensi perpindahan jabatan fungsional atau jenjang karir',
      sortOrder: 7,
    ),
    ServiceCategoryModel(
      id: 8,
      nama: 'KGB',
      kode: 'KGB',
      deskripsi: 'Kenaikan Gaji Berkala pegawai berkala 2 tahunan',
      sortOrder: 8,
    ),
    ServiceCategoryModel(
      id: 9,
      nama: 'Lainnya',
      kode: 'LAINNYA',
      deskripsi: 'Layanan kepegawaian umum atau pertanyaan yang belum tercantum spesifik',
      sortOrder: 9,
    ),
  ];
}
