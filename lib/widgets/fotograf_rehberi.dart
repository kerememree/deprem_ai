import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// Bina fotoğrafı çekerken nasıl çekilmesi gerektiğini
/// adım adım gösteren modal rehber.
///
/// Kullanım:
///   FotografRehberi.goster(context);
class FotografRehberi {
  static void goster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FotografRehberiSheet(),
    );
  }
}

class _FotografRehberiSheet extends StatefulWidget {
  const _FotografRehberiSheet();

  @override
  State<_FotografRehberiSheet> createState() => _FotografRehberiSheetState();
}

class _FotografRehberiSheetState extends State<_FotografRehberiSheet> {
  final PageController _ctrl = PageController();
  int _sayfa = 0;

  List<_RehberAdim> _buildAdimlar() => [
    _RehberAdim(
      ikon: Icons.home_outlined,
      renkHex: 0xFF1565C0,
      baslik: t('guide_s1_title'),
      altBaslik: t('guide_s1_sub'),
      maddeler: [
        t('guide_s1_m1'),
        t('guide_s1_m2'),
        t('guide_s1_m3'),
        t('guide_s1_m4'),
        t('guide_s1_m5'),
      ],
      ikonlar: [
        Icons.photo_camera,
        Icons.rotate_90_degrees_ccw,
        Icons.wb_cloudy_outlined,
        Icons.straighten,
        Icons.crop_free,
      ],
      ipucu: t('guide_s1_tip'),
    ),
    _RehberAdim(
      ikon: Icons.foundation,
      renkHex: 0xFFB71C1C,
      baslik: t('guide_s2_title'),
      altBaslik: t('guide_s2_sub'),
      maddeler: [
        t('guide_s2_m1'),
        t('guide_s2_m2'),
        t('guide_s2_m3'),
        t('guide_s2_m4'),
        t('guide_s2_m5'),
      ],
      ikonlar: [
        Icons.view_column,
        Icons.zoom_in,
        Icons.circle_outlined,
        Icons.crop_rotate,
        Icons.layers,
      ],
      ipucu: t('guide_s2_tip'),
    ),
    _RehberAdim(
      ikon: Icons.meeting_room_outlined,
      renkHex: 0xFF1B5E20,
      baslik: t('guide_s3_title'),
      altBaslik: t('guide_s3_sub'),
      maddeler: [
        t('guide_s3_m1'),
        t('guide_s3_m2'),
        t('guide_s3_m3'),
        t('guide_s3_m4'),
        t('guide_s3_m5'),
      ],
      ikonlar: [
        Icons.crop_landscape,
        Icons.window,
        Icons.vertical_align_top,
        Icons.horizontal_rule,
        Icons.water_drop_outlined,
      ],
      ipucu: t('guide_s3_tip'),
    ),
    _RehberAdim(
      ikon: Icons.stairs,
      renkHex: 0xFF4A148C,
      baslik: t('guide_s4_title'),
      altBaslik: t('guide_s4_sub'),
      maddeler: [
        t('guide_s4_m1'),
        t('guide_s4_m2'),
        t('guide_s4_m3'),
        t('guide_s4_m4'),
        t('guide_s4_m5'),
      ],
      ikonlar: [
        Icons.format_list_numbered,
        Icons.linear_scale,
        Icons.elevator,
        Icons.emergency_outlined,
        Icons.open_in_full,
      ],
      ipucu: t('guide_s4_tip'),
    ),
    _RehberAdim(
      ikon: Icons.check_circle_outline,
      renkHex: 0xFF006064,
      baslik: t('guide_s5_title'),
      altBaslik: t('guide_s5_sub'),
      maddeler: [
        t('guide_s5_m1'),
        t('guide_s5_m2'),
        t('guide_s5_m3'),
        t('guide_s5_m4'),
        t('guide_s5_m5'),
      ],
      ikonlar: [
        Icons.photo_library_outlined,
        Icons.center_focus_strong,
        Icons.brightness_medium,
        Icons.dashboard_outlined,
        Icons.data_usage,
      ],
      ipucu: t('guide_s5_tip'),
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adimlar = _buildAdimlar();
    final adim = adimlar[_sayfa];
    final renk = Color(adim.renkHex);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Tutamaç
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2)),
          ),

          // Üst başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: renk.withOpacity(0.12),
                  shape: BoxShape.circle),
                child: Icon(Icons.photo_camera_outlined, color: renk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('guide_title'),
                      style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(t('guide_subtitle'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
            ]),
          ),

          // Adım indikatörü
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(adimlar.length, (i) {
                final aktif = i == _sayfa;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: aktif ? 5 : 3,
                    decoration: BoxDecoration(
                      color: aktif ? renk : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_sayfa + 1} / ${adimlar.length}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),

          // Sayfa içeriği
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _sayfa = i),
              itemCount: adimlar.length,
              itemBuilder: (_, i) => _AdimSayfasi(
                adim: adimlar[i],
                scrollCtrl: scrollCtrl,
              ),
            ),
          ),

          // Alt navigasyon
          Padding(
            padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Row(children: [
              if (_sayfa > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _ctrl.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(t('guide_prev')),
                  ),
                ),
              if (_sayfa > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_sayfa < adimlar.length - 1) {
                      _ctrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    _sayfa < adimlar.length - 1
                        ? Icons.arrow_forward
                        : Icons.check,
                    size: 16),
                  label: Text(_sayfa < adimlar.length - 1
                    ? t('guide_next')
                    : t('guide_start')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: renk,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AdimSayfasi extends StatelessWidget {
  final _RehberAdim adim;
  final ScrollController scrollCtrl;

  const _AdimSayfasi({required this.adim, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    final renk = Color(adim.renkHex);

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      children: [
        // Başlık kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [renk, renk.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle),
              child: Icon(adim.ikon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(adim.baslik, style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(adim.altBaslik, style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Maddeler
        ...List.generate(adim.maddeler.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: renk.withOpacity(0.1),
                shape: BoxShape.circle),
              child: Icon(adim.ikonlar[i], color: renk, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(adim.maddeler[i],
                  style: const TextStyle(fontSize: 14, height: 1.4)),
              ),
            ),
          ]),
        )),

        const SizedBox(height: 8),

        // İpucu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: renk.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: renk.withOpacity(0.25))),
          child: Text(adim.ipucu,
            style: TextStyle(
              fontSize: 13, color: renk,
              fontWeight: FontWeight.w500, height: 1.4)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Veri sınıfı ─────────────────────────────────────────────────────────────

class _RehberAdim {
  final IconData ikon;
  final int renkHex;
  final String baslik;
  final String altBaslik;
  final List<String> maddeler;
  final List<IconData> ikonlar;
  final String ipucu;

  const _RehberAdim({
    required this.ikon,
    required this.renkHex,
    required this.baslik,
    required this.altBaslik,
    required this.maddeler,
    required this.ikonlar,
    required this.ipucu,
  });
}
