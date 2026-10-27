import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex/models/pokemon.dart';
import 'package:pokedex/services/pokeapi_service.dart';

Map<String, dynamic> pokemonJson(int id, String name) => {
  'id': id, 'name': name, 'height': 4, 'weight': 60,
  'types': [{'type': {'name': 'electric'}}],
  'abilities': [{'ability': {'name': 'static'}}],
  'stats': [{'stat': {'name': 'hp'}, 'base_stat': 35}],
};

http.Response jsonResponse(Object data) => http.Response.bytes(
  utf8.encode(jsonEncode(data)), 200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('converte listas aninhadas, atributos, unidades e número', () {
    final p = Pokemon.fromJson(pokemonJson(25, 'pikachu'));
    expect(p.number, '#025');
    expect(p.displayName, 'Pikachu');
    expect(p.primaryType, 'electric');
    expect(p.abilities, ['static']);
    expect(p.stats['hp'], 35);
    expect(p.heightInMeters, 0.4);
    expect(p.weightInKg, 6.0);
    expect(p.description, isNull);
    expect(p.imageUrl, endsWith('/official-artwork/25.png'));
  });

  test('paginação preserva a ordem apesar de respostas fora de ordem', () async {
    final api = PokeApiService(client: MockClient((r) async {
      if (r.url.path.endsWith('/pokemon')) {
        expect(r.url.queryParameters, {'limit': '2', 'offset': '0'});
        return jsonResponse({'results': [{'name': 'bulbasaur'}, {'name': 'pikachu'}]});
      }
      final first = r.url.path.endsWith('bulbasaur');
      if (first) await Future<void>.delayed(const Duration(milliseconds: 5));
      return jsonResponse(pokemonJson(first ? 1 : 25, first ? 'bulbasaur' : 'pikachu'));
    }));
    addTearDown(api.close);
    final list = await api.fetchPokedex(limit: 2);
    expect(list.map((p) => p.id), [1, 25]);
  });

  test('cache reaproveita o mesmo Pokémon por nome e id', () async {
    var calls = 0;
    final api = PokeApiService(client: MockClient((_) async {
      calls++;
      return jsonResponse(pokemonJson(25, 'pikachu'));
    }));
    addTearDown(api.close);
    await api.fetchPokemon('Pikachu');
    await api.fetchPokemon('25');
    expect(calls, 1);
  });

  test('descrição escolhe inglês, limpa espaços e reaproveita cache', () async {
    var calls = 0;
    final api = PokeApiService(client: MockClient((r) async {
      calls++;
      expect(r.url.path, '/api/v2/pokemon-species/25');
      return jsonResponse({'flavor_text_entries': [
        {'language': {'name': 'ja'}, 'flavor_text': 'Outro idioma'},
        {'language': {'name': 'en'}, 'flavor_text': 'Electric\nmouse\fPokémon.'},
      ]});
    }));
    addTearDown(api.close);
    expect(await api.fetchDescription(25), 'Electric mouse Pokémon.');
    await api.fetchDescription(25);
    expect(calls, 1);
  });

  test('ausência de descrição inglesa tem mensagem própria', () async {
    final api = PokeApiService(client: MockClient((_) async =>
      jsonResponse({'flavor_text_entries': []})));
    addTearDown(api.close);
    expect(await api.fetchDescription(1), 'Descrição em inglês não disponível.');
  });

  test('status HTTP inválido vira erro amigável', () async {
    final api = PokeApiService(client: MockClient((_) async => http.Response('', 404)));
    addTearDown(api.close);
    await expectLater(api.fetchPokemon('missing'), throwsA(isA<PokeApiException>()));
  });

  test('timeout e falta de rede não deixam o carregamento preso', () async {
    final slow = PokeApiService(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return jsonResponse(pokemonJson(25, 'pikachu'));
      }),
    );
    addTearDown(slow.close);
    await expectLater(slow.fetchPokemon('25'), throwsA(isA<PokeApiException>()));
    final offline = PokeApiService(client: MockClient((_) async {
      throw http.ClientException('offline');
    }));
    addTearDown(offline.close);
    await expectLater(offline.fetchPokemon('25'), throwsA(isA<PokeApiException>()));
  });
}
