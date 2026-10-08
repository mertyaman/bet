import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const BetMasterApp());
}

class BetMasterApp extends StatelessWidget {
  const BetMasterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BetMaster',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
      ),
      home: const MatchListScreen(),
    );
  }
}

// --- 1. AŞAMA: ANA EKRAN (ARAMA VE FİLTRELİ) ---
class MatchListScreen extends StatefulWidget {
  const MatchListScreen({Key? key}) : super(key: key);

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  List allMatches = [];
  List filteredMatches = [];
  List<String> leagues = ["Tümü"];
  String selectedLeague = "Tümü";
  String searchQuery = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  Future<void> fetchMatches() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/matches'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allMatches = data['matches'];
          filteredMatches = allMatches;
          leagues = List<String>.from(data['leagues']);
          if (!leagues.contains("Tümü")) leagues.insert(0, "Tümü");
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    setState(() {
      filteredMatches = allMatches.where((match) {
        final matchesSearch = match['home_team'].toLowerCase().contains(searchQuery.toLowerCase()) || 
                              match['away_team'].toLowerCase().contains(searchQuery.toLowerCase());
        final matchesLeague = selectedLeague == "Tümü" || match['league'] == selectedLeague;
        return matchesSearch && matchesLeague;
      }).toList();
    });
  }

  Widget _buildOddBox(String label, String odd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(odd, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BetMaster Bülten')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) {
                          searchQuery = value;
                          applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Takım ara...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Lig: ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedLeague,
                              dropdownColor: const Color(0xFF2C2C2C),
                              items: leagues.map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(val, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (String? val) {
                                setState(() {
                                  selectedLeague = val!;
                                  applyFilters();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredMatches.length,
                    itemBuilder: (context, index) {
                      final match = filteredMatches[index];
                      final msOdds = match['ms_odds'];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MatchDetailScreen(matchId: match['id'], matchTitle: "${match['home_team']} - ${match['away_team']}"),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text("${match['home_team']} - ${match['away_team']}", 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    Text("${match['time']}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("${match['league']} | ${match['date']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildOddBox("MS 1", msOdds['MS1'].toString()),
                                    _buildOddBox("MS 0", msOdds['MS0'].toString()),
                                    _buildOddBox("MS 2", msOdds['MS2'].toString()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// --- 2. AŞAMA: KARŞILAŞTIRMALI DETAY EKRANI ---
class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  final String matchTitle;

  const MatchDetailScreen({Key? key, required this.matchId, required this.matchTitle}) : super(key: key);

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  Map<String, dynamic>? matchData;
  String? selectedBookmaker;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMatchDetail();
  }

  Future<void> fetchMatchDetail() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/matches/${widget.matchId}/compare'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          matchData = data;
          final bookmakers = data['bookmakers'] as Map<String, dynamic>;
          if (bookmakers.isNotEmpty) {
            selectedBookmaker = bookmakers.keys.first;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.matchTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (matchData == null || matchData!['bookmakers'] == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.matchTitle)),
        body: const Center(child: Text("Veri yüklenemedi.")),
      );
    }

    final bookmakers = matchData!['bookmakers'] as Map<String, dynamic>;
    if (selectedBookmaker == null || !bookmakers.containsKey(selectedBookmaker)) {
      if (bookmakers.isNotEmpty) {
        selectedBookmaker = bookmakers.keys.first;
      }
    }

    final selectedSiteMarkets = selectedBookmaker != null 
        ? (bookmakers[selectedBookmaker] as Map<String, dynamic>) 
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(title: Text(widget.matchTitle, style: const TextStyle(fontSize: 16))),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Global Site Seç:", style: TextStyle(color: Colors.grey, fontSize: 14)),
                DropdownButton<String>(
                  value: selectedBookmaker,
                  dropdownColor: const Color(0xFF2C2C2C),
                  underline: Container(height: 2, color: Colors.amber),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.amber),
                  items: bookmakers.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBookmaker = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: selectedSiteMarkets.keys.length,
              itemBuilder: (context, index) {
                String marketName = selectedSiteMarkets.keys.elementAt(index);
                Map<String, dynamic> options = selectedSiteMarkets[marketName] ?? {};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(marketName, style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...options.entries.map((entry) {
                      String optionName = entry.key; 
                      var data = entry.value;
                      
                      String diffStr = data['diff'].toString();
                      bool isNeutral = diffStr == "Veri Yok";
                      bool isPositive = diffStr.startsWith('+');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Seçenek: $optionName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text("TR Yasal: ${data['tr_odd']}", style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("${data['global_odd']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                                    const SizedBox(height: 4),
                                    Text(selectedBookmaker ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isNeutral 
                                        ? Colors.grey.withOpacity(0.2) 
                                        : (isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    diffStr,
                                    style: TextStyle(
                                      color: isNeutral 
                                          ? Colors.grey 
                                          : (isPositive ? Colors.greenAccent : Colors.redAccent),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}