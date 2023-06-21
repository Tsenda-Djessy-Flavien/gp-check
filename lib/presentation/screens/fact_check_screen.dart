import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FactCheckScreen extends StatefulWidget {
  const FactCheckScreen({super.key});

  @override
  State<FactCheckScreen> createState() => _FactCheckScreenState();
}

class _FactCheckScreenState extends State<FactCheckScreen> {
  String userInput = '';
  List<dynamic> factCheckResults = [];

  Future<void> checkInfo() async {
    String apiKey = 'AIzaSyAM3XI4vEwVR_uNv6ftt9W8dK5TouexDxg';
    String apiUrl =
        'https://factchecktools.googleapis.com/v1alpha1/claims:search';

    Uri uri = Uri.parse('$apiUrl?key=$apiKey&query=$userInput');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      factCheckResults = data['claims'] ?? [];
      setState(() {});
    } else {
      print('Erreur de requête : ${response.statusCode}');
    }

    print('Le status est : ${response.statusCode}');
    print('Contenu est : ${response.body}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification des faits'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        userInput = value;
                      });
                    },
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                      labelText: 'Saisissez votre texte',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: checkInfo,
                    child: Text('Vérifier'.toUpperCase()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Résultats de la vérification :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: factCheckResults.length,
                itemBuilder: (context, index) {
                  var result = factCheckResults[index];
                  String title = result['text'] ?? '';
                  String subtitle = result['claimReview'][0]['url'] ?? '';
                  return ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
