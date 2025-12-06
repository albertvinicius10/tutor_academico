import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'roadmap_detail_screen.dart';

class RoadmapListScreen extends StatefulWidget {
  const RoadmapListScreen({super.key});

  @override
  State<RoadmapListScreen> createState() => _RoadmapListScreenState();
}

class _RoadmapListScreenState extends State<RoadmapListScreen> {
  late Future<List<Roadmap>> _roadmapsFuture;

  @override
  void initState() {
    super.initState();
    _loadRoadmaps();
  }

  void _loadRoadmaps() {
    setState(() {
      _roadmapsFuture = apiService.getRoadmaps();
    });
  }

  Future<void> _showCreateRoadmapDialog() async {
    final topicController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gerar Novo Roadmap'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: topicController,
              decoration: const InputDecoration(hintText: "Ex: Python para Análise de Dados"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira um tópico.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Gerar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(); // Fecha o dialog
                  _handleRoadmapGeneration(topicController.text);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleRoadmapGeneration(String topic) {
    // Mostra um SnackBar de carregamento
    final snackBar = SnackBar(
      content: Row(
        children: const [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text("Gerando seu roadmap..."),
        ],
      ),
      duration: const Duration(minutes: 5), // Duração longa
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    apiService.generateRoadmap(topic).then((newRoadmap) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Esconde o loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Roadmap gerado com sucesso!"), backgroundColor: Colors.green),
      );
      _loadRoadmaps(); // Recarrega a lista
    }).catchError((error) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao gerar roadmap: $error"), backgroundColor: Colors.red),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FutureBuilder<List<Roadmap>>(
        future: _roadmapsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não tem roadmaps.\nCrie um no botão +',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final roadmaps = snapshot.data!;
          return ListView.builder(
            itemCount: roadmaps.length,
            itemBuilder: (context, index) {
              final roadmap = roadmaps[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(roadmap.topic, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Criado em: ${roadmap.createdAt.day}/${roadmap.createdAt.month}/${roadmap.createdAt.year}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoadmapDetailScreen(roadmap: roadmap),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton.extended(
          onPressed: _showCreateRoadmapDialog,
          icon: const Icon(Icons.add),
          label: const Text('Novo Roadmap'),
        ),
      ),
    ]);
  }
}