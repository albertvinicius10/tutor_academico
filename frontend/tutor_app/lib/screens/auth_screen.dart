import 'package:flutter/material.dart';
import '../api/api_service.dart'; // Importa a lógica da API
import 'home_screen.dart'; // Importa a nova tela principal
import 'package:flutter/gestures.dart'; // Para o RichText

// --- TELAS DE AUTENTICAÇÃO (Auth Screens) ---

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Ícone ou Logo
              Icon(
                Icons.school, // Ícone representativo
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Bem-vindo ao\nTutor Acadêmico',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Seu assistente de estudos pessoal, agora na palma da sua mão.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const AuthScreen(isLogin: true)),
                ),
                child: const Text('Entrar'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const AuthScreen(isLogin: false)),
                ),
                child: const Text('Criar Conta'),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, required this.isLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  late bool _isLogin;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  void _submitAuth() async {
    setState(() => _isLoading = true);
    String? error;
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (_isLogin) {
      error = await apiService.login(username, password);
    } else {
      if (password != _confirmPasswordController.text) {
        error = "As senhas não coincidem.";
      } else {
        error = await apiService.register(username, password);
      }
    }

    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context, // Usar pushAndRemoveUntil para limpar a pilha de navegação
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta';
    final subtitle = _isLogin ? 'Faça login para continuar' : 'Preencha os campos para se registrar';
    final buttonText = _isLogin ? 'Entrar' : 'Registrar';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _usernameController,
                  enableSuggestions: false, 
  autocorrect: false,
  keyboardType: TextInputType.visiblePassword,
  autofillHints: const [],
                  decoration: const InputDecoration(
                    labelText: 'Email ou Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitAuth,
                        child: Text(buttonText),
                      ),
                const SizedBox(height: 24),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: _isLogin ? 'Não tem uma conta? ' : 'Já tem uma conta? ',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      children: [
                        TextSpan(
                          text: _isLogin ? 'Registre-se' : 'Faça login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}