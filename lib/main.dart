import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mylib/screens/SelectionRole.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mon Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Login(),
    );
  }
}
class Login extends StatelessWidget {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login(BuildContext context) {
    String login = loginController.text.trim();
    String password = passwordController.text.trim();

    if (login == 'Utilisateur' && password == '1') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SelectionRole()),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Login ou mot de passe incorrect.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7EFFA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Logo centré en haut
              Container(
                margin: EdgeInsets.only(top: 40, bottom: 60),
                height: 200,width: 320,
                child: Image.asset('assets/images/logo1.jpg',
                  fit: BoxFit.contain,
                ),
              ),
              // Formulaire de login
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: loginController,
                    decoration: InputDecoration(
                      hintText: 'Login',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Mot de passe',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                    ),
                    child: Text('Entrer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}