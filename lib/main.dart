import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VirusTotal URL Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiKey =
      'e8d05d416dd2c5218ac9c440d15eae9dbdd2d5732b6aa6eb769d58fca924b300';
  final TextEditingController _urlController = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> submitUrl(String url) async {
    final apiUrl = 'https://www.virustotal.com/api/v3/urls';
    final headers = {
      'x-apikey': apiKey,
      'Content-Type': 'application/json',
    };
    final queryParams = {'url': url};
    final uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

    final response = await http.post(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as Map<String, dynamic>;
    } else {
      final error = json.decode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  Future<void> fetchUrlAnalysis(String url) async {
    try {
      final urlAnalysisResponse = await submitUrl(url);
      final analysisUrl = urlAnalysisResponse['data']['links']['self'];
      final analysisResults = await getAnalysisResults(analysisUrl);

      final analysisResultsUrl = analysisResults['links']['self'];
      final finalResults = await getFinalResults(analysisResultsUrl);

      setState(() {
        _result = finalResults.toString();
      });
    } catch (e) {
      print('Erreur lors de la récupération des résultats de l\'analyse : $e');
    }
  }

  Future<Map<String, dynamic>> getFinalResults(String finalResultsUrl) async {
    final headers = {'x-apikey': apiKey};

    final response =
        await http.get(Uri.parse(finalResultsUrl), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = json.decode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  Future<Map<String, dynamic>> getAnalysisResults(String analysisUrl) async {
    final headers = {'x-apikey': apiKey};

    final response = await http.get(Uri.parse(analysisUrl), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = json.decode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  void _checkUrl() async {
    final url = _urlController.text;

    if (url.isNotEmpty) {
      try {
        final result = await submitUrl(url);

        setState(() {
          _result = result.toString();
        });

        // Effectuer une deuxième requête GET en utilisant l'URL fournie
        final analysisResultsUrl = result['data']['links']['self'];
        final finalResults = await getFinalResults(analysisResultsUrl);

        setState(() {
          _result = finalResults.toString();
        });
      } catch (error) {
        setState(() {
          _result = 'Error: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VirusTotal URL Checker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter URL',
              ),
            ),
            ElevatedButton(
              onPressed: _checkUrl,
              child: Text('Check URL'),
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
