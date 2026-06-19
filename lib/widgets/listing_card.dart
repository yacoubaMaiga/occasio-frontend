import 'package:flutter/material.dart';
import 'package:occasio/screen/annonce/annonce_detail_screen.dart';
import 'package:occasio/screen/app_colors.dart';

class ListingCard extends StatelessWidget {
  final dynamic item;

  const ListingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final titre = item['titre'] ?? 'Sans titre';
    final description = item['description'] ?? '';
    final prix = item['prix']?.toString() ?? '0';
    final imagePrincipale = item['imagePrincipale'];
    final estVendu = item['statut'] == 'VENDUE';
    final estFavori = item['estEnFavori'] ?? false;

    return GestureDetector(
      // ── Toute la card est cliquable → page détail ──
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnnonceDetailScreen(item: item),
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
            // ── Image et Badges ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                    child: imagePrincipale != null
                        ? Image.network(
                            imagePrincipale,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.sable,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: AppColors.sable,
                            child: Icon(
                              Icons.image_outlined,
                              color:
                                  AppColors.terracotta.withValues(alpha: 0.3),
                              size: 40,
                            ),
                          ),
                  ),
                  if (estVendu)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.menthe,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Vendu',
                          style: TextStyle(
                            color: AppColors.blanc,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // ── Favori : GestureDetector séparé pour ne pas
                  //    déclencher la navigation au tap sur le cœur ──
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: AnnonceService.ajouterFavoris / retirerFavoris
                        // Stopper la propagation vers le GestureDetector parent
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.blanc,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          estFavori
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: estFavori
                              ? AppColors.terracotta
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Textes ──
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.nuit.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$prix FCFA',
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
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