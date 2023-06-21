import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VirusTotal URL Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiKey =
      'e8d05d416dd2c5218ac9c440d15eae9dbdd2d5732b6aa6eb769d58fca924b300';
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  bool _isUrlEmpty = false;
  String _result = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String extractUrl(String text) {
    final regex = RegExp(
      r"(?:(?:https?|http):\/\/|www\.)[^\s/$.?#].[^\s]*",
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  Future<Map<String, dynamic>> submitUrl(String url) async {
    const apiUrl = 'https://www.virustotal.com/api/v3/urls';
    final headers = {
      'x-apikey': apiKey,
      'Content-Type': 'application/json',
    };
    final queryParams = {'url': url};
    final uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

    final response = await http.post(uri, headers: headers);
    // print('submitUrl - body : ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as Map<String, dynamic>;
    } else {
      final error = json.decode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  Future<Map<String, dynamic>> getFinalResults(String finalResultsUrl) async {
    final headers = {'x-apikey': apiKey};

    final response =
        await http.get(Uri.parse(finalResultsUrl), headers: headers);
    // print("getFinalResults  - ${response.body}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = json.decode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  void _checkUrl() async {
    final url = extractUrl(_urlController.text);

    setState(() {
      _isUrlEmpty = url.isEmpty;
    });

    if (_isUrlEmpty) {
      setState(() {
        _result = 'Error: URL is empty';
      });
      return;
    }

    // if (!isValidUrl(url)) {
    //   setState(() {
    //     _result = 'Error: Invalid URL';
    //   });
    //   return;
    // }

    setState(() {
      _isLoading = true; // Activation du chargement
      _result = ''; // Réinitialisation du résultat précédent
    });

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
    } finally {
      setState(() {
        _isLoading = false; // Désactivation du chargement
      });
    }
  }

  // void _checkUrl() async {
  //   // final url = _urlController.text;
  //   final url = extractUrl(_urlController.text);

  //   if (url.isNotEmpty) {
  //     setState(() {
  //       _isLoading = true; // Activation du chargement
  //       _result = ''; // Réinitialisation du résultat précédent
  //     });

  //     try {
  //       final result = await submitUrl(url);

  //       setState(() {
  //         _result = result.toString();
  //       });

  //       // Effectuer une deuxième requête GET en utilisant l'URL fournie
  //       final analysisResultsUrl = result['data']['links']['self'];
  //       final finalResults = await getFinalResults(analysisResultsUrl);

  //       setState(() {
  //         _result = finalResults.toString();
  //       });
  //     } catch (error) {
  //       setState(() {
  //         _result = 'Error: $error';
  //       });
  //     } finally {
  //       setState(() {
  //         _isLoading = false; // Désactivation du chargement
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VirusTotal URL Checker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              maxLines: 5,
              controller: _urlController,
              decoration: InputDecoration(
                hintText: "Veuillez saisir votre text",
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 0.0),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 0.0),
                ),
                border: _isUrlEmpty
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      )
                    : null,
                errorText: _isUrlEmpty ? 'URL cannot be empty' : null,
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkUrl,
              child: const Text('Check URL'),
            ),
            const SizedBox(height: 20.0),
            Visibility(
              visible: _isLoading,
              child: const CircularProgressIndicator(), // Affichage du loader
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: TextStyle(
                    color:
                        _result.startsWith('Error') ? Colors.red : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
