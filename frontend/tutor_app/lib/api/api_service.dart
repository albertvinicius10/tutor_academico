import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

// --- CONFIGURAÇÃO DA API ---
// Se você estiver rodando emulador, use 10.0.2.2 para acessar o localhost do Docker
const String _apiBaseUrl = 'http://10.0.2.2:8000';

// --- MODELOS DE DADOS ---
class Message {
  final String sender; // 'user' ou 'assistant'
  final String content;
  final DateTime timestamp;

  Message({required this.sender, required this.content, required this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class Conversation {
  final int id;
  final String title;
  final DateTime lastMessageAt;

  Conversation(
      {required this.id, required this.title, required this.lastMessageAt});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'] ?? 'Nova Conversa',
      // Se 'last_message_at' for nulo, usa a data e hora atuais como fallback.
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at']) 
          : DateTime.now(),
    );
  }
}

class Roadmap {
  final int id;
  final String topic;
  final Map<String, dynamic> content;
  final DateTime createdAt;

  Roadmap({
    required this.id,
    required this.topic,
    required this.content,
    required this.createdAt,
  });

  factory Roadmap.fromJson(Map<String, dynamic> json) {
    return Roadmap(
      id: json['id'],
      topic: json['main_topic'], // Correção: de 'topic' para 'main_topic'
      // O campo JSON pode vir como uma string, então decodificamos se necessário.
      content: json['content'] is String ? jsonDecode(json['content']) : json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class VideoRecommendation {
  final String title;
  final String link;
  final String thumbnailUrl;

  VideoRecommendation({
    required this.title,
    required this.link,
    required this.thumbnailUrl,
  });

  factory VideoRecommendation.fromJson(Map<String, dynamic> json) {
    // A API retorna 'thumbnail_url', vamos usar esse campo.
    return VideoRecommendation(
      title: json['title'],
      link: json['url'],
      thumbnailUrl: json['thumbnail_url'],
    );
  }
}

class PersonalizedRecommendation {
  final String topic;
  final String reason;
  final VideoRecommendation? video; // O vídeo pode ser nulo

  PersonalizedRecommendation({
    required this.topic,
    required this.reason,
    this.video,
  });

  factory PersonalizedRecommendation.fromJson(Map<String, dynamic> json) {
    // Se a API retornar uma mensagem para novos usuários, tratamos como uma recomendação especial.
    if (json.containsKey('message')) {
      return PersonalizedRecommendation(topic: 'Bem-vindo!', reason: json['message'], video: null);
    }

    return PersonalizedRecommendation(
      topic: json['suggested_topic'],
      reason: json['reasoning'],
      // Verifica se o campo 'recommended_video' não é nulo antes de tentar decodificar.
      video: json['recommended_video'] != null ? VideoRecommendation.fromJson(json['recommended_video']) : null,
    );
  }
}

// --- SERVIÇO DE AUTENTICAÇÃO E CHAT ---
class ApiService {
  String? _accessToken;
  int? _currentConversationId;

  String? get accessToken => _accessToken;
  int? get currentConversationId => _currentConversationId;
  set currentConversationId(int? id) {
    _currentConversationId = id;
  }

  // 1. REGISTRO (Sign Up)
  Future<String?> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      return null; // Sucesso
    } else {
      final errorData = jsonDecode(response.body);
      // Assumindo que o erro da API é { "detail": "User already exists" }
      return errorData['detail'];
    }
  }

  // 2. LOGIN (Sign In)
  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      return null; // Sucesso
    } else {
      return 'Credenciais inválidas ou erro no servidor.';
    }
  }

