import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../widgets/connection_wrapper.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;
  final storage = const FlutterSecureStorage();

  static const String baseUrl = 'https://127.0.0.1:8000/bibleqna/api/';

  Future<void> _submitQuestion() async {
    setState(() {
      _isLoading = true;
    });

    String firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      firstName = "Anonymous";
    }

    final String question = _questionController.text.trim();

    if (question.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final String? apiKey = await storage.read(key: 'bible_qna_app_key');

    final response = await http.post(
      Uri.parse('${baseUrl}new/question/'),
      headers: {
        'Content-Type': 'application/json',
        'BIBLE-QNA-APP-KEY': apiKey ?? '',
      },
      body: jsonEncode({
        'first_name': firstName,
        'question': question,
      }),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question submitted successfully!')),
      );
      _firstNameController.clear();
      _questionController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit question.')),
      );
    }
  }


  @override
  void dispose() {
    _firstNameController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionWrapper(
      child: Scaffold(
        appBar: AppBar(title: const Text('Ask a Question')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Your Question',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitQuestion,
                      child: const Text('Submit'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
