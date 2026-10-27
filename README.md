# Pokédex em Flutter

Atividade LabDAMD da PUC Minas baseada no código-base e nos slides fornecidos. Mantém a organização e o visual do material e completa as etapas 1 a 4.

## Executar

Instale Flutter com Dart 3.8 ou superior (antes de Dart 4). Na pasta do projeto:

```sh
flutter pub get
flutter run
```

No navegador:

```sh
flutter run -d chrome
```

Para usar os 12 Pokémon estáticos do material, sem consultar a PokéAPI:

```sh
flutter run -d chrome --dart-define=USE_MOCK=true
```

As imagens ainda precisam de internet no modo estático. O modo padrão consulta os 151 Pokémon de Kanto.

## Etapas implementadas

| Etapa | Implementação |
| --- | --- |
| 1 | O card abre PokemonDetailScreen via Navigator.push e passa Pokemon pelo construtor. |
| 2 | Capturar! devolve true via Navigator.pop. A lista aguarda a resposta, confere mounted, atualiza o conjunto de capturados e exibe SnackBar. |
| 3 | Pokemon.fromJson, pacote http, PokeApiService e FutureBuilder para carregamento, erro, lista vazia e grade. |
| 4 | A tela de detalhes busca a descrição de pokemon-species com um Future criado no initState. Dados estáticos usam Future.value. |
| Desafios | Busca local por nome/número, RefreshIndicator e botões para tentar novamente. |

As capturas ficam em memória durante a sessão e são perdidas ao fechar o aplicativo. A descrição da API é exibida em inglês, conforme o roteiro. As descrições dos dados estáticos estão em português.

## Organização

- `lib/models`: modelo Pokemon e conversão do JSON.
- `lib/services`: HTTP, timeout, erros e cache em memória.
- `lib/screens`: grade e detalhes com navegação de ida e volta.
- `lib/widgets`: card, etiquetas de tipo e barras de status.
- `lib/theme`: cores e nomes de tipos em português.
- `lib/data`: exemplos estáticos fornecidos na aula.
- `test`: testes sem chamadas reais à API.

A consulta da lista usa Future.wait em lotes de 10, preservando a ordem e limitando conexões simultâneas. O cache de detalhes e descrições dura enquanto o serviço existe. Atualizar consulta novamente o índice e reaproveita os detalhes em cache.

## Validar

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
```

As pastas Android, iOS, web, Windows, Linux e macOS acompanham o projeto. Android possui a permissão INTERNET e macOS possui network.client nas configurações de debug e release. Para compilar cada plataforma, instale os componentes indicados pelo `flutter doctor`.

## Windows: bloqueio do SDK pelo Git

Se aparecer `detected dubious ownership` no SDK instalado em `C:/Dev/flutter`, execute com seu usuário normal:

```sh
git config --global --add safe.directory C:/Dev/flutter
flutter doctor
```

## Referências

- Material da disciplina: Pokedex_Flutter_Navegacao_API.pptx e pokedex_aluno_codigo_base.zip, professores Cristiano Neto e Cleiton Silva Tavares.
- [Documentação da PokéAPI](https://pokeapi.co/docs/v2/)

Pokémon e seus nomes são marcas de Nintendo, Game Freak e Creatures. Projeto para uso educacional.
