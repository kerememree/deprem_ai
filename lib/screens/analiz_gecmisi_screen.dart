import 'package:flutter/material.dart';
import '../models/analiz_kaydi.dart';
import '../services/analiz_gecmisi_service.dart';
import '../widgets/risk_karti.dart';
import '../core/exceptions/app_exceptions.dart';
import '../l10n/app_strings.dart';
import 'analiz_karsilastirma_screen.dart';

class AnalizGecmisiScreen extends StatefulWidget {
  const AnalizGecmisiScreen({super.key});

  @override
  State<AnalizGecmisiScreen> createState() => _AnalizGecmisiScreenState();
}

class _AnalizGecmisiScreenState extends State<AnalizGecmisiScreen> {
  List<AnalizKaydi> _tumAnalizler = [];
  List<AnalizKaydi> _filtreliAnalizler = [];
  bool _yukleniyor = true;
  String? _hataMesaji;

  // ── Arama & Filtre ────────────────────────────────────────────────────────
  final _aramaCtrl = TextEditingController();
  String _riskFiltresi = 'all';   // all | high | medium | low
  String _siralama    = 'date';   // date | risk
  bool _aramaAcik     = false;

  @override
  void initState() {
    super.initState();
    _analizleriYukle();
    _aramaCtrl.addListener(_filtreUygula);
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  // ── Veri yükleme ──────────────────────────────────────────────────────────

  Future<void> _analizleriYukle() async {
    setState(() { _yukleniyor = true; _hataMesaji = null; });
    try {
      final analizler = await AnalizGecmisiService.tumAnalizleriGetir();
      if (mounted) {
        setState(() {
          _tumAnalizler = analizler;
          _yukleniyor = false;
        });
        _filtreUygula();
      }
    } on AppException catch (e) {
      if (mounted) setState(() { _hataMesaji = e.userMessage; _yukleniyor = false; });
    } catch (e) {
      if (mounted) setState(() { _hataMesaji = t('history_load_error'); _yukleniyor = false; });
    }
  }

  // ── Filtre & Arama ────────────────────────────────────────────────────────

  void _filtreUygula() {
    final arama = _aramaCtrl.text.trim().toLowerCase();

    var liste = _tumAnalizler.where((a) {
      // Risk filtresi
      if (_riskFiltresi == 'high'   && a.analiz.riskSkoru <= 6) return false;
      if (_riskFiltresi == 'medium' && (a.analiz.riskSkoru <= 3 || a.analiz.riskSkoru > 6)) return false;
      if (_riskFiltresi == 'low'    && a.analiz.riskSkoru > 3) return false;

      // Arama
      if (arama.isNotEmpty) {
        final isimEslese = a.gosterilecekIsim.toLowerCase().contains(arama);
        final tarihEslese = a.tamTarih.contains(arama);
        if (!isimEslese && !tarihEslese) return false;
      }
      return true;
    }).toList();

    // Sıralama
    if (_siralama == 'date') {
      liste.sort((a, b) => b.tarih.compareTo(a.tarih));
    } else {
      liste.sort((a, b) => b.analiz.riskSkoru.compareTo(a.analiz.riskSkoru));
    }

    setState(() => _filtreliAnalizler = liste);
  }

  // ── Silme ─────────────────────────────────────────────────────────────────

  Future<void> _analizSil(AnalizKaydi analiz) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_analysis')),
        content: Text('"${analiz.gosterilecekIsim}" ${t('delete_confirm')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (onay != true) return;

    try {
      await AnalizGecmisiService.analizSil(analiz.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('delete_success'))));
        _analizleriYukle();
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage), backgroundColor: Colors.red));
    }
  }

  Future<void> _tumunuSil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_all')),
        content: Text(t('delete_all_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('clear')),
          ),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await AnalizGecmisiService.tumGecmisiTemizle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('delete_all_success'))));
        _analizleriYukle();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, _, __) => Scaffold(
        appBar: _buildAppBar(),
        body: Column(children: [
          if (_aramaAcik) _buildAramaBari(),
          _buildFiltreBari(),
          Expanded(child: _buildGovde()),
        ]),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(t('history_title')),
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      actions: [
        // Arama
        IconButton(
          icon: Icon(_aramaAcik ? Icons.search_off : Icons.search),
          tooltip: t('search'),
          onPressed: () => setState(() {
            _aramaAcik = !_aramaAcik;
            if (!_aramaAcik) { _aramaCtrl.clear(); _filtreUygula(); }
          }),
        ),
        // Karşılaştır
        if (_tumAnalizler.length >= 2)
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: t('compare'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AnalizKarsilastirmaScreen())),
          ),
        // Tümünü sil
        if (_tumAnalizler.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: t('delete_all'),
            onPressed: _tumunuSil,
          ),
      ],
    );
  }

  // ── Arama Barı ────────────────────────────────────────────────────────────

  Widget _buildAramaBari() {
    return Container(
      color: Colors.blue[700],
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: _aramaCtrl,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: t('history_search'),
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: _aramaCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () { _aramaCtrl.clear(); _filtreUygula(); })
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ── Filtre Barı ───────────────────────────────────────────────────────────

  Widget _buildFiltreBari() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Row(children: [
        // Risk filtresi chipleri
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('all', t('history_filter_all')),
              const SizedBox(width: 6),
              _filterChip('high', t('history_filter_high'), Colors.red),
              const SizedBox(width: 6),
              _filterChip('medium', t('history_filter_medium'), Colors.orange),
              const SizedBox(width: 6),
              _filterChip('low', t('history_filter_low'), Colors.green),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        // Sıralama
        PopupMenuButton<String>(
          onSelected: (v) { setState(() => _siralama = v); _filtreUygula(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.sort, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                _siralama == 'date' ? t('history_sort_date') : t('history_sort_risk'),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ]),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'date',
                child: Row(children: [
                  Icon(Icons.calendar_today, size: 16,
                      color: _siralama == 'date' ? Colors.blue : Colors.grey),
                  const SizedBox(width: 8),
                  Text(t('history_sort_date')),
                  if (_siralama == 'date') ...[const Spacer(), const Icon(Icons.check, size: 16)],
                ])),
            PopupMenuItem(value: 'risk',
                child: Row(children: [
                  Icon(Icons.analytics, size: 16,
                      color: _siralama == 'risk' ? Colors.blue : Colors.grey),
                  const SizedBox(width: 8),
                  Text(t('history_sort_risk')),
                  if (_siralama == 'risk') ...[const Spacer(), const Icon(Icons.check, size: 16)],
                ])),
          ],
        ),
      ]),
    );
  }

  Widget _filterChip(String value, String label, [Color? color]) {
    final secili = _riskFiltresi == value;
    return FilterChip(
      label: Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: secili ? FontWeight.bold : FontWeight.normal)),
      selected: secili,
      onSelected: (_) { setState(() => _riskFiltresi = value); _filtreUygula(); },
      selectedColor: (color ?? Colors.blue).withOpacity(0.15),
      checkmarkColor: color ?? Colors.blue,
      side: BorderSide(
          color: secili ? (color ?? Colors.blue) : Colors.grey[300]!),
    );
  }

  // ── Gövde ─────────────────────────────────────────────────────────────────

  Widget _buildGovde() {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator());

    if (_hataMesaji != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
        const SizedBox(height: 16),
        Text(_hataMesaji!, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[900])),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _analizleriYukle, child: Text(t('retry'))),
      ]));
    }

    if (_tumAnalizler.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(t('history_empty'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(t('history_empty_sub'),
            style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      ]));
    }

    if (_filtreliAnalizler.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(t('no_results'),
            style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            _aramaCtrl.clear();
            setState(() => _riskFiltresi = 'all');
            _filtreUygula();
          },
          icon: const Icon(Icons.filter_alt_off),
          label: Text(t('clear')),
        ),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _analizleriYukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtreliAnalizler.length,
        itemBuilder: (ctx, i) {
          final analiz = _filtreliAnalizler[i];
          return _AnalizKart(
            analiz: analiz,
            onTap: () => Navigator.of(ctx).push(MaterialPageRoute(
                builder: (_) => AnalizDetayScreen(analiz: analiz))),
            onDelete: () => _analizSil(analiz),
          );
        },
      ),
    );
  }
}

