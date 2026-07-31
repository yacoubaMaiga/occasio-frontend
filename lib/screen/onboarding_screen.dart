import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  void _goToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _goToRegistration() {
    Navigator.of(context).pushNamed('/inscription');
  }

  void _goToLogin() {
    Navigator.of(context).pushNamed('/connexion');
  }

  void _showLoginOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.blanc,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Se connecter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              _LoginOptionButton(
                text: 'Continuer avec Google',
                iconWidget: Image.asset('assets/icons/google_icon.png', height: 24, width: 24),
                onTap: () {
                  // Google login logic here
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _LoginOptionButton(
                text: 'Se connecter avec email',
                iconWidget: const Icon(Icons.email_outlined, size: 24, color: AppColors.textPrimary),
                onTap: () {
                  Navigator.pop(context);
                  _goToLogin();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _OnboardingHeader(onSkip: _goToHome),

            const SizedBox(height: 12),

            // Scrolling Mosaic Section
            const Expanded(child: _ScrollingMosaic()),

            const SizedBox(height: 32),

            // Text and Buttons
            _OnboardingFooter(
              onCreateAccount: _goToRegistration,
              onAlreadyHaveAccount: _showLoginOptions,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginOptionButton extends StatelessWidget {
  final String text;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _LoginOptionButton({
    required this.text,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: iconWidget,
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final VoidCallback onSkip;

  const _OnboardingHeader({required this.onSkip});

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
              color: AppColors.textPrimary.withValues(alpha: 0.6),
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
    const double speed = 30.0;
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
          child: _ImageRow(controller: _controller1, images: _row1Images),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _ImageRow(controller: _controller2, images: _row2Images),
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
                  color: AppColors.sable,
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.textPrimary.withValues(alpha: 0.3),
                  ),
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
  final VoidCallback onCreateAccount;
  final VoidCallback onAlreadyHaveAccount;

  const _OnboardingFooter({
    required this.onCreateAccount,
    required this.onAlreadyHaveAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(
            'Rejoins Occasio et donne une seconde vie à tes objets que tu n\'utilises plus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onCreateAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.callToAction,
                foregroundColor: AppColors.blanc,
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
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: onAlreadyHaveAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.callToAction,
                side: const BorderSide(
                  color: AppColors.callToAction,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'J\'ai déjà un compte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
