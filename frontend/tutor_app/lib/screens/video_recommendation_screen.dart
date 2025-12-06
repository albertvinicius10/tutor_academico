import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';

class VideoRecommendationScreen extends StatefulWidget {
  const VideoRecommendationScreen({super.key});

  @override
  State<VideoRecommendationScreen> createState() => _VideoRecommendationScreenState();
}

class _VideoRecommendationScreenState extends State<VideoRecommendationScreen> {
  final _topicController = TextEditingController();
  
  // Estado para a recomendação "Para Você"
  PersonalizedRecommendation? _forYouRecommendation;
  bool _isForYouLoading = true;
  String? _forYouError;

  // Estado para a busca manual
  List<VideoRecommendation> _videos = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetchForYouRecommendation();
  }

  // Busca manual de vídeos
  Future<void> _searchVideos() async {
    if (_topicController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final results = await apiService.getYouTubeRecommendations(_topicController.text);
      setState(() {
        _videos = results;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar vídeos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Busca a recomendação "Para Você"
  Future<void> _fetchForYouRecommendation() async {
    setState(() {
      _isForYouLoading = true;
      _forYouError = null;
    });
    try {
      final recommendation = await apiService.getForYouRecommendation();
      setState(() {
        _forYouRecommendation = recommendation;
      });
    } catch (e) {
      setState(() {
        _forYouError = 'Não foi possível carregar sua recomendação.';
      });
    } finally {
      setState(() => _isForYouLoading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção "Para Você"
          _buildForYouSection(),
          const SizedBox(height: 24),
          // Seção de Busca
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: TextField(
              controller: _topicController,
              autocorrect: false,
              enableSuggestions: false,
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                icon: const Icon(Icons.search),
                hintText: 'Buscar vídeos sobre...',
                border: InputBorder.none,
                suffixIcon: _topicController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _topicController.clear()) : null,
              ),
              onChanged: (value) => setState(() {}), // Para atualizar o ícone de limpar
              onSubmitted: (_) => _searchVideos(),
            ),
          ),
          const SizedBox(height: 16),
          // Conteúdo (Loading, Erro, Lista ou Mensagem Inicial)
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (!_hasSearched) {
      return const Center(child: Text('Digite um tópico para ver recomendações de vídeos.'));
    }
    if (_videos.isEmpty) {
      return const Center(child: Text('Nenhum vídeo encontrado para este tópico.'));
    }

    return ListView.builder(
      shrinkWrap: true, // Para funcionar dentro de um SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Desabilita o scroll da lista interna
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return InkWell(
          onTap: () => _launchURL(video.link),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    video.thumbnailUrl,
                    width: 120,
                    height: 70,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 120,
                        height: 70,
                        color: Colors.grey.shade800,
                        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 70,
                        color: Colors.grey.shade800,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Título
                Expanded(
                  child: Text(video.title, maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForYouSection() {
    if (_isForYouLoading) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_forYouError != null || _forYouRecommendation == null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_forYouError ?? 'Ocorreu um erro desconhecido.'),
        ),
      );
    }

    final recommendation = _forYouRecommendation!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Para Você',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: recommendation.video != null ? () => _launchURL(recommendation.video!.link) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recommendation.video != null)
                  Image.network(
                    recommendation.video!.thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(height: 180, child: Icon(Icons.broken_image, size: 40));
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.topic,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.reason,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      if (recommendation.video != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          recommendation.video!.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}