import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const SportsAnalyticsApp());
}

class SportsAnalyticsApp extends StatelessWidget {
  const SportsAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Analytics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MatchListScreen(),
    );
  }
}

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  List<dynamic> matches = [];
  bool isLoading = true;
  Timer? _timer;

  final String baseUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    fetchMatches();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchMatches());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchMatches() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/matches'));
      if (response.statusCode == 200) {
        setState(() {
          matches = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> triggerRefresh() async {
    setState(() => isLoading = true);
    await http.post(Uri.parse('$baseUrl/api/refresh'));
    await fetchMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anlık Oran Karşılaştırma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: triggerRefresh,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchMatches,
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final double advantage = (match['max_advantage_pct'] ?? 0.0).toDouble();

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: const Color(0xFF1E1E1E),
                    child: ListTile(
                      title: Text(
                        '${match['home_team']} - ${match['away_team']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(match['league'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: advantage > 10 ? Colors.green.shade800 : Colors.blue.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+%$advantage Fark',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        // Tıklama ile Detay Ekranına Geçiş
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchDetailScreen(
                              matchId: match['id'],
                              matchTitle: '${match['home_team']} - ${match['away_team']}',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// DETAY EKRANI (BÜRO ORAN TABLOSU)
class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  final String matchTitle;

  const MatchDetailScreen({super.key, required this.matchId, required this.matchTitle});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  Map<String, dynamic>? matchDetail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/matches/${widget.matchId}'));
      if (response.statusCode == 200) {
        setState(() {
          matchDetail = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oddsList = matchDetail?['odds'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.matchTitle)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Büro')),
                  DataColumn(label: Text('Piyasa')),
                  DataColumn(label: Text('Seçenek')),
                  DataColumn(label: Text('Oran')),
                ],
                rows: oddsList.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item['bookmaker'] ?? '')),
                    DataCell(Text(item['market'] ?? '')),
                    DataCell(Text(item['outcome'] ?? '')),
                    DataCell(Text(
                      '${item['price']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}