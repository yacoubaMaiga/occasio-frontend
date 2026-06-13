import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color primaryColor = Color(0xFFE07B39);
  static const Color textColor = Color(0xFF1A1A2E);
  static const Color skipColor = Color(0xFF9A9AAF); // softer than textColor

  void _goToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _OnboardingHeader(onSkip: _goToHome, skipColor: skipColor),

            const SizedBox(height: 12),

            // Scrolling Mosaic Section
            const Expanded(
              child: _ScrollingMosaic(),
            ),

            const SizedBox(height: 32),

            // Text and Buttons
            _OnboardingFooter(
              primaryColor: primaryColor,
              textColor: textColor,
              onAction: _goToHome,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final VoidCallback onSkip;
  final Color skipColor;

  const _OnboardingHeader({required this.onSkip, required this.skipColor});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 20),
        child: GestureDetector(
          onTap: onSkip,
          child: Text(
            'Passer',
            style: TextStyle(
              color: skipColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollingMosaic extends StatefulWidget {
  const _ScrollingMosaic();

  @override
  State<_ScrollingMosaic> createState() => _ScrollingMosaicState();
}

class _ScrollingMosaicState extends State<_ScrollingMosaic> {
  late ScrollController _controller1;
  late ScrollController _controller2;

  final List<String> _row1Images = [
    'assets/onboarding/on1.jpeg',
    'assets/onboarding/on2.jpeg',
    'assets/onboarding/on3.jpeg',
  ];
  final List<String> _row2Images = [
    'assets/onboarding/on4.jpeg',
    'assets/onboarding/on5.jpeg',
    'assets/onboarding/on6.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _controller1 = ScrollController();
    _controller2 = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    // Slow linear scroll to a very large offset to simulate infinite
    const double speed = 30.0; // pixels per second
    const double targetOffset = 1000000.0;
    final duration1 = Duration(seconds: (targetOffset / speed).round());
    final duration2 = Duration(seconds: (targetOffset / (speed * 0.8)).round());

    if (_controller1.hasClients) {
      _controller1.animateTo(
        targetOffset,
        duration: duration1,
        curve: Curves.linear,
      );
    }
    if (_controller2.hasClients) {
      _controller2.animateTo(
        targetOffset,
        duration: duration2,
        curve: Curves.linear,
      );
    }
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _ImageRow(
            controller: _controller1,
            images: _row1Images,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _ImageRow(
            controller: _controller2,
            images: _row2Images,
          ),
        ),
      ],
    );
  }
}

class _ImageRow extends StatelessWidget {
  final ScrollController controller;
  final List<String> images;

  const _ImageRow({required this.controller, required this.images});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final imagePath = images[index % images.length];
        return Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 0.85,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF0EDE8),
                  child: const Icon(Icons.image_outlined, color: Color(0xFFBBB8B0)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  final Color primaryColor;
  final Color textColor;
  final VoidCallback onAction;

  const _OnboardingFooter({
    required this.primaryColor,
    required this.textColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(
            'Rejoins Occasio et donne une seconde vie aux objets que tu n\'utilises plus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 40),
          // Primary button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'J\'ai déjà un compte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
