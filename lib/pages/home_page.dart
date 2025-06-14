import 'package:flutter/material.dart';
import '../widgets/connection_wrapper.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String apiKeyStorageKey = 'bible_qna_app_key';
  static const String apiKeyUrl = 'https://127.0.0.1:8000/bibleqna/api/new/key/';
  static const String votdUrl = 'https://www.biblegateway.com/votd/get/?format=json&version=NASB1995';
  static const String linkTree = 'https://127.0.0.1:8000/linktree';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _votdText;
  String? _votdReference;

  @override
  void initState() {
    super.initState();
    _ensureApiKey();
    _getVOTD();
  }

  Future<void> _ensureApiKey() async {
    const storage = FlutterSecureStorage();
    String? key = await storage.read(key: HomePage.apiKeyStorageKey);
    if (key != null) return;

    try {
      final response = await http.get(Uri.parse(HomePage.apiKeyUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newKey = data['BIBLE-QNA-APP-KEY'];
        if (newKey != null) {
          await storage.write(key: HomePage.apiKeyStorageKey, value: newKey);
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch API key: $e");
    }
  }

  Future<void> _getVOTD() async {
    const storage = FlutterSecureStorage();
    final cachedText = await storage.read(key: 'votd_text');
    final cachedRef = await storage.read(key: 'votd_ref');

    if (cachedText != null && cachedRef != null) {
      setState(() {
        _votdText = cachedText;
        _votdReference = cachedRef;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(HomePage.votdUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['votd']['text'] as String?;
        final ref = data['votd']['display_ref'] as String?;
        if (text != null && ref != null) {
          await storage.write(key: 'votd_text', value: text);
          await storage.write(key: 'votd_ref', value: ref);
          setState(() {
            _votdText = text;
            _votdReference = ref;
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch VOTD: $e");
    }
  }

  Future<void> _launchLinkTree() async {
    final url = Uri.parse(HomePage.linkTree);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not get Link Tree URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionWrapper(
      child: Scaffold(
        appBar: AppBar(title: const Text('Bible Q&A')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_votdText != null && _votdReference != null)
                  Card(
                    color: Colors.blue[50],
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            _votdText!,
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _votdReference!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/question'),
                  child: const Text('Ask a Question'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/testimony'),
                  child: const Text('Give a Testimony'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _launchLinkTree,
                  child: const Text('View All Our Socials'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
