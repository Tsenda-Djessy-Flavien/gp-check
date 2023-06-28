import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'models/analysis_result_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiKey =
      'e8d05d416dd2c5218ac9c440d15eae9dbdd2d5732b6aa6eb769d58fca924b300';
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  bool _isUrlEmpty = false;
  bool _isPasteButtonVisible = false;
  List _result = [];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteText() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _urlController.text = clipboardData.text!;
      });
    }
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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final attributes = data['data']?['attributes'];
      final analysisStatus = attributes?['status'];
      final maliciousStatus = attributes?['stats']?['malicious'];
      final engines = attributes?['results'];

      return {
        'analysisStatus': analysisStatus,
        'maliciousStatus': maliciousStatus,
        'engines': engines,
      };
    } else {
      final error = json.decode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  Future<List<AnalysisResult>> _checkUrl() async {
    final url = extractUrl(_urlController.text);

    setState(() {
      _isUrlEmpty = url.isEmpty;
    });

    if (_isUrlEmpty) {
      return [
        AnalysisResult(
          analysisStatus: 'Error: URL is empty',
          maliciousStatus: 0,
          engines: [],
        )
      ];
    }

    // if (_isUrlEmpty) {
    //   setState(() {
    //     _result = ['Error: URL is empty'];
    //   });
    //   return;
    // }

    setState(() {
      _isLoading = true;
      _result = [];
    });

    try {
      final result = await submitUrl(url);

      // setState(() {
      //   final analysisStatus = result['data']['attributes']?['status'];
      //   final maliciousStatus =
      //       result['data']['attributes']?['stats']?['malicious'];
      //   _result.add('Statut de l\'analyse: ${analysisStatus ?? 'N/A'}');
      //   _result.add('Statut de malveillance: ${maliciousStatus ?? 'N/A'}/90');
      // });

      final analysisResultsUrl = result['data']['links']['self'];
      final finalResults = await getFinalResults(analysisResultsUrl);

      final analysisStatus = finalResults['analysisStatus'];
      final maliciousStatus = finalResults['maliciousStatus'];
      final engines = finalResults['engines'];

      final enginesList = engines?.entries
              .map((entry) {
                final engineName = entry.key;
                final engineResult = entry.value['result'];
                final convertedEngine = Map<String, String>.from({
                  'engineName': engineName,
                  'engineResult': engineResult ?? 'N/A',
                });
                return convertedEngine;
              })
              .toList()
              .cast<Map<String, String>>() ??
          [];

      final List<AnalysisResult> analysisResults = [
        AnalysisResult(
          analysisStatus: analysisStatus ?? 'N/A',
          maliciousStatus: maliciousStatus ?? 0,
          engines: enginesList,
        ),
      ];

      setState(() {
        _result = analysisResults;
      });

      return analysisResults;
    } catch (error) {
      final List<AnalysisResult> errorResult = [
        AnalysisResult(
          analysisStatus: 'Error: $error',
          maliciousStatus: 0,
          engines: [],
        ),
      ];

      setState(() {
        _result = errorResult;
      });

      return errorResult;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildEngineWidget(String engineName, String engineResult) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              engineName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                const SizedBox(width: 5),
                Text(
                  engineResult,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

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
                hintText: "Veuillez saisir votre texte",
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
              onChanged: (value) {
                setState(() {
                  _isUrlEmpty = false;
                  _isPasteButtonVisible = value.isEmpty;
                });
              },
            ),
            _urlController.text.isNotEmpty
                ? ElevatedButton(
                    onPressed: _isLoading ? null : _checkUrl,
                    child: const Text('Check URL'),
                  )
                : const SizedBox(height: 0),
            _urlController.text.isEmpty
                ? ElevatedButton(
                    onPressed: _pasteText,
                    child: const Text('Paste Text'),
                  )
                : const SizedBox(height: 0),
            const SizedBox(height: 20.0),
            Visibility(
              visible: _isLoading,
              child: const CircularProgressIndicator(),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _result.map((item) {
                    final analysisStatus = item.analysisStatus;
                    final maliciousStatus = item.maliciousStatus;
                    final engines = item.engines;

                    final enginesWidgets = engines.map((engine) {
                      final engineName = engine['engineName'];
                      final engineResult = engine['engineResult'];
                      return _buildEngineWidget(engineName, engineResult);
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Status: $analysisStatus',
                          style: TextStyle(
                            color: analysisStatus.startsWith('Error')
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                        Text(
                          'Malicious Status: $maliciousStatus/90',
                          style: TextStyle(
                            color: analysisStatus.startsWith('Error')
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Engines:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...enginesWidgets,
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
