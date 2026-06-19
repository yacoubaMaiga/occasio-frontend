import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/screen/app_colors.dart';

// ─────────────────────────────────────────────
//  MODÈLE LOCAL  (à remplacer par le vrai DTO)
// ─────────────────────────────────────────────

enum _ConvStatut { actif, vendu, archive }

class _Conversation {
  const _Conversation({
    required this.id,
    required this.interlocuteur,
    required this.avatarInitiale,
    required this.titrAnnonce,
    required this.prixAnnonce,
    required this.dernierMessage,
    required this.heure,
    required this.nonLus,
    required this.statut,
    this.imageAnnonce,
    this.estMoi = false,
  });

  final String id;
  final String interlocuteur;
  final String avatarInitiale;
  final String titrAnnonce;
  final String prixAnnonce;
  final String dernierMessage;
  final String heure;
  final int nonLus;
  final _ConvStatut statut;
  final String? imageAnnonce;
  final bool estMoi; // dernier message envoyé par moi
}

// ─────────────────────────────────────────────
//  DONNÉES STATIQUES DE DÉMO
// ─────────────────────────────────────────────

const List<_Conversation> _demoConversations = [
  _Conversation(
    id: '1',
    interlocuteur: 'Aminata Koné',
    avatarInitiale: 'A',
    titrAnnonce: 'Canapé 3 places tissu gris',
    prixAnnonce: '150 000 FCFA',
    dernierMessage: 'Est-ce que le canapé est toujours disponible ?',
    heure: '10:34',
    nonLus: 2,
    statut: _ConvStatut.actif,
  ),
  _Conversation(
    id: '2',
    interlocuteur: 'Moussa Diallo',
    avatarInitiale: 'M',
    titrAnnonce: 'iPhone 13 Pro 256 Go',
    prixAnnonce: '380 000 FCFA',
    dernierMessage: 'Ok parfait, je passe demain matin.',
    heure: 'Hier',
    nonLus: 0,
    statut: _ConvStatut.actif,
    estMoi: false,
  ),
  _Conversation(
    id: '3',
    interlocuteur: 'Fatoumata Traoré',
    avatarInitiale: 'F',
    titrAnnonce: 'Veste en jean Levi\'s – M',
    prixAnnonce: '35 000 FCFA',
    dernierMessage: 'Vous : C\'est vendu, merci !',
    heure: 'Lun.',
    nonLus: 0,
    statut: _ConvStatut.vendu,
    estMoi: true,
  ),
  _Conversation(
    id: '4',
    interlocuteur: 'Ibrahim Coulibaly',
    avatarInitiale: 'I',
    titrAnnonce: 'Vélo de ville 7 vitesses',
    prixAnnonce: '90 000 FCFA',
    dernierMessage: 'Vous : Je vous envoie ma localisation.',
    heure: 'Dim.',
    nonLus: 0,
    statut: _ConvStatut.actif,
    estMoi: true,
  ),
  _Conversation(
    id: '5',
    interlocuteur: 'Kadiatou Bah',
    avatarInitiale: 'K',
    titrAnnonce: 'Table basse bois massif',
    prixAnnonce: '65 000 FCFA',
    dernierMessage: 'Pouvez-vous faire 55 000 ?',
    heure: '12/06',
    nonLus: 1,
    statut: _ConvStatut.actif,
  ),
  _Conversation(
    id: '6',
    interlocuteur: 'Seydou Keïta',
    avatarInitiale: 'S',
    titrAnnonce: 'Console PS5 + 2 manettes',
    prixAnnonce: '420 000 FCFA',
    dernierMessage: 'Vous : Non désolé, prix ferme.',
    heure: '08/06',
    nonLus: 0,
    statut: _ConvStatut.archive,
    estMoi: true,
  ),
];

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_Conversation> _filtered(_ConvStatut? statut) {
    return _demoConversations.where((c) {
      final matchStatut = statut == null || c.statut == statut;
      final matchSearch = _searchQuery.isEmpty ||
          c.interlocuteur
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          c.titrAnnonce
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchStatut && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _ConversationsAppBar(tabController: _tabController),
      body: Column(
        children: [
          // ── Barre de recherche ──────────────────────────────────────
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),

          // ── Contenu tabulé ──────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ConversationList(
                  conversations: _filtered(null),
                  emptyLabel: 'Aucune conversation',
                ),
                _ConversationList(
                  conversations: _filtered(_ConvStatut.actif),
                  emptyLabel: 'Aucune conversation active',
                ),
                _ConversationList(
                  conversations: _filtered(_ConvStatut.vendu),
                  emptyLabel: 'Aucune transaction conclue',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────

class _ConversationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ConversationsAppBar({required this.tabController});

  final TabController tabController;

  @override
  Size get preferredSize => const Size.fromHeight(56 + 46); // title + tabs

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.sable,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: const Text(
        'Messages',
        style: TextStyle(
          color: AppColors.nuit,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: false,
      actions: [
        // Bouton composer nouveau message
        GestureDetector(
          onTap: () {}, // TODO: ouvrir écran nouveau message
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.nuit.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: AppColors.nuit,
              size: 18,
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: tabController,
        labelColor: AppColors.terracotta,
        unselectedLabelColor: AppColors.nuit.withValues(alpha: 0.4),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.terracotta,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.sable,
        tabs: const [
          Tab(text: 'Tous'),
          Tab(text: 'En cours'),
          Tab(text: 'Conclus'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BARRE DE RECHERCHE
// ─────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blanc,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.sable.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sable),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search,
                size: 18, color: AppColors.nuit.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher une conversation…',
                  hintStyle: TextStyle(
                    color: AppColors.nuit.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.close,
                      size: 16,
                      color: AppColors.nuit.withValues(alpha: 0.4)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LISTE DES CONVERSATIONS
// ─────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.conversations,
    required this.emptyLabel,
  });

  final List<_Conversation> conversations;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return _EmptyState(label: emptyLabel);
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: conversations.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 76,
        endIndent: 0,
        color: AppColors.sable.withValues(alpha: 0.8),
      ),
      itemBuilder: (context, index) =>
          _ConversationTile(conv: conversations[index]),
    );
  }
}

// ─────────────────────────────────────────────
//  TUILE DE CONVERSATION
// ─────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conv});

  final _Conversation conv;

  @override
  Widget build(BuildContext context) {
    final hasUnread = conv.nonLus > 0;

    return GestureDetector(
      onTap: () {
        // TODO: Navigator.push vers ChatScreen(conversationId: conv.id)
      },
      child: Container(
        color: hasUnread
            ? AppColors.terracotta.withValues(alpha: 0.03)
            : AppColors.blanc,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ───────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _avatarColor(conv.avatarInitiale),
                  ),
                  child: Center(
                    child: Text(
                      conv.avatarInitiale,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Badge vendé
                if (conv.statut == _ConvStatut.vendu)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.menthe,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.blanc, width: 2),
                      ),
                      child: const Icon(Icons.check,
                          color: AppColors.blanc, size: 9),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // ── Contenu principal ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne 1 : nom + heure
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.interlocuteur,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conv.heure,
                        style: TextStyle(
                          color: hasUnread
                              ? AppColors.terracotta
                              : AppColors.nuit.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Ligne 2 : titre annonce (chip compact)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: conv.statut == _ConvStatut.vendu
                              ? AppColors.menthe.withValues(alpha: 0.15)
                              : AppColors.sable,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          conv.prixAnnonce,
                          style: TextStyle(
                            color: conv.statut == _ConvStatut.vendu
                                ? AppColors.menthe
                                : AppColors.terracotta,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          conv.titrAnnonce,
                          style: TextStyle(
                            color:
                                AppColors.nuit.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Ligne 3 : dernier message + badge non lus
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.dernierMessage,
                          style: TextStyle(
                            color: hasUnread
                                ? AppColors.nuit
                                : AppColors.nuit.withValues(alpha: 0.45),
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              conv.nonLus > 9
                                  ? '9+'
                                  : conv.nonLus.toString(),
                              style: const TextStyle(
                                color: AppColors.blanc,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Couleur de l'avatar basée sur l'initiale
  Color _avatarColor(String initiale) {
    const colors = [
      AppColors.nuit,
      AppColors.terracotta,
      AppColors.menthe,
      Color(0xFF6B7DB3),
      Color(0xFF8B6B9E),
    ];
    return colors[initiale.codeUnitAt(0) % colors.length];
  }
}

// ─────────────────────────────────────────────
//  ÉTAT VIDE
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.sable,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.terracotta,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vos échanges avec les vendeurs\napparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.nuit.withValues(alpha: 0.45),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}