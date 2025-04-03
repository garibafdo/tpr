import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common/sqflite.dart';

class AiSettingsView extends StatefulWidget {
  const AiSettingsView({super.key});

  @override
  State<AiSettingsView> createState() => _AiSettingsViewState();
}

class _AiSettingsViewState extends State<AiSettingsView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiKeyController;
  late final TextEditingController _promptController;

  Map<String, String> _modelLabels = {};
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: Prefs.openRouterApiKey);
    _promptController = TextEditingController(text: Prefs.openRouterPrompt);
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      Directory dir;
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        final dbPath = await getDatabasesPath();
        dir = Directory(dbPath);
      } else {
        dir = await getApplicationSupportDirectory();
      }
      final file = File(join(dir.path, 'openrouter_models.json'));

      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = json.decode(contents);
        if (mounted) {
          setState(() {
            _modelLabels = data.map((k, v) => MapEntry(k, v.toString()));
            _selectedModel = _modelLabels.containsKey(Prefs.openRouterModel)
                ? Prefs.openRouterModel
                : null;
          });
        }
      } else {
        const defaultModels = {
          'google/gemini-flash-1.5-8b-exp': 'Gemini Flash 1.5',
          'google/gemini-2.5-pro-exp-03-25:free': 'Gemini Pro 2.5',
          'deepseek/deepseek-chat-v3-0324:free': 'DeepSeek Chat V3',
          'nvidia/llama-3.1-nemotron-70b-instruct:free': 'Nvidia Llama 3.1',
          'openai/chatgpt-4o-latest': '\$\$ Current 4o',
          'openai/gpt-4o-2024-08-06': '\$ Nov-2024 Gpt 4o',
        };
        await file.writeAsString(json.encode(defaultModels));
        if (mounted) {
          setState(() {
            _modelLabels = defaultModels;
            _selectedModel = Prefs.openRouterModel;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load models: $e');
    }
  }

  Future<void> _updateModelsFromGitHub(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(
          'https://github.com/bksubhuti/tpr_downloads/raw/master/download_source_files/openrouter_models.json'));

      if (response.statusCode == 200) {
        final newData = json.decode(response.body);
        Directory dir;
        if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
          final dbPath = await getDatabasesPath();
          dir = Directory(dbPath);
        } else {
          dir = await getApplicationSupportDirectory();
        }
        final file = File(join(dir.path, 'openrouter_models.json'));
        await file.writeAsString(json.encode(newData));
        if (mounted) {
          setState(() {
            _modelLabels = Map<String, String>.from(newData);
            _selectedModel = _modelLabels.containsKey(Prefs.openRouterModel)
                ? Prefs.openRouterModel
                : null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Model list updated from GitHub.')),
          );
        }
      } else {
        throw Exception('Failed to fetch models');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update model list: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('How to Get an OpenRouter API Key'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'To use AI translation, you need a free API key from OpenRouter.ai.'),
              SizedBox(height: 12),
              Text(
                  '• Visit the OpenRouter website and sign up for an account.'),
              Text('• Once logged in, you can get your API key.'),
              SizedBox(height: 12),
              Text(
                  '💡 Models with a dollar sign (e.g., \$7.22) require payment.'),
              Text(
                  '• The \$7 model costs about 0.0014 USD per 100 words (~7,000 words per dollar).'),
              Text(
                  '• The \$3 model costs about 0.0007 USD per 100 words (~14,000 words per dollar).'),
              SizedBox(height: 12),
              Text('Use free models like Gemini Flash, DeepSeek, etc.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            child: const Text('Get Key'),
            onPressed: () async {
              final url = Uri.parse('https://openrouter.ai');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.psychology),
        title: Text(
          'AI Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'OpenRouter API Key',
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          TextButton.icon(
                            label: const Text('Key ?'),
                            icon: const Icon(Icons.help_outline),
                            onPressed: () => _showHelpDialog(context),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                            onPressed: () {
                              Prefs.openRouterApiKey = _apiKeyController.text;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API Key saved')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  DropdownButtonFormField<String>(
                    value: _selectedModel,
                    decoration: const InputDecoration(
                      labelText: 'OpenRouter Model',
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedModel = value;
                          Prefs.openRouterModel = value;
                        });
                      }
                    },
                    items: _modelLabels.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child:
                            Text(entry.value, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Update model list'),
                      onPressed: () => _updateModelsFromGitHub(context),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _promptController,
                    maxLines: null,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'Custom OpenRouter Prompt',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      Prefs.openRouterPrompt = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset to Default'),
                      onPressed: () {
                        setState(() {
                          Prefs.openRouterPrompt = defaultOpenRouterPrompt;
                          _promptController.text = defaultOpenRouterPrompt;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Prompt reset to default')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
