import 'package:flutter/material.dart';
import '../api/api_service.dart';

class RoadmapDetailScreen extends StatelessWidget {
  final Roadmap roadmap;

  const RoadmapDetailScreen({super.key, required this.roadmap});

  @override
  Widget build(BuildContext context) {
    // O campo 'roadmap' no JSON é uma lista de passos
    final List<dynamic> steps = roadmap.content['roadmap'] ?? [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove o botão de voltar
        title: Text(roadmap.topic),
        centerTitle: true, // Adicione esta linha para centralizar o título
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          // Cada passo é um mapa de dados
          final stepData = steps[index] as Map<String, dynamic>;
          final int stepNumber = stepData['step'];
          final String title = stepData['title'];
          final String description = stepData['description'];
          // Os tópicos são uma lista de strings
          final List<dynamic> topics = stepData['topics'] ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Text('$stepNumber'),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(description),
              ),
              // Mapeia a lista de tópicos para uma lista de widgets
              children: topics.map<Widget>((topic) {
                return ListTile(
                  leading: const Icon(Icons.arrow_right_alt, size: 20),
                  title: Text(topic as String),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}