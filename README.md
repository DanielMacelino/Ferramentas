# Ferramentas

Aplicativo mobile modular desenvolvido em Flutter.

## Configuração Inicial

Como o projeto foi criado manualmente, você precisará gerar os arquivos nativos (Android/iOS) antes de rodar:

1.  Abra o terminal na pasta do projeto.
2.  Execute:
    ```bash
    flutter create .
    ```
3.  Baixe as dependências:
    ```bash
    flutter pub get
    ```

## Estrutura do Projeto

-   **Clean Architecture**: Separação em camadas (core, modules, providers, screens).
-   **Riverpod**: Gerenciamento de estado.
-   **Hive**: Banco de dados local.
-   **Modularização**: Funcionalidades separadas em `modules/`.

## Funcionalidades

-   Navegação com Bottom Bar (Home, Notas, Organização, Configurações).
-   Tema Claro/Escuro (persistido localmente).