  // 3. ENVIAR MENSAGEM (Chat)
  Future<Message> sendMessage(String question) async {
    if (_accessToken == null) {
      throw Exception('Usuário não autenticado.');
    }

    final body = {
      'question': question,
      // Se já tiver um ID de conversa, envia para manter o contexto
      if (_currentConversationId != null) 'conversation_id': _currentConversationId,
      'provider': 'gemini', 
    };

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/chat/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // A API retorna o ID da mensagem. Por simplificação, o usamos para manter o fluxo.
      // O ID da conversa deve ser retornado pelo backend para ser mais robusto.
      if (_currentConversationId == null && data.containsKey('conversation_id')) {
          _currentConversationId = data['conversation_id'];
      }
      return Message.fromJson(data);
    } else {
      debugPrint('API Error Status: ${response.statusCode}');
      debugPrint('API Error Body: ${response.body}');
      throw Exception('Falha ao enviar mensagem: ${response.statusCode}');
    }
  }

  // 4. LISTAR CONVERSAS (GET /chat/conversations/)
  Future<List<Conversation>> getConversations() async {
    if (_accessToken == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/chat/conversations/'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      debugPrint('API Error Status: ${response.statusCode}');
      debugPrint('API Error Body: ${response.body}');
      throw Exception('Falha ao buscar conversas: ${response.body}');
    }
  }

  // 5. LISTAR MENSAGENS DE UMA CONVERSA (GET /chat/conversations/{id}/messages/)
  Future<List<Message>> getConversationMessages(int conversationId) async {
    if (_accessToken == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/chat/$conversationId'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      // Decodifica o objeto JSON completo da resposta.
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      // Acessa a lista de mensagens dentro da chave "messages".
      final List<dynamic> messagesList = data['messages'];
      // A API retorna as mensagens da mais antiga para a mais nova.
      return messagesList.map((json) => Message.fromJson(json)).toList();
    } else {
      debugPrint('API Error Status: ${response.statusCode}');
      debugPrint('API Error Body: ${response.body}');
      throw Exception('Falha ao buscar mensagens da conversa: ${response.body}');
    }
  }

  // 4. GERAR ROADMAP (POST /roadmap/)
  Future<Roadmap> generateRoadmap(String topic, {String provider = 'gemini'}) async {
    if (_accessToken == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/roadmap/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'topic': topic,
        'provider': provider,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Roadmap.fromJson(data);
    } else {
      debugPrint('API Error Status: ${response.statusCode}');
      debugPrint('API Error Body: ${response.body}');
      throw Exception('Falha ao gerar roadmap: ${response.body}');
    }
  }

  // 5. LISTAR ROADMAPS (GET /roadmap/)
  Future<List<Roadmap>> getRoadmaps() async {
    if (_accessToken == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/roadmap/'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Roadmap.fromJson(json)).toList();
    } else {
      debugPrint('API Error Status: ${response.statusCode}');
      debugPrint('API Error Body: ${response.body}');
      throw Exception('Falha ao buscar roadmaps: ${response.body}');
    }
  }

  // 6. BUSCAR RECOMENDAÇÕES DE VÍDEOS (POST /recommendations/videos)
  Future<List<VideoRecommendation>> getYouTubeRecommendations(String topic, {int maxResults = 5}) async {
    if (_accessToken == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/recommendations/videos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'topic': topic,
        'max_results': maxResults,
      }),
    );

    if (response.statusCode == 200) {
      // A API retorna uma lista diretamente no corpo da resposta
      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> videosList = responseData['videos'] as List<dynamic>;
      return videosList.map((json) => VideoRecommendation.fromJson(json)).toList();
    } else {
      debugPrint('API Error Status: ${response.statusCode}');
      debugPrint('API Error Body: ${response.body}');
      throw Exception('Falha ao buscar recomendações de vídeos: ${response.body}');
    }
  }

  // 7. BUSCAR RECOMENDAÇÃO "PARA VOCÊ" (GET /recommendations/for-you)
  Future<PersonalizedRecommendation> getForYouRecommendation() async {
    if (_accessToken == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/recommendations/for-you'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return PersonalizedRecommendation.fromJson(data);
    } else {
      debugPrint('API Error Status: ${response.statusCode}');
      debugPrint('API Error Body: ${response.body}');
      throw Exception('Falha ao buscar recomendação "Para Você": ${response.body}');
    }
  }

  void logout() {
    _accessToken = null;
    _currentConversationId = null;
  }
}

final ApiService apiService = ApiService();
