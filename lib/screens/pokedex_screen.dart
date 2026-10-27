import 'package:flutter/material.dart';

import '../data/pokemon_mock.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../theme/type_colors.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';

/// Tela 1: o Future nasce uma vez, e a busca só filtra os dados carregados.
class PokedexScreen extends StatefulWidget {
  final PokeApiService? api;
  final bool useMock;
  const PokedexScreen({super.key, this.api, this.useMock = false});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late final PokeApiService _api;
  late Future<List<Pokemon>> _pokedexFuture;
  final Set<int> _captured = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PokeApiService();
    _pokedexFuture = _load();
  }

  Future<List<Pokemon>> _load() => widget.useMock
      ? Future.value(pokemonMock)
      : _api.fetchPokedex();

  Future<void> _reload() async {
    final next = _load();
    setState(() => _pokedexFuture = next);
    try {
      await next;
    } catch (_) {
      // O FutureBuilder apresenta o erro e oferece outra tentativa.
    }
  }

  Future<void> _openDetails(Pokemon pokemon) async {
    final captured = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (context) => PokemonDetailScreen(
        pokemon: pokemon,
        isCaptured: _captured.contains(pokemon.id),
        api: _api,
      )),
    );
    if (!mounted || captured != true) return;
    setState(() => _captured.add(pokemon.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${pokemon.displayName} foi capturado!')),
    );
  }

  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: pokedexRed,
        foregroundColor: Colors.white,
        title: const Text('Pokédex', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              const Icon(Icons.catching_pokemon),
              const SizedBox(width: 4),
              Text('${_captured.length}', semanticsLabel: '${_captured.length} capturados'),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Buscar por nome ou número',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(child: FutureBuilder<List<Pokemon>>(
          future: _pokedexFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off, size: 48),
                  const SizedBox(height: 12),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _reload,
                    icon: const Icon(Icons.refresh), label: const Text('Tentar de novo')),
                ]),
              ));
            }
            final all = snapshot.data ?? const <Pokemon>[];
            final pokemons = all.where((p) => p.name.contains(_query)
                || p.displayName.toLowerCase().contains(_query)
                || p.number.toLowerCase().contains(_query)).toList();
            return RefreshIndicator(
              onRefresh: _reload,
              child: pokemons.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    Padding(padding: const EdgeInsets.all(32), child: Text(
                      all.isEmpty ? 'Nenhum Pokémon disponível.' : 'Nenhum Pokémon encontrado.',
                      textAlign: TextAlign.center)),
                  ])
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200, mainAxisSpacing: 12,
                      crossAxisSpacing: 12, childAspectRatio: 0.8),
                    itemCount: pokemons.length,
                    itemBuilder: (context, index) {
                      final pokemon = pokemons[index];
                      return PokemonCard(key: ValueKey(pokemon.id), pokemon: pokemon,
                        isCaptured: _captured.contains(pokemon.id),
                        onTap: () => _openDetails(pokemon));
                    },
                  ),
            );
          },
        )),
      ]),
    );
  }
}
