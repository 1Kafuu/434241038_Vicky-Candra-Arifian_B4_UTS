import 'package:flutter/material.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final faqs = [
      {
        'question': 'Bagaimana cara membuat tiket baru?',
        'answer':
            'Untuk membuat tiket baru, navigasi ke menu "Tiket" dan klik tombol "+" atau "Buat Tiket". Isi form yang disediakan termasuk judul, deskripsi, dan lampiran jika diperlukan.',
      },
      {
        'question': 'Bagaimana cara melihat status tiket saya?',
        'answer':
            'Anda dapat melihat semua tiket Anda di menu "Riwayat Tiket". Setiap tiket menampilkan status terkini seperti "Open", "In Progress", atau "Resolved".',
      },
      {
        'question': 'Berapa lama waktu respons untuk tiket?',
        'answer':
            'Waktu respons bervariasi tergantung prioritas tiket. Tiket dengan prioritas tinggi akan direspons lebih cepat oleh tim helpdesk kami.',
      },
      {
        'question': 'Bagaimana cara mengubah tema aplikasi?',
        'answer':
            'Navigasi ke menu Profil, lalu klik ikon pengaturan di header. Anda dapat beralih antara Dark Mode dan Light Mode di sana.',
      },
      {
        'question': 'Apakah saya bisa membatalkan tiket?',
        'answer':
            'Ya, Anda dapat membatalkan tiket yang belum diproses. Buka detail tiket dan pilih opsi "Batalkan Tiket".',
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        title: Text(
          'FAQ',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
            ),
            child: ExpansionTile(
              title: Text(
                faqs[index]['question']!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              iconColor: isDark ? Colors.grey.shade400 : AppColors.primary,
              collapsedIconColor: isDark ? Colors.grey.shade400 : AppColors.primary,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faqs[index]['answer']!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
