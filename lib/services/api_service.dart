import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  String? _token; // token JSON ou cookie
  bool _useCookie = false; // true si ancien serveur
  String? _apiBaseUrl;

  // Dictionnaire des serveurs avec leurs URL spécifiques pour TaxRef
  final Map<String, String> serverTaxRefUrls = {
    "https://expert.silene.eu/api": "https://taxhub.silene.eu/api/taxref/",
    "https://donnees.biodiversite-auvergne-rhone-alpes.fr/api":
        "https://taxons.biodiversite-aura.fr/api/taxref/",
  };

  String get baseUrl => _apiBaseUrl!;

  // Login : récupère token JSON ou cookie
  Future<void> login({
    required String apiBaseUrl,
    required String login,
    required String password,
  }) async {
    _apiBaseUrl = apiBaseUrl;

    try {
      final uri = Uri.parse("$apiBaseUrl/auth/login");

      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "User-Agent": "fr.geonature.mobile",
            },
            body: jsonEncode({"login": login, "password": password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey("token")) {
          _token = data["token"];
          _useCookie = false;
          return;
        }

        final setCookie = response.headers['set-cookie'];
        if (setCookie != null) {
          final match = RegExp(r'token=([^;]+)').firstMatch(setCookie);
          if (match != null) {
            _token = match.group(1);
            _useCookie = true;
            return;
          }
        }

        throw ApiException("Authentification réussie mais token introuvable.");
      }

      if (response.statusCode == 401 || response.statusCode == 490) {
        throw ApiException(
          "Identifiant ou mot de passe incorrect.",
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 404) {
        throw ApiException(
          "API GeoNature introuvable. Vérifiez l'URL du serveur.",
          statusCode: 404,
        );
      }

      if (response.statusCode >= 500) {
        throw ApiException(
          "Erreur serveur (${response.statusCode}).",
          statusCode: response.statusCode,
        );
      }

      throw ApiException(
        "Erreur de connexion (${response.statusCode}).",
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      // Serveur inexistant / URL mal écrite
      if (e.osError != null &&
          (e.osError!.errorCode == 7 || e.osError!.errorCode == 8)) {
        throw ApiException(
          "Serveur introuvable. Vérifiez la connexion internet ou l'adresse du serveur.",
        );
      }

      // Tout le reste = problème réseau
      throw ApiException("Aucune connexion Internet.");
    } on TimeoutException {
      throw ApiException("Le serveur met trop de temps à répondre.");
    }
  }

  // POST pour /for_web
  Future<dynamic> postForWeb(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    if (_token == null || _apiBaseUrl == null) {
      throw ApiException("Non authentifié");
    }

    final headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "User-Agent": "fr.geonature.mobile",
    };

    if (_useCookie) {
      headers["Cookie"] = "token=$_token";
    } else {
      headers["Authorization"] = "Bearer $_token";
    }

    try {
      final response = await http
          .post(
            Uri.parse("$_apiBaseUrl$endpoint"),
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          throw ApiException("Réponse serveur invalide.");
        }
      }

      if (response.statusCode == 401) {
        logout();
        throw ApiException(
          "Session expirée. Veuillez vous reconnecter.",
          statusCode: 401,
        );
      }

      if (response.statusCode >= 500) {
        throw ApiException(
          "Erreur serveur (${response.statusCode}).",
          statusCode: response.statusCode,
        );
      }

      throw ApiException(
        "Erreur de connexion (${response.statusCode}).",
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      if (e.osError != null &&
          (e.osError!.errorCode == 7 || e.osError!.errorCode == 8)) {
        throw ApiException(
          "Serveur introuvable. Vérifiez la connexion internet ou l'adresse du serveur.",
        );
      }

      throw ApiException("Aucune connexion Internet.");
    } on TimeoutException {
      throw ApiException("Le serveur met trop de temps à répondre.");
    }
  }

  Future<List<dynamic>> searchTaxons(
    String search, {
    bool useRanks = false,
  }) async {
    if (_apiBaseUrl == null || _token == null) {
      throw ApiException("Non authentifié");
    }

    final headers = {
      "Accept": "application/json",
      if (_useCookie)
        "Cookie": "token=$_token"
      else
        "Authorization": "Bearer $_token",
    };

    try {
      String url;

      if (useRanks) {
        // Recherche avec rangs taxonomiques (+ vérification si le serveur a une URL spécifique dans serverTaxRefUrls)
        String? baseTaxRefUrl = serverTaxRefUrls[_apiBaseUrl];
        if (baseTaxRefUrl != null) {
          url =
              "$baseTaxRefUrl/search/lb_nom/$search?add_rank=true&rank_limit=GN";
        } else {
          url =
              "$_apiBaseUrl/taxhub/api/taxref/search/lb_nom/$search?add_rank=true&rank_limit=GN";
        }
      } else {
        // Recherche standard sur taxons
        url =
            "$_apiBaseUrl/synthese/taxons_autocomplete?search_name=$search&limit=20";
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          throw ApiException("Réponse serveur invalide.");
        }
      }

      if (response.statusCode == 401) {
        logout();
        throw ApiException(
          "Session expirée. Veuillez vous reconnecter.",
          statusCode: 401,
        );
      }

      if (response.statusCode >= 500) {
        throw ApiException(
          "Erreur serveur (${response.statusCode}).",
          statusCode: response.statusCode,
        );
      }

      throw ApiException(
        "Erreur autocomplete (${response.statusCode}).",
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      if (e.osError != null &&
          (e.osError!.errorCode == 7 || e.osError!.errorCode == 8)) {
        throw ApiException(
          "Serveur introuvable. Vérifiez la connexion internet ou l'adresse du serveur.",
        );
      }
      throw ApiException("Aucune connexion Internet.");
    } on TimeoutException {
      throw ApiException("Le serveur met trop de temps à répondre.");
    }
  }

  Future<List<dynamic>> searchCommunes(String search) async {
    if (_apiBaseUrl == null || _token == null) {
      throw ApiException("Non authentifié");
    }

    final headers = {
      "Accept": "application/json",
      if (_useCookie)
        "Cookie": "token=$_token"
      else
        "Authorization": "Bearer $_token",
    };

    try {
      final response = await http
          .get(
            Uri.parse("$_apiBaseUrl/geo/areas?type_code=COM&area_name=$search"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          throw ApiException("Réponse serveur invalide.");
        }
      }

      if (response.statusCode == 401) {
        logout();
        throw ApiException(
          "Session expirée. Veuillez vous reconnecter.",
          statusCode: 401,
        );
      }

      if (response.statusCode >= 500) {
        throw ApiException(
          "Erreur serveur (${response.statusCode}).",
          statusCode: response.statusCode,
        );
      }

      throw ApiException(
        "Erreur lors de la récupération des communes (${response.statusCode}).",
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      if (e.osError != null &&
          (e.osError!.errorCode == 7 || e.osError!.errorCode == 8)) {
        throw ApiException(
          "Serveur introuvable. Vérifiez la connexion internet ou l'adresse du serveur.",
        );
      }
      throw ApiException("Aucune connexion Internet.");
    } on TimeoutException {
      throw ApiException("Le serveur met trop de temps à répondre.");
    }
  }

  Future<List<dynamic>> searchDepartements(String search) async {
    if (_apiBaseUrl == null || _token == null) {
      throw ApiException("Non authentifié");
    }

    final headers = {
      "Accept": "application/json",
      if (_useCookie)
        "Cookie": "token=$_token"
      else
        "Authorization": "Bearer $_token",
    };

    try {
      final response = await http
          .get(
            Uri.parse("$_apiBaseUrl/geo/areas?type_code=DEP&area_name=$search"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          throw ApiException("Réponse serveur invalide.");
        }
      }

      if (response.statusCode == 401) {
        logout();
        throw ApiException(
          "Session expirée. Veuillez vous reconnecter.",
          statusCode: 401,
        );
      }

      if (response.statusCode >= 500) {
        throw ApiException(
          "Erreur serveur (${response.statusCode}).",
          statusCode: response.statusCode,
        );
      }

      throw ApiException(
        "Erreur lors de la récupération des départements (${response.statusCode}).",
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      if (e.osError != null &&
          (e.osError!.errorCode == 7 || e.osError!.errorCode == 8)) {
        throw ApiException(
          "Serveur introuvable. Vérifiez la connexion internet ou l'adresse du serveur.",
        );
      }
      throw ApiException("Aucune connexion Internet.");
    } on TimeoutException {
      throw ApiException("Le serveur met trop de temps à répondre.");
    }
  }

  // Récupération des observations
  Future<List<dynamic>> fetchObservations({
    List<int>? cdRefs, // taxons précis
    List<int>? cdRefParents, // rangs taxonomiques
    Map<String, dynamic>? otherFilters, // autres filtres
  }) async {
    // Construire le corps de la requête
    final filters = {...?otherFilters};

    if (cdRefs != null && cdRefs.isNotEmpty) {
      filters["cd_ref"] = cdRefs; // filtre sur taxons précis
    }

    if (cdRefParents != null && cdRefParents.isNotEmpty) {
      filters["cd_ref_parent"] = cdRefParents; // filtre sur rangs
    }

    // Requête
    final response = await postForWeb("/synthese/for_web", body: filters);

    // Retourner les observations si présentes
    if (response is Map && response.containsKey("features")) {
      return response["features"];
    }

    return [];
  }

  // Détails des observations
  Future<Map<String, dynamic>> fetchObservationDetail(String id) async {
    if (_apiBaseUrl == null || _token == null) {
      throw ApiException("Non authentifié");
    }

    final headers = {
      "Accept": "application/json",
      if (_useCookie)
        "Cookie": "token=$_token"
      else
        "Authorization": "Bearer $_token",
    };

    try {
      final response = await http
          .get(
            Uri.parse("$_apiBaseUrl/synthese/vsynthese/$id"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      if (response.statusCode == 401) {
        logout();
        throw ApiException("Session expirée.");
      }

      if (response.statusCode >= 500) {
        throw ApiException("Erreur serveur (${response.statusCode}).");
      }

      throw ApiException("Erreur (${response.statusCode}).");
    } on SocketException {
      throw ApiException("Aucune connexion Internet.");
    } on TimeoutException {
      throw ApiException("Le serveur met trop de temps à répondre.");
    }
  }

  // TAXHUB
  // Récupère les attributs TaxRef pour un cd_nom donné
  Future<Map<String, dynamic>> fetchTaxRef(String cdNom) async {
    if (_apiBaseUrl == null || _token == null) {
      throw ApiException("Non authentifié");
    }

    final headers = {
      "Accept": "application/json",
      if (_useCookie)
        "Cookie": "token=$_token"
      else
        "Authorization": "Bearer $_token",
    };

    try {
      // Récupérer l'URL spécifique si elle existe
      String? taxRefUrl = serverTaxRefUrls[_apiBaseUrl];

      // Sinon utiliser l'URL générique
      taxRefUrl ??= "$_apiBaseUrl/taxhub/api/taxref/$cdNom?fields=attributs";
      // Si URL spécifique, ajouter le cdNom
      if (serverTaxRefUrls.containsKey(_apiBaseUrl)) {
        taxRefUrl = "${serverTaxRefUrls[_apiBaseUrl]}$cdNom";
      }

      final uri = Uri.parse(taxRefUrl);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          throw ApiException("Réponse TaxRef invalide.");
        }
      }

      if (response.statusCode == 401) {
        logout();
        throw ApiException(
          "Session expirée. Veuillez vous reconnecter.",
          statusCode: 401,
        );
      }

      if (response.statusCode >= 500) {
        throw ApiException(
          "Erreur serveur TaxRef (${response.statusCode}).",
          statusCode: response.statusCode,
        );
      }

      throw ApiException(
        "Erreur TaxRef (${response.statusCode}).",
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw ApiException("Aucune connexion Internet.");
    } on TimeoutException {
      throw ApiException("Le serveur TaxRef met trop de temps à répondre.");
    }
  }

  // Déconnexion
  void logout() {
    _token = null;
    _apiBaseUrl = null;
    _useCookie = false;
  }
}
