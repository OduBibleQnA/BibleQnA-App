import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../widgets/connection_wrapper.dart';

class TestimonyPage extends StatefulWidget {
  const TestimonyPage({super.key});

  @override
  State<TestimonyPage> createState() => _TestimonyPageState();
}

class _TestimonyPageState extends State<TestimonyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _testimonyController = TextEditingController();
  final _contactDetailController = TextEditingController();

  bool _onCamera = false;
  String? _contactMethod;

  static const String apiKeyStorageKey = 'bible_qna_app_key';
  static const String baseUrl = 'https://127.0.0.1:8000/bibleqna/api/';

  Future<String?> _getApiKey() async {
    const storage = FlutterSecureStorage();
    String? key = await storage.read(key: apiKeyStorageKey);
    return key;
  }

  Future<void> _submitTestimony() async {
    if (!_formKey.currentState!.validate()) return;

    final apiKey = await _getApiKey();
    if (apiKey == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key not found, please restart app.')),
      );
      return;
    }

    final body = {
      "name": _nameController.text.trim(),
      "shortened_testimony": _testimonyController.text.trim(),
      "on_camera": _onCamera,
      "contact_method": _contactMethod,
      "contact_detail": _contactDetailController.text.trim(),
    };

    final url = Uri.parse('${baseUrl}new/testimony/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'BIBLE-QNA-APP-KEY': apiKey,
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your testimony!')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _onCamera = false;
          _contactMethod = null;
        });
        _nameController.clear();
        _testimonyController.clear();
        _contactDetailController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting: $e')),
      );
    }
  }


  final List<DropdownMenuItem<String>> contactMethodItems = const [
    DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
    DropdownMenuItem(value: 'phone', child: Text('Phone')),
    DropdownMenuItem(value: 'email', child: Text('Email')),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _testimonyController.dispose();
    _contactDetailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionWrapper(
      child: Scaffold(
        appBar: AppBar(title: const Text('Give a Testimony')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _testimonyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Shortened Testimony',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your testimony';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('May we record you on camera?'),
                  value: _onCamera,
                  onChanged: (value) {
                    setState(() {
                      _onCamera = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _contactMethod,
                  items: contactMethodItems,
                  onChanged: (value) {
                    setState(() {
                      _contactMethod = value;
                      _contactDetailController.clear();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Preferred Contact Method',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a contact method';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_contactMethod != null)
                  TextFormField(
                    controller: _contactDetailController,
                    decoration: InputDecoration(
                      labelText:
                          'Enter your ${_contactMethod![0].toUpperCase()}${_contactMethod!.substring(1)}',
                      hintText: 'Provide your $_contactMethod contact details',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Contact detail is required';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitTestimony,
                  child: const Text('Submit Testimony'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
