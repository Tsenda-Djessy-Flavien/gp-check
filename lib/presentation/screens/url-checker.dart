import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UrlChecker extends StatefulWidget {
  @override
  _UrlCheckerState createState() => _UrlCheckerState();
}

class _UrlCheckerState extends State<UrlChecker> {
  TextEditingController _urlController = TextEditingController();
  String _result = '';

  final String apiUrl = 'https://www.virustotal.com/api/v3/urls';
  final String apiKey =
      'e8d05d416dd2c5218ac9c440d15eae9dbdd2d5732b6aa6eb769d58fca924b300';
  Future<Map<String, dynamic>> submitUrl(String url) async {
    final apiUrlWithParams =
        Uri.parse(apiUrl).replace(queryParameters: {'url': url});

    final headers = {
      'x-apikey': apiKey,
    };

    final response = await http.post(apiUrlWithParams, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final analysisId = data['data']['id'];

      return getAnalysis(analysisId);
    } else {
      throw Exception('Failed to submit URL for analysis');
    }
  }

  Future<Map<String, dynamic>> getAnalysis(String analysisUrl) async {
    final headers = {
      'x-apikey': apiKey,
    };

    final response = await http.get(Uri.parse(analysisUrl), headers: headers);

    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get analysis results');
    }
  }

  Future<void> _checkUrl() async {
    final url = _urlController.text;

    if (url.isNotEmpty) {
      final result = await submitUrl(url);

      if (result.containsKey('links') && result['links'].containsKey('self')) {
        final analysisUrl = result['links']['self'];

        final analysisResult = await getAnalysis(analysisUrl);

        if (analysisResult.containsKey('data') &&
            analysisResult['data'].containsKey('attributes')) {
          final attributes = analysisResult['data']['attributes'];

          setState(() {
            _result = attributes.toString();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('URL Checker'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _checkUrl,
              child: Text('Vérifier URL'),
            ),
            SizedBox(height: 16.0),
            Text(_result),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Checker',
      home: UrlChecker(),
    );
  }
}
