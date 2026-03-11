import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../map/map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ApiService _apiService = ApiService();

  bool _loading = false;
  bool _obscurePassword = true;

  List<String> _recentServers = [];

  final List<Map<String, String>> exampleServers = [
    {"name": "Silene", "url": "https://expert.silene.eu"},
    {"name": "Helix (CEN PACA)", "url": "https://helix.cen-paca.org"},
    {
      "name": "Biodiv'Aura Expert",
      "url": "https://donnees.biodiversite-auvergne-rhone-alpes.fr",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentServers();
  }

  Future<void> _loadRecentServers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentServers = prefs.getStringList("recentServers") ?? [];
    });
  }

  Future<void> _addRecentServer(String url) async {
    final prefs = await SharedPreferences.getInstance();

    if (url.endsWith("/api")) {
      url = url.substring(0, url.length - 4);
    }

    if (exampleServers.any((server) => server["url"] == url)) return;

    _recentServers.remove(url);
    _recentServers.insert(0, url);

    if (_recentServers.length > 3) {
      _recentServers = _recentServers.sublist(0, 3);
    }

    await prefs.setStringList("recentServers", _recentServers);
    setState(() {});
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    String baseUrl = _serverController.text.trim();
    if (baseUrl.endsWith("/")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    final apiUrl = baseUrl.endsWith("/api") ? baseUrl : "$baseUrl/api";

    try {
      await _apiService.login(
        apiBaseUrl: apiUrl,
        login: _loginController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _addRecentServer(baseUrl);

      if (!mounted) return;

      const specialServers = ["https://expert.silene.eu"];
      final bool skipInitialLoad = specialServers.contains(baseUrl);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MapScreen(
            apiService: _apiService,
            skipInitialLoad: skipInitialLoad,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text("⚠️ ${e.message}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("⚠️ Erreur inattendue"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 100,
                ),
              ),
              const SizedBox(height: 0),

              // Sous-titre
              const Center(
                child: Text(
                  "L'appli de visualisation des données de GeoNature.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),

              // Formulaire
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // URL serveur
                    TextFormField(
                      controller: _serverController,
                      decoration: InputDecoration(
                        labelText: "URL du serveur GeoNature",
                        hintText: "https://demo.geonature.fr/geonature/",
                        prefixIcon: const Icon(Icons.public),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Veuillez saisir l'URL du serveur";
                        }
                        if (!value.startsWith("http")) {
                          return "URL invalide (doit commencer par http/https)";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Identifiant
                    TextFormField(
                      controller: _loginController,
                      decoration: InputDecoration(
                        labelText: "Identifiant",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Veuillez saisir votre identifiant";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Veuillez saisir votre mot de passe";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // Bouton connexion
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Se connecter",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Serveurs exemples
              const Text(
                "Serveurs exemples",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 0),
              Wrap(
                spacing: 5,
                runSpacing: 0,
                children: exampleServers.map((server) {
                  return ActionChip(
                    avatar: const Icon(Icons.link, size: 18),
                    label: Text(server["name"]!),
                    onPressed: () {
                      _serverController.text = server["url"]!;
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 15),

              // Serveurs récents
              if (_recentServers.isNotEmpty) ...[
                const Text(
                  "Derniers serveurs utilisés",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 0),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentServers.map((url) {
                    return ActionChip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: Text(url),
                      onPressed: () {
                        _serverController.text = url;
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
