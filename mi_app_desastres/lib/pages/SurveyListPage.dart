import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SurveyListPage extends StatefulWidget {
  const SurveyListPage({Key? key}) : super(key: key);

  @override
  _SurveyListPageState createState() => _SurveyListPageState();
}

class _SurveyListPageState extends State<SurveyListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Encuestas"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('survey_responses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final surveys = snapshot.data!.docs;

          // Calcular la frecuencia de cada calificación (1 a 5)
          Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (var survey in surveys) {
            final rating = survey['rating'];
            if (rating is int) {
              ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Gráfico de barras simple
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SimpleBarChart(ratingCounts: ratingCounts),
                ),
                const Divider(),
                // Lista de encuestas
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: surveys.length,
                  itemBuilder: (context, index) {
                    final survey = surveys[index];
                    final rating = survey['rating'];
                    final comment = survey['comment'] ?? '';
                    final timestamp = survey['timestamp'] != null
                        ? (survey['timestamp'] as Timestamp).toDate()
                        : null;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text("Calificación: $rating"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (comment.toString().isNotEmpty)
                              Text("Comentario: $comment"),
                            if (timestamp != null)
                              Text(
                                "Fecha: ${timestamp.toLocal()}",
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget para crear un gráfico de barras simple utilizando widgets nativos de Flutter
class SimpleBarChart extends StatelessWidget {
  final Map<int, int> ratingCounts;

  const SimpleBarChart({Key? key, required this.ratingCounts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtener el valor máximo para dimensionar proporcionalmente las barras.
    int maxValue =
        ratingCounts.values.fold(0, (prev, e) => e > prev ? e : prev);
    if (maxValue == 0) maxValue = 1;

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ratingCounts.entries.map((entry) {
          final rating = entry.key;
          final count = entry.value;
          // Calcular la altura proporcional de la barra (máximo 150 píxeles)
          double barHeight = (count / maxValue) * 150;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: barHeight,
                color: Colors.blue,
              ),
              const SizedBox(height: 4),
              Text(
                rating.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(count.toString()),
            ],
          );
        }).toList(),
      ),
    );
  }
}
