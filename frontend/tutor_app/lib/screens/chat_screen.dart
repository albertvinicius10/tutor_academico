import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import 'conversation_screen.dart';

// --- TELA PRINCIPAL (Chat Screen) ---

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ChatScreen> {
  late Future<List<Conversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    setState(() {
      _conversationsFuture = apiService.getConversations();
    });
  }

  void _startNewConversation() async {
    // Navega para a tela de conversa sem um ID, indicando que é uma nova conversa.
    // O `await` garante que a lista será recarregada quando o usuário voltar.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConversationScreen()),
    );
    // Recarrega a lista de conversas, pois uma nova pode ter sido criada.
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar conversas: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma conversa encontrada.\nInicie uma nova conversa no botão +',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final conversations = snapshot.data!;
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: Text(
                  conversation.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text(
                  'Toque para ver a conversa', // Placeholder
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(DateFormat('dd/MM').format(conversation.lastMessageAt)),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConversationScreen(
                        conversationId: conversation.id,
                        conversationTitle: conversation.title,
                      ),
                    ),
                  );
                  _loadConversations(); // Recarrega ao voltar
                },
              );
            },
          );
        },
      ),
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          onPressed: _startNewConversation,
          child: const Icon(Icons.add_comment_outlined),
          tooltip: 'Nova Conversa',
        ),
      ),
    ]);
  }
}