// ─── Analiz Kartı ─────────────────────────────────────────────────────────────

class _AnalizKart extends StatelessWidget {
  final AnalizKaydi analiz;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AnalizKart({
    required this.analiz,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: analiz.analiz.riskRengi.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Risk rengi sol şerit
              Container(
                width: 4, height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: analiz.analiz.riskRengi,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(analiz.gosterilecekIsim,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(analiz.tamTarih,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ])),
              // Risk skoru badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: analiz.analiz.riskRengi.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: analiz.analiz.riskRengi, width: 1.5),
                ),
                child: Text(
                  analiz.analiz.riskSkoru.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: analiz.analiz.riskRengi,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: analiz.analiz.riskRengi.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(analiz.analiz.riskSeviyesi,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: analiz.analiz.riskRengi)),
              ),
              const Spacer(),
              Text('${analiz.analiz.tespitler.length} ${t('findings')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red[300],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey[400]),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Analiz Detay ─────────────────────────────────────────────────────────────

class AnalizDetayScreen extends StatelessWidget {
  final AnalizKaydi analiz;
  const AnalizDetayScreen({super.key, required this.analiz});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, _, __) => Scaffold(
        appBar: AppBar(
          title: Text(analiz.gosterilecekIsim),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text('${t('analysis_date_label')}: ${analiz.tamTarih}',
                    style: TextStyle(color: Colors.grey[700])),
              ]),
            ),
            const SizedBox(height: 16),
            RiskKarti(analiz: analiz.analiz, fotograflar: analiz.fotografDosyalari),
            const SizedBox(height: 16),
            if (analiz.fotografDosyalari.isNotEmpty) ...[
              Text(t('photos_label'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: analiz.fotografDosyalari.length,
                  itemBuilder: (_, i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(analiz.fotografDosyalari[i],
                          width: 150, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ]),
        ),
      ),
    );
  }
}
