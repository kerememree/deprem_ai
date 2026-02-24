import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tespit.dart';
import '../l10n/app_strings.dart';

class FotografListesi extends StatelessWidget {
  final List<File> fotograflar;
  final Function(int) onRemove;
  final List<Tespit>? tespitler; // Opsiyonel: Tespitler (fotoğraf indekslerine göre)

  const FotografListesi({
    super.key,
    required this.fotograflar,
    required this.onRemove,
    this.tespitler,
  });

  /// Tam ekran fotoğraf önizleme (pinch-to-zoom destekli)
  void _tamEkranGoster(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            '${t("photo_preview")} #${index + 1} / ${fotograflar.length}',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: t('delete'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _silOnayla(context, index);
              },
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(
              fotograflar[index],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// Silme onay dialogu
  void _silOnayla(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_photo_title')),
        content: Text(t('delete_photo_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t('cancel')),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(t('delete')),
            onPressed: () {
              Navigator.of(ctx).pop();
              onRemove(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (fotograflar.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fotograflar.length,
        itemBuilder: (context, index) {
          // Bu fotoğrafa ait tespitleri bul
          final buFotograflaIlgiliTespitler = tespitler
                  ?.where((t) => t.fotografIndeksi == index)
                  .toList() ??
              [];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              // Fotoğrafa tıklanınca tam ekran önizleme aç
              onTap: () => _tamEkranGoster(context, index),
              child: Stack(
                children: [
                  // Fotoğraf küçük resmi
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      fotograflar[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Büyüt ikonu (orta üst kısım)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Tespit var mı göster
                  if (buFotograflaIlgiliTespitler.isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${buFotograflaIlgiliTespitler.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Sil butonu — onay dialogu ile
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _silOnayla(context, index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Fotoğraf numarası
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
