import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/theme/app_colors.dart';
import 'package:occasio/service/messagerie_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String interlocuteurName;
  final String interlocuteurId;
  final Map<String, dynamic> produitInfo; // Contient titre, prix, image

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.interlocuteurName,
    required this.interlocuteurId,
    required this.produitInfo,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessagerieService _messagerieService = MessagerieService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _chargerMessages(initial: true);
    _marquerConversationCommeLue();
    
    // Polling toutes les 3 secondes pour recevoir les nouveaux messages
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _chargerMessages(initial: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _chargerMessages({required bool initial}) async {
    try {
      final list = await _messagerieService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = list;
          _isLoading = false;
        });
        if (initial) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _marquerConversationCommeLue() async {
    try {
      await _messagerieService.marquerCommeLu(widget.conversationId);
    } catch (e) {
      print("Erreur marquage lu : $e");
    }
  }

  Future<void> _envoyerMessage() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty) return;

    _messageController.clear();

    try {
      final nouveauMessage = await _messagerieService.envoyerMessage(widget.conversationId, texte);
      setState(() {
        _messages.add(nouveauMessage);
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'envoyer le message")),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.sable,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.nuit),
        title: Text(
          widget.interlocuteurName,
          style: const TextStyle(color: AppColors.nuit, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Bandeau du Produit Concerne ──
          _buildProduitBanner(),
          
          // ── Flux de Messages ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.all(16),
    itemCount: _messages.length,
    itemBuilder: (context, index) {
      final msg = _messages[index];
      
      // 🎯 LA MAGIE EST ICI : Si l'expéditeur n'est pas l'autre personne, c'est que c'est toi !
      final bool estMoi = msg['expediteurId'] != widget.interlocuteurId; 

      return _ChatBubble(
        message: msg['contenu'] ?? '',
        dateStr: msg['dateEnvoie'] ?? '',
        estMoi: estMoi, // Maintenant ça va marcher parfaitement !
      );
    },
  )
          ),

          // ── Barre de Saisie en Bas ──
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildProduitBanner() {
    final img = widget.produitInfo['image'];
    return Container(
      // La couleur et la bordure doivent être regroupées dans "decoration"
      decoration: BoxDecoration(
        color: AppColors.blanc,
        border: Border(bottom: BorderSide(color: AppColors.sable.withValues(alpha: 0.5))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sable,
              borderRadius: BorderRadius.circular(6),
              image: img != null ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover) : null,
            ),
            child: img == null ? const Icon(Icons.image_outlined, size: 20, color: AppColors.terracotta) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.produitInfo['titre'] ?? 'Article', 
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 2),
                Text(
                  widget.produitInfo['prix'] ?? '0 FCFA', 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.terracotta)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPadding),
      color: AppColors.blanc,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.sable),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Écrire un message...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _envoyerMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: AppColors.blanc, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "Aucun message.\nEnvoyez un message pour démarrer l'échange !",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.4), fontSize: 13, height: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BULLE DE DISCUSSION
// ─────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String message;
  final String dateStr;
  final bool estMoi;

  const _ChatBubble({required this.message, required this.dateStr, required this.estMoi});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: estMoi ? AppColors.terracotta : AppColors.blanc,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(estMoi ? 16 : 2),
            bottomRight: Radius.circular(estMoi ? 2 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(color: estMoi ? AppColors.blanc : AppColors.textPrimary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(dateStr),
                style: TextStyle(color: estMoi ? AppColors.blanc.withValues(alpha: 0.7) : Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String rawDate) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(rawDate).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}