# moovie

Moovie é um aplicativo em Flutter que permite que os usuários descubram, rastreiem e organizem os filmes que assistiram, gostaram ou desejam assistir.

## ✨ Funcionalidades

- 🎬 Explorar filmes populares, mais bem avaliados e que serão lançados em breve.
- 🔍 Pesquisar por filmes específicos.
- ℹ️ Ver detalhes completos do filme, incluindo sinopse, elenco e duração.
- 👤 Sistema de usuários com login e cadastro.
- ❤️ Marcar filmes como favoritos.
- ✅ Marcar filmes como assistidos.
- 📜 Adicionar filmes a uma lista de "Quero Assistir".
- ⭐ Avaliar filmes de 1 a 10.
- 📊 Visualizar estatísticas pessoais, como tempo total de filmes assistidos.

## 🛠️ Tecnologias e Arquitetura

O projeto foi construído utilizando uma arquitetura em camadas para separar responsabilidades, tornando o código mais limpo e escalável.

- **Framework:** [Flutter](https://flutter.dev/)
- **Gerenciamento de Estado:** [Provider](https://pub.dev/packages/provider)
- **Banco de Dados Local:** [sqflite](https://pub.dev/packages/sqflite) para persistência de dados no dispositivo.
- **API:** [The Movie Database (TMDB)](https://www.themoviedb.org/documentation/api) para buscar informações sobre os filmes.
- **Segredos de API:** [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) para gerenciar a chave da API de forma segura.

## 🚀 Como Executar o Projeto

Para rodar este projeto localmente, siga os passos abaixo:

1.  **Pré-requisitos**
    - Ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado em sua máquina.

2.  **Clonar o Repositório**
    ```sh
    git clone https://github.com/guilhermeguidat/moovie.git
    cd moovie
    ```

3.  **Configurar Variáveis de Ambiente**
    - Crie um arquivo chamado `.env` na raiz do projeto.
    - Adicione sua chave da API do TMDB a este arquivo:
      ```
      TMDB_API_KEY=SUA_CHAVE_DE_API_AQUI
      ```

4.  **Instalar Dependências**
    ```sh
    flutter pub get
    ```

5.  **Executar o Aplicativo**
    ```sh
    flutter run
    ```
