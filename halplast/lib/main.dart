import 'package:flutter/material.dart';

import 'package:halplast/cambiarPassword.dart';
import 'package:halplast/chat.dart';
import 'package:halplast/vistaInicial.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:provider/provider.dart';

import 'package:another_flushbar/flushbar.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final response = await http.post(
      Uri.parse('https://apihalplast.onrender.com/api/usuarios/confirmarPassword'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'correo': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      await Flushbar(
        message: 'Inicio de sesión exitoso',
        icon: Icon(
          Icons.check_circle,
          size: 28.0,
          color: Color.fromARGB(255, 0, 255, 8),
        ),
        duration: Duration(seconds: 2),
        leftBarIndicatorColor: Color.fromARGB(255, 0, 255, 8),
        backgroundColor: Color.fromARGB(255, 55, 52, 52),
      ).show(context);

      await Future.delayed(Duration(seconds: 1));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VistaGeneral(id: data['_id'], correo: data['correo']),
        ),
      );
    } else {
      await Flushbar(
        message: 'Correo o contraseña incorrecta',
        icon: Icon(
          Icons.error,
          size: 28.0,
          color: Colors.red,
        ),
        duration: Duration(seconds: 2),
        leftBarIndicatorColor: Colors.red,
        backgroundColor: const Color.fromARGB(255, 55, 52, 52),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 60.0),
            Container(
              width: 200.0,
              height: 200.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage('https://raw.githubusercontent.com/castano208/imagenesHalplast/main/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20.0),
            // Mensaje de bienvenida
            Text(
              '¡Bienvenido a Halplast!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            // Email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            // Password field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20.0),


            ElevatedButton(
              onPressed: _login,
              child: Text('Iniciar Sesion'),
            ),
            SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecuperarPasswordPagina()),
                );
              },
              child: Text('¿Olvidaste tu contraseña?'),
            ),
            SizedBox(height: 60.0), // Espacio extra al final
          ],
        ),
      ),
    );
  }
}
