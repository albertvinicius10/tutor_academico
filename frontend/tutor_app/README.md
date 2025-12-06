# 📱 Tutor Acadêmico App (Frontend)

Este é o aplicativo mobile do projeto **Tutor Acadêmico**, construído com **Flutter**. Ele serve como a interface de usuário para interagir com a [API do Tutor Acadêmico](../backend/README.md), permitindo que estudantes conversem com um tutor de IA, gerem planos de estudo e recebam recomendações de conteúdo.

---

## ✨ Principais Funcionalidades

O aplicativo oferece uma experiência de usuário limpa e focada no aprendizado, com as seguintes funcionalidades:

✔️ **Autenticação Segura**: Tela de boas-vindas, registro e login de usuários.
✔️ **Chat Inteligente**: Converse com um tutor IA (OpenAI ou Gemini) com persistência de histórico.
✔️ **Lista de Conversas**: Acesse e continue conversas anteriores a qualquer momento.
✔️ **Gerador de Roadmaps**: Crie planos de estudo detalhados sobre qualquer tópico.
✔️ **Recomendações de Vídeo**:
  - Uma seção "Para Você" com sugestões personalizadas com base no seu histórico.
  - Uma busca manual para encontrar vídeos educacionais no YouTube.

---

## ⚙️ Tecnologias e Pacotes

| Tecnologia/Pacote | Descrição |
|-------------------|-----------|
| **Flutter 3** | Framework principal para a construção da UI multiplataforma. |
| **Dart** | Linguagem de programação utilizada. |
| **`http`** | Para realizar as chamadas à API REST do backend. |
| **`google_fonts`** | Para uma tipografia elegante e consistente. |
| **`intl`** | Para formatação de datas e horas. |
| **`url_launcher`**| Para abrir os links dos vídeos recomendados no navegador ou app do YouTube. |

---

## 📁 Estrutura do Projeto

O código-fonte está organizado para facilitar a manutenção e escalabilidade:

```text
lib/
├── api/
│   └── api_service.dart      # Lógica de comunicação com a API e modelos de dados
│
├── screens/
│   ├── auth_screen.dart          # Tela de Login e Registro
│   ├── chat_screen.dart          # Lista de conversas existentes
│   ├── conversation_screen.dart  # Tela de chat com o tutor
│   ├── home_screen.dart          # Tela principal com navegação (BottomNavigationBar)
│   ├── roadmap_screen.dart       # Lista de roadmaps gerados
│   ├── roadmap_detail_screen.dart# Detalhes de um roadmap específico
│   └── video_recommendation_screen.dart # Tela de recomendação de vídeos
│
└── main.dart                 # Ponto de entrada do aplicativo e configuração do tema
```

---

## 🚀 Como Rodar o Aplicativo

### 1. Pré-requisitos
- Ter o **Backend** rodando. Siga as instruções aqui.
- Ter o **Flutter SDK** instalado na sua máquina.

### 2. Configuração da API

O endereço da API está definido no arquivo `lib/api/api_service.dart`. O valor padrão é otimizado para o emulador do Android:

```dart
// lib/api/api_service.dart
const String _apiBaseUrl = 'http://10.0.2.2:8000';
```

- **Emulador Android**: Mantenha `10.0.2.2`.
- **Emulador iOS ou Dispositivo Físico na mesma rede**: Altere para o endereço IP local da sua máquina (ex: `http://192.168.1.10:8000`).

### 3. Instalar Dependências

Navegue até a pasta do projeto e execute:
```bash
flutter pub get
```

### 4. Executar o App

Conecte um dispositivo ou inicie um emulador e execute:
```bash
flutter run
```

