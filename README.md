Tutor Acadêmico API
Bem-vindo ao repositório do Tutor Acadêmico API, um projeto de chatbot inteligente construído com FastAPI para auxiliar estudantes em diversas matérias. A aplicação é capaz de responder a perguntas, manter o contexto das conversas e, futuramente, recomendar conteúdos educacionais.

Tecnologias
O projeto utiliza um stack moderno e robusto para garantir performance, escalabilidade e facilidade de desenvolvimento.

FastAPI: Um framework web de alta performance para a construção da API.

Python 3.11: A linguagem de programação principal do projeto.

PostgreSQL: Um sistema de banco de dados relacional robusto para persistir usuários e conversas.

Docker & Docker Compose: Para gerenciar os ambientes de desenvolvimento e produção de forma consistente.

SQLAlchemy: O ORM (Object-Relational Mapper) para interagir com o banco de dados de forma simples e orientada a objetos.

LangChain: Um framework para orquestrar e gerenciar a interação com modelos de linguagem (LLMs).

OpenAI & Google Gemini: Modelos de linguagem de ponta usados para gerar as respostas do chatbot.

JWT (JSON Web Tokens): Usado para autenticação segura e autorização dos usuários.

Estrutura do Projeto
A organização do projeto segue uma estrutura modular, facilitando a manutenção e a adição de novas funcionalidades.

tutor_academico/
│── app/
│   ├── main.py            # Ponto de entrada da API
│   ├── config.py          # Variáveis de ambiente
│   ├── db.py              # Configuração da conexão com o banco de dados
│   ├── models.py          # Definição dos modelos de dados (SQLAlchemy)
│   ├── schemas.py         # Schemas de validação de dados (Pydantic)
│   ├── utils.py           # Funções utilitárias (criação de token, hash de senha, etc.)
│   ├── auth.py            # Roteador para autenticação de usuários
│   └── chat.py            # Roteador para a lógica principal do chatbot
│
│── .env                   # Variáveis de ambiente para o projeto
│── requirements.txt       # Dependências Python
│── Dockerfile             # Definição da imagem Docker do backend
└── docker-compose.yml     # Orquestração dos serviços (backend e banco de dados)
Como Rodar
Siga estes passos para configurar e rodar o projeto localmente usando Docker.

Pré-requisitos
Certifique-se de que você tem o Docker e o Docker Compose instalados na sua máquina.

1. Clonar o Repositório e Configurar o Ambiente
Primeiro, clone este repositório para o seu ambiente local e navegue até o diretório do projeto.

Em seguida, crie o arquivo de variáveis de ambiente .env na raiz do projeto e preencha com as suas credenciais.

Bash

# Conteúdo do arquivo .env
DATABASE_URL=postgresql+psycopg2://user:password@db:5432/tutor_academico
SECRET_KEY=sua_chave_secreta_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
OPENAI_API_KEY=sua_chave_do_openai_aqui
GOOGLE_API_KEY=sua_chave_do_gemini_aqui
DEFAULT_LLM_PROVIDER=openai # ou 'gemini'
2. Rodar com Docker Compose
Com o arquivo .env configurado, você pode iniciar os contêineres do backend e do banco de dados com um único comando:

Bash

docker-compose up --build
O flag --build é crucial, pois ele reconstrói as imagens, garantindo que as variáveis de ambiente e as dependências mais recentes sejam carregadas.

3. Acessar a API
A API estará disponível em http://localhost:8000. Você pode interagir com os endpoints usando a documentação interativa gerada automaticamente pelo Swagger:

Swagger UI: http://localhost:8000/docs

Redoc: http://localhost:8000/redoc

Como Usar a API
Para interagir com o chatbot, siga estes passos:

Registro / Login: Use os endpoints POST /auth/register ou POST /auth/login para obter um token de acesso.

Autenticação: No Swagger, clique no botão "Authorize" e cole o token obtido, no formato Bearer <seu_token>.

Conversa: Use o endpoint POST /chat/ para iniciar ou continuar uma conversa. A primeira requisição cria uma nova conversa, e as próximas usam o conversation_id para manter o contexto.