# 🌟 Tutor Acadêmico API  
### 🚀 A Plataforma Inteligente para Auxiliar Estudantes com Tecnologia de Ponta

O **Tutor Acadêmico API** é uma solução moderna construída com **FastAPI**, **LLMs avançados** (OpenAI + Google Gemini), autenticação segura com **JWT**, persistência robusta com **PostgreSQL**, e um aplicativo **Flutter** para interação dos usuários.  

Ele foi projetado para oferecer **respostas inteligentes**, **memória de conversa** e futuramente **recomendações personalizadas de aprendizado**.

---

# 📘 Sumário  
- [✨ Visão Geral](#-visão-geral)  
- [🧠 Principais Funcionalidades](#-principais-funcionalidades)  
- [⚙️ Tecnologias Utilizadas](#️-tecnologias-utilizadas)  
- [📁 Estrutura do Projeto](#-estrutura-do-projeto)  
- [🐳 Como Rodar o Backend](#-como-rodar-o-backend)  
- [📱 Como Rodar o Frontend](#-como-rodar-o-frontend)  
- [🧭 Como Usar o Aplicativo](#-como-usar-o-aplicativo)  
- [📡 Uso da API](#-uso-da-api)  
- [🔮 Roadmap Futuro](#-roadmap-futuro)  
- [📌 Informações Complementares](#-informações-complementares)

---

# ✨ Visão Geral

O Tutor Acadêmico API foi criado para ser:

- 🧠 **Inteligente** — capaz de manter o contexto da conversa  
- 📚 **Educacional** — orientado para auxiliar estudantes  
- ⚡ **Rápido e Escalável** — graças ao FastAPI e Docker  
- 🔐 **Seguro** — com autenticação JWT  
- 📲 **Completo** — com um app Flutter integrado  

---

# 🧠 Principais Funcionalidades

✔️ Chat com contexto  
✔️ Histórico de conversas  
✔️ Autenticação JWT  
✔️ Escolha entre **OpenAI** ou **Google Gemini**  
✔️ Arquitetura dockerizada  
✔️ App Flutter integrado à API  

---

# ⚙️ Tecnologias Utilizadas

| Tecnologia | Descrição |
|-----------|-----------|
| **FastAPI** | Backend rápido e assíncrono |
| **Python 3.11** | Linguagem principal |
| **PostgreSQL** | Armazenamento de usuários e conversas |
| **Docker & Docker Compose** | Ambientes reproduzíveis |
| **SQLAlchemy** | ORM para modelagem e queries |
| **LangChain** | Orquestração de modelos de linguagem |
| **OpenAI** | Respostas inteligentes |
| **Google Gemini** | Alternativa de LLM avançada |
| **JWT** | Autenticação segura |
| **Flutter** | Aplicativo mobile para o usuário final |

---

# 📁 Estrutura do Projeto

```text
tutor_academico/
├── backend/
│   ├── app/
│   │   ├── main.py          # Ponto de entrada da API
│   │   ├── config.py        # Variáveis de ambiente
│   │   ├── db.py            # Conexão com o banco PostgreSQL
│   │   ├── models.py        # Modelos SQLAlchemy
│   │   ├── schemas.py       # Schemas Pydantic
│   │   ├── auth.py          # Autenticação JWT
│   │   └── chat.py          # Chat e processamento LLM
│   │
│   ├── .env                 # Variáveis de ambiente
│   ├── requirements.txt     # Dependências Python
│   ├── Dockerfile           # Build do backend
│   └── docker-compose.yml   # Orquestração backend + banco
│
└── frontend/
    └── tutor_app/           # Aplicativo Flutter

yaml
Copiar código

---

# 🐳 Como Rodar o Backend

## 1️⃣ Criar o arquivo `.env`

Na pasta `backend/`:

```env
DATABASE_URL=postgresql+psycopg2://user:password@db:5432/tutor_academico
SECRET_KEY=sua_chave_secreta_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
OPENAI_API_KEY=sua_chave_openai
GOOGLE_API_KEY=sua_chave_gemini
DEFAULT_LLM_PROVIDER=openai
2️⃣ Subir o ambiente com Docker
bash
Copiar código
docker-compose up --build
✔️ O --build garante atualização das variáveis e dependências.

3️⃣ Acessar a API
🔗 API Base: http://localhost:8000

📘 Swagger: http://localhost:8000/docs

📕 Redoc: http://localhost:8000/redoc

📱 Como Rodar o Frontend (Flutter)
1️⃣ Abrir a pasta do app
bash
Copiar código
cd frontend/tutor_app
2️⃣ Instalar dependências
bash
Copiar código
flutter pub get
3️⃣ Executar o app
bash
Copiar código
flutter run
🧭 Como Usar o Aplicativo
Criar conta ou fazer login

Autenticação via JWT

Acessar a lista de conversas

Criar nova conversa (+)

Interagir com o tutor — respostas inteligentes e histórico salvo 🎯

📡 Uso da API
🔐 Autenticação
POST /auth/register

POST /auth/login → devolve token JWT

No Swagger clique: Authorize → Bearer <seu_token>

💬 Chat
Enviar mensagem:

bash
Copiar código
POST /chat/
Primeira requisição → cria a conversa

Próximas → enviar conversation_id para manter o contexto

🔮 Roadmap Futuro
🚧 Em desenvolvimento para as próximas versões:

📘 Recomendação personalizada de conteúdos

📄 Upload e leitura de PDFs

📊 Dashboard de aprendizado

🎯 Seleção de matéria/tema

🔎 Busca inteligente no histórico

📌 Informações Complementares
Arquitetura totalmente modular

Fácil integração com novos LLMs

Backend otimizado para produção

Frontend rápido e simples de usar

🎉 Agradecimentos
Obrigado por utilizar o Tutor Acadêmico API!
Sinta-se livre para contribuir, abrir issues ou sugerir funcionalidades.