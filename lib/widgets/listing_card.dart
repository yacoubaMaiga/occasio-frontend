import 'package:flutter/material.dart';
import 'package:occasio/screen/annonce/annonce_detail_screen.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/data/models/annonce_model.dart';
// N'oublie pas d'importer ton nouveau service
import 'package:occasio/service/favori_service.dart'; 

class ListingCard extends StatefulWidget {
  final AnnonceModel item;

  const ListingCard({super.key, required this.item});

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  final FavoriService _favoriService = FavoriService();
  bool _isFavori = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifierStatutFavori();
  }

  // Vérifie si l'annonce est dans les favoris au chargement de la carte
  Future<void> _verifierStatutFavori() async {
    final estFavori = await _favoriService.estFavori(widget.item.id);
    if (mounted) {
      setState(() {
        _isFavori = estFavori;
      });
    }
  }

  // Ajoute ou retire des favoris lors du clic
  Future<void> _toggleFavori() async {
    if (_isLoading) return; // Évite les clics multiples pendant le chargement

    setState(() => _isLoading = true);

    try {
      if (_isFavori) {
        await _favoriService.supprimerDesFavoris(widget.item.id);
        setState(() => _isFavori = false);
      } else {
        await _favoriService.ajouterAuxFavoris(widget.item.id);
        setState(() => _isFavori = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnnonceDetailScreen(item: widget.item),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.nuit.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: widget.item.imagePrincipale != null
                        ? Image.network(
                            widget.item.imagePrincipale!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.sable,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: AppColors.sable,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.terracotta.withValues(alpha: 0.3),
                              size: 40,
                            ),
                          ),
                  ),
                  if (widget.item.estVendue)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.menthe,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Vendu',
                          style: TextStyle(color: AppColors.blanc, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _toggleFavori, // Appel de la fonction de toggle ici
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.blanc,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                        ),
                        child: _isLoading 
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta),
                            )
                          : Icon(
                              _isFavori ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: _isFavori ? AppColors.terracotta : Colors.grey.shade400,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.item.titre,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.description,
                    style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.6), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.item.prix} FCFA', // Formatage propre sans décimales
                    style: const TextStyle(color: AppColors.terracotta, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}