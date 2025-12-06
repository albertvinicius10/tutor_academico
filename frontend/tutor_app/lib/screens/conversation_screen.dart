import 'package:flutter/material.dart';
import '../api/api_service.dart'; // Importa o ApiService e o modelo Message

class ConversationScreen extends StatefulWidget {
  final int? conversationId; // Pode ser nulo para uma nova conversa
  final String? conversationTitle;

  const ConversationScreen({super.key, this.conversationId, this.conversationTitle});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isAwaitingResponse = false;
  final ScrollController _scrollController = ScrollController();
  int? _currentConversationId;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;
    if (_currentConversationId == null) {
      _addInitialMessage();
    } else {
      _loadConversationHistory(_currentConversationId!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addInitialMessage() {
    setState(() {
      _messages.insert(
          0,
          Message(
            sender: 'assistant',
            content: 'Olá! Sou seu Tutor Acadêmico. Como posso ajudar você hoje?',
            timestamp: DateTime.now(),
          ));
    });
  }

  void _loadConversationHistory(int conversationId) async {
    setState(() => _isAwaitingResponse = true); // Mostra um indicador de loading
    try {
      final history = await apiService.getConversationMessages(conversationId);
      setState(() {
        // Adiciona o histórico. Como o ListView é reverso, inserimos no final.
        _messages.addAll(history.reversed);
      });
    } catch (e) {
      setState(() {
        _messages.insert(0, Message(
          sender: 'assistant',
          content: 'ERRO: Falha ao carregar o histórico. ($e)',
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isAwaitingResponse = false);
      _scrollToBottom();
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isAwaitingResponse) return;
    _messageController.clear();

    final userMessage = Message(
      sender: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
      _isAwaitingResponse = true;
    });

    _scrollToBottom();

    try {
      // Passa o ID da conversa atual para a API
      apiService.currentConversationId = _currentConversationId;
      final aiMessage = await apiService.sendMessage(text);
      
      // Se for uma nova conversa, a API retorna o ID, que guardamos.
      if (_currentConversationId == null) {
        _currentConversationId = apiService.currentConversationId;
      }

      setState(() {
        _messages.insert(0, aiMessage);
      });
    } catch (e) {
      setState(() {
        _messages.insert(
            0,
            Message(
              sender: 'assistant',
              content: 'ERRO: Não foi possível obter resposta. ($e)',
              timestamp: DateTime.now(),
            ));
      });
    } finally {
      setState(() {
        _isAwaitingResponse = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove o botão de voltar
        title: Text(widget.conversationTitle ?? 'Nova Conversa'),
        centerTitle: true, // Adicione esta linha para centralizar o título
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) {
                final message = _messages[index];
                return ChatMessage(message: message);
              },
            ),
          ),
          if (_isAwaitingResponse) const LoadingBubble(),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.primary),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TextField(
                  controller: _messageController,
                  onSubmitted: _handleSubmitted,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Pergunte algo...',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.onPrimary,
                onPressed: _isAwaitingResponse ? null : () => _handleSubmitted(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Os widgets ChatMessage e LoadingBubble podem ser movidos para cá ou para um arquivo separado.
// Por simplicidade, vamos assumir que eles estão em chat_screen.dart e importá-los.
class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.sender == 'user';
    final Color bubbleColor = isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Text(message.content),
        ),
      ),
    );
  }
}

class LoadingBubble extends StatelessWidget {
  const LoadingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Digitando...'),
          ],
        ),
      ),
    );
  }
}