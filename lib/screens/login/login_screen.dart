import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../map/map_screen.dart';

class ServerItem {
  final String name;
  final String url;
  final bool isRecent;

  ServerItem({required this.name, required this.url, this.isRecent = false});
}

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
  final FocusNode _loginFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final ApiService _apiService = ApiService();

  late Future<String> _appVersionFuture;
  final String developerName = "Développé par OtusEco";

  bool _loading = false;
  bool _obscurePassword = true;

  List<String> _recentServers = [];

  // liste de serveur dont l'accès est possible avec création de compte ou en accès public
  final List<ServerItem> exampleServers = [
    ServerItem(
      name: "Biodiv'Aura Expert",
      url: "https://donnees.biodiversite-auvergne-rhone-alpes.fr",
    ),
    ServerItem(
      name: "Biodiv'Bretagne",
      url: "https://data.biodiversite-bretagne.fr/geonature",
    ),
    ServerItem(
      name: "Biodiv'Occitanie",
      url: "https://geonature.biodiv-occitanie.fr",
    ),
    ServerItem(
      name: "GeoNat'îdF",
      url: "https://geonature.arb-idf.fr/geonature",
    ),
    ServerItem(name: "Helix (CEN PACA)", url: "https://helix.cen-paca.org"),
    ServerItem(name: "La SHF", url: "https://geonature.lashf.org"),
    ServerItem(name: "Lo Parvi", url: "https://geonature.loparvi.fr"),
    ServerItem(
      name: "Parc National de forêts",
      url: "https://geonature.forets-parcnational.fr/geonature",
    ),
    ServerItem(
      name: "PN amazonien de Guyane",
      url: "https://geonature.parc-amazonien-guyane.fr/geonature",
    ),
    ServerItem(
      name: "PN des Pyrénées",
      url: "https://geonature.pyrenees-parcnational.fr/geonature",
    ),
    ServerItem(
      name: "PNR du Marais poitevin",
      url: "https://geonature.parc-marais-poitevin.fr",
    ),
    ServerItem(
      name: "PNR Normandie-Maine",
      url: "https://geonature.parc-naturel-normandie-maine.fr/geonature",
    ),
    ServerItem(
      name: "Réensauvager la Ferme",
      url: "https://reensauvagerlaferme.fr/geonature",
    ),
    ServerItem(
      name: "SIFlora Expert (CBN Alpin)",
      url: "https://geonature.cbn-alpin.fr",
    ),
    ServerItem(name: "Silene", url: "https://expert.silene.eu"),
  ];

  List<ServerItem> get _serverSuggestions {
    final recent = _recentServers
        .map((url) => ServerItem(name: url, url: url, isRecent: true))
        .toList();

    return [...recent, ...exampleServers];
  }

  @override
  void initState() {
    super.initState();
    _loadRecentServers();
    _appVersionFuture = _getAppVersion();

    _serverController.addListener(_onFieldChanged);
    _loginController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return "${packageInfo.version} (${packageInfo.buildNumber})";
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _canLogin {
    final server = _serverController.text.trim();
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (server.isEmpty || login.isEmpty || password.isEmpty) return false;

    final uri = Uri.tryParse(server);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _serverController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
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

    if (exampleServers.any((server) => server.url == url)) return;

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
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            ),
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 100,
                ),
              ),
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
                    /// Sélection du serveur
                    Autocomplete<ServerItem>(
                      optionsBuilder: (text) {
                        final query = text.text.toLowerCase();

                        if (query.isEmpty) {
                          return _serverSuggestions;
                        }

                        return _serverSuggestions.where((server) {
                          return server.name.toLowerCase().contains(query) ||
                              server.url.toLowerCase().contains(query);
                        });
                      },
                      displayStringForOption: (option) => option.url,
                      onSelected: (selection) {
                        _serverController.text = selection.url;
                        FocusScope.of(context).requestFocus(_loginFocusNode);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Serveur GeoNature",
                            hintText: "https://demo.geonature.fr/geonature/",
                            prefixIcon: const Icon(Icons.public),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        controller.clear(); // Vider le champ
                                      });
                                    },
                                  )
                                : null, // Afficher la croix uniquement si le champ n'est pas vide
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Veuillez saisir l'URL du serveur";
                            }

                            final trimmed = value.trim();

                            if (trimmed.contains(' ')) {
                              return "L'URL ne doit pas contenir d'espaces";
                            }

                            final uri = Uri.tryParse(trimmed);
                            if (uri == null) {
                              return "URL invalide";
                            }

                            if (!(uri.isScheme('http') ||
                                uri.isScheme('https'))) {
                              return "L'URL doit commencer par http:// ou https://";
                            }

                            if (uri.host.isEmpty) {
                              return "L'URL doit contenir un nom de domaine valide";
                            }

                            return null;
                          },
                          onChanged: (value) {
                            _serverController.text = value;
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(14),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final server = options.elementAt(index);

                                  return ListTile(
                                    leading: Icon(
                                      server.isRecent
                                          ? Icons.history
                                          : Icons.storage,
                                      color: server.isRecent
                                          ? Colors.orange
                                          : Theme.of(context).primaryColor,
                                    ),
                                    title: Text(server.name),
                                    subtitle: Text(server.url),
                                    onTap: () => onSelected(server),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Identifiant
                    TextFormField(
                      controller: _loginController,
                      focusNode: _loginFocusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: "Identifiant",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
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
                    ),

                    const SizedBox(height: 30),

                    // Bouton connexion
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_loading || !_canLogin)
                            ? null
                            : _handleLogin,
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

              FutureBuilder<String>(
                future: _appVersionFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }

                  final appVersion = snapshot.data!;

                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Text(
                          "Version $appVersion",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          developerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
