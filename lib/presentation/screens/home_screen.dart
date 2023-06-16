import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String lastMessage = '';

  Future<void> pasteLastMessage() async {
    ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        lastMessage = clipboardData.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: TextEditingController(text: lastMessage),
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
                  labelText: 'Last Message',
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pasteLastMessage,
              child: const Text('Paste Last Message'),
            ),
          ],
        ),
      ),
    );
  }
}
