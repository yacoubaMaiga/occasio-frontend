import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/annonce_service.dart';

enum EtatArticle { NEUF, TRES_BON_ETAT, BON_ETAT, ETAT_CORRECT }

extension EtatArticleExt on EtatArticle {
  String get label {
    switch (this) {
      case EtatArticle.NEUF:
        return 'Neuf';
      case EtatArticle.TRES_BON_ETAT:
        return 'Très bon état';
      case EtatArticle.BON_ETAT:
        return 'Bon état';
      case EtatArticle.ETAT_CORRECT:
        return 'État correct';
    }
  }

  String get description {
    switch (this) {
      case EtatArticle.NEUF:
        return 'Jamais utilisé, avec étiquette';
      case EtatArticle.TRES_BON_ETAT:
        return 'Peu utilisé, sans défaut visible';
      case EtatArticle.BON_ETAT:
        return 'Quelques traces d\'usage légères';
      case EtatArticle.ETAT_CORRECT:
        return 'Marques d\'usure mais fonctionnel';
    }
  }
}

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final AnnonceService _annonceService = AnnonceService(); // Instance du service

  final List<File> _images = [];
  EtatArticle? _etatSelectionne;
  dynamic _categorieSelectionnee;
  bool _isSubmitting = false;

  List<dynamic> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // ── Chargement depuis le Backend ────────────────
  Future<void> _loadCategories() async {
    try {
      final categoriesData = await _annonceService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categoriesData;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCategories = false);
        _showSnack('Erreur lors du chargement des catégories.');
      }
    }
  }

  // ── Sélection d'images ────────────────────
  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      _showSnack('Maximum 5 photos par annonce.');
      return;
    }
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file != null) {
        setState(() => _images.add(File(file.path)));
      }
    } catch (_) {
      _showSnack('Impossible d\'accéder à la caméra ou à la galerie.');
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ── Soumission au Backend ─────────────────
  Future<void> _submit() async {
    if (_images.isEmpty) {
      _showSnack('Ajoutez au moins une photo.');
      return;
    }
    if (_etatSelectionne == null) {
      _showSnack('Sélectionnez l\'état de l\'article.');
      return;
    }
    if (_categorieSelectionnee == null) {
      _showSnack('Choisissez une catégorie.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _annonceService.creerAnnonce(
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        prix: int.parse(_prixController.text.trim()),
        etat: _etatSelectionne!.name, // Renvoie "NEUF", "TRES_BON_ETAT"...
        categorieId: _categorieSelectionnee['id'],
        images: _images,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('Annonce publiée avec succès ! 🎉');
        Navigator.of(context).pop(); // Retour à la page précédente
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('Erreur lors de la publication de l\'annonce.');
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.nuit,
      ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _PublishAppBar(
        isSubmitting: _isSubmitting,
        onPublish: _submit,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // 1. Photos
            _PhotoSection(
              images: _images,
              onPickFromGallery: () => _pickImage(ImageSource.gallery),
              onPickFromCamera: () => _pickImage(ImageSource.camera),
              onRemove: _removeImage,
            ),            

            // 2. Infos principales
            _FormSection(
              title: 'Décrivez votre article',
              child: Column(
                children: [
                  _OccasioTextField(
                    controller: _titreController,
                    label: 'Titre',
                    hint: 'Ex : iPhone 13 Pro – 256 Go',
                    maxLength: 100,
                    validator: (v) {
                      if (v == null || v.trim().length < 3) {
                        return 'Au moins 3 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _OccasioTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Décrivez l\'état, les dimensions, les accessoires inclus…',
                    maxLines: 4,
                    maxLength: 1000,
                    validator: (v) {
                      if (v == null || v.trim().length < 10) {
                        return 'Au moins 10 caractères';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // 3. Prix
            _FormSection(
              title: 'Prix',
              child: _OccasioTextField(
                controller: _prixController,
                label: 'Prix',
                hint: '0',
                suffix: 'FCFA',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Saisissez un prix';
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Prix invalide';
                  return null;
                },
              ),
            ),

            // 4. Catégorie
            _FormSection(
              title: 'Catégorie',
              child: _loadingCategories
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.terracotta, strokeWidth: 2))
                  : _CategorySelector(
                      categories: _categories,
                      selected: _categorieSelectionnee,
                      onSelect: (cat) =>
                          setState(() => _categorieSelectionnee = cat),
                    ),
            ),

            

            // 5. État de l'article
            _FormSection(
              title: 'État de l\'article',
              child: _EtatSelector(
                selected: _etatSelectionne,
                onSelect: (e) => setState(() => _etatSelectionne = e),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton publier (pied de page alternatif si besoin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PublishButton(
                  isSubmitting: _isSubmitting, onTap: _submit),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────

class _PublishAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PublishAppBar(
      {required this.isSubmitting, required this.onPublish});

  final bool isSubmitting;
  final VoidCallback onPublish;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.sable,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.nuit),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Publier une annonce',
        style: TextStyle(
          color: AppColors.nuit,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        if (!isSubmitting)
          GestureDetector(
            onTap: onPublish,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Publier',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION PHOTOS
// ─────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.images,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onRemove,
  });

  final List<File> images;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Photos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${images.length}/5',
                style: TextStyle(
                  color: AppColors.nuit.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'La première photo sera la photo principale.',
            style: TextStyle(
              color: AppColors.nuit.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Boutons d'ajout (galerie + caméra)
                if (images.length < 5) ...[
                  _AddPhotoButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galerie',
                    onTap: onPickFromGallery,
                  ),
                  const SizedBox(width: 10),
                  _AddPhotoButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Photo',
                    onTap: onPickFromCamera,
                  ),
                  if (images.isNotEmpty) const SizedBox(width: 10),
                ],
                // Miniatures des photos sélectionnées
                ...images.asMap().entries.map((entry) {
                  final i = entry.key;
                  final file = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(right: i < images.length - 1 ? 10 : 0),
                    child: _PhotoThumbnail(
                      file: file,
                      isPrimary: i == 0,
                      onRemove: () => onRemove(i),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.sable.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.terracotta.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.terracotta, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.terracotta,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.file,
    required this.isPrimary,
    required this.onRemove,
  });

  final File file;
  final bool isPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: 90,
            height: 110,
            fit: BoxFit.cover,
          ),
        ),
        // Badge "Principale"
        if (isPrimary)
          Positioned(
            bottom: 6,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.nuit.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Principale',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        // Bouton supprimer
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.nuit,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: AppColors.blanc, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION WRAPPER
// ─────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHAMP TEXTE
// ─────────────────────────────────────────────

class _OccasioTextField extends StatelessWidget {
  const _OccasioTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: AppColors.terracotta,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: TextStyle(
          color: AppColors.nuit.withValues(alpha: 0.55),
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: AppColors.nuit.withValues(alpha: 0.3),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.sable.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.sable, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.sable, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.terracotta, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        counterStyle: TextStyle(
          color: AppColors.nuit.withValues(alpha: 0.35),
          fontSize: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SÉLECTEUR DE CATÉGORIE
// ─────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<dynamic> categories;
  final dynamic selected;
  final void Function(dynamic) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = selected != null && selected['id'] == cat['id'];
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.terracotta : AppColors.sable.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.terracotta
                    : AppColors.sable,
                width: 1.5,
              ),
            ),
            child: Text(
              cat['nom'] ?? '',
              style: TextStyle(
                color: isSelected ? AppColors.blanc : AppColors.nuit,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
//  SÉLECTEUR D'ÉTAT
// ─────────────────────────────────────────────

class _EtatSelector extends StatelessWidget {
  const _EtatSelector({required this.selected, required this.onSelect});

  final EtatArticle? selected;
  final void Function(EtatArticle) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: EtatArticle.values.map((etat) {
        final isSelected = selected == etat;
        return GestureDetector(
          onTap: () => onSelect(etat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.terracotta.withValues(alpha: 0.08)
                  : AppColors.sable.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.terracotta : AppColors.sable,
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                // Bouton radio custom
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.terracotta
                          : AppColors.nuit.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.terracotta,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etat.label,
                        style: TextStyle(
                          color: AppColors.nuit,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        etat.description,
                        style: TextStyle(
                          color: AppColors.nuit.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
//  BOUTON PUBLIER (bas de page)
// ─────────────────────────────────────────────

class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.isSubmitting, required this.onTap});

  final bool isSubmitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: isSubmitting
              ? AppColors.terracotta.withValues(alpha: 0.6)
              : AppColors.terracotta,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.blanc,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Publier l\'annonce',
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
