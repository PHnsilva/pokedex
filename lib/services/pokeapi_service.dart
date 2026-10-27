import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokeApiException implements Exception {
  final String message;
  const PokeApiException(this.message);
  @override
  String toString() => message;
}

/// Concentra HTTP e JSON. O cache em memória evita repetir detalhes já lidos.
class PokeApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';
  final http.Client _client;
  final Duration timeout;
  final Map<String, Pokemon> _pokemonCache = {};
  final Map<int, String> _descriptionCache = {};

  PokeApiService({http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/$path')).timeout(timeout);
      if (response.statusCode != 200) {
        throw PokeApiException('Não foi possível carregar os dados (HTTP ${response.statusCode}).');
      }
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on TimeoutException {
      throw const PokeApiException('O servidor demorou para responder. Tente novamente.');
    } on PokeApiException {
      rethrow;
    } on FormatException {
      throw const PokeApiException('A API retornou dados inválidos.');
    } on http.ClientException {
      throw const PokeApiException('Não foi possível conectar à PokéAPI. Verifique sua internet.');
    }
  }

  Future<Pokemon> fetchPokemon(String idOrName) async {
    final key = idOrName.trim().toLowerCase();
    if (key.isEmpty) throw ArgumentError.value(idOrName, 'idOrName');
    final cached = _pokemonCache[key];
    if (cached != null) return cached;
    final pokemon = Pokemon.fromJson(await _get('pokemon/${Uri.encodeComponent(key)}'));
    _pokemonCache[pokemon.name] = pokemon;
    _pokemonCache['${pokemon.id}'] = pokemon;
    return pokemon;
  }

  Future<List<Pokemon>> fetchPokedex({int limit = 151, int offset = 0}) async {
    if (limit < 1 || offset < 0) throw ArgumentError('Paginação inválida.');
    final data = await _get('pokemon?limit=$limit&offset=$offset');
    final results = data['results'] as List<dynamic>;
    final pokemons = <Pokemon>[];
    // Future.wait preserva a ordem. Lotes limitam as conexões simultâneas.
    for (var i = 0; i < results.length; i += 10) {
      pokemons.addAll(await Future.wait(
        results.skip(i).take(10).map((r) => fetchPokemon(r['name'] as String)),
      ));
    }
    return pokemons;
  }

  Future<String> fetchDescription(int id) async {
    final cached = _descriptionCache[id];
    if (cached != null) return cached;
    final data = await _get('pokemon-species/$id');
    final entries = data['flavor_text_entries'] as List<dynamic>;
    // O roteiro usa inglês: a PokéAPI não fornece esses textos em português.
    final texts = entries.where((e) => e['language']['name'] == 'en');
    final text = texts.isEmpty
        ? 'Descrição em inglês não disponível.'
        : (texts.first['flavor_text'] as String).replaceAll(RegExp(r'\s+'), ' ').trim();
    _descriptionCache[id] = text;
    return text;
  }

  void close() => _client.close();
}
