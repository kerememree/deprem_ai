import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Her sayfanın statik metadatası (ikon + renk); metinler t() ile çekilir
  static const List<_OnboardingMeta> _metas = [
    _OnboardingMeta(
      icon: Icons.analytics_outlined,
      titleKey: 'onboarding_0_title',
      descKey: 'onboarding_0_desc',
      color: Colors.blue,
    ),
    _OnboardingMeta(
      icon: Icons.camera_alt_outlined,
      titleKey: 'onboarding_1_title',
      descKey: 'onboarding_1_desc',
      color: Colors.green,
    ),
    _OnboardingMeta(
      icon: Icons.science_outlined,
      titleKey: 'onboarding_2_title',
      descKey: 'onboarding_2_desc',
      color: Colors.orange,
    ),
    _OnboardingMeta(
      icon: Icons.security_outlined,
      titleKey: 'onboarding_3_title',
      descKey: 'onboarding_3_desc',
      color: Colors.purple,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _nextPage() {
    if (_currentPage < _metas.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() => _completeOnboarding();

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder ile dil değişikliğinde otomatik yeniden oluştur
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Atla Butonu
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        t('onboarding_skip'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _metas.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_metas[index]);
                    },
                  ),
                ),

                // Sayfa göstergeleri
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _metas.length,
                    (index) => _buildPageIndicator(index == _currentPage),
                  ),
                ),

                const SizedBox(height: 32),

                // İleri / Başlayalım Butonu
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _metas[_currentPage].color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentPage == _metas.length - 1
                            ? t('onboarding_start')
                            : t('onboarding_next'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(_OnboardingMeta meta) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon animasyonu
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: meta.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      meta.icon,
                      size: 80,
                      color: meta.color,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 48),

          // Başlık — t() ile lokalize
          Text(
            t(meta.titleKey),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: meta.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Açıklama — t() ile lokalize
          Text(
            t(meta.descKey),
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? _metas[_currentPage].color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Onboarding sayfa metadatası — metinler build sırasında t() ile çekilir
class _OnboardingMeta {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final Color color;

  const _OnboardingMeta({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.color,
  });
}
