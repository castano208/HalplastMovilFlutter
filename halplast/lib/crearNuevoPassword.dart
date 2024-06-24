import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:halplast/main.dart';
import 'package:another_flushbar/flushbar.dart';

class CrearNuevoPassword extends StatefulWidget {
  @override
  _CrearNuevoPassword createState() => _CrearNuevoPassword();
}

 class _CrearNuevoPassword extends State<CrearNuevoPassword> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  Future<void> _confirmPassword() async {
    final response = await http.post(
      Uri.parse('https://apihalplast.onrender.com/api/usuarios/restablecerPassword'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'correo': _emailController.text,
        'codigoAcceso': _codeController.text,
        'nuevaPassword': _newPasswordController.text,
      }),
    );

    if (response.statusCode == 200) {
      await Flushbar(
        message: 'Contraseña restablecida correctamente',
        icon: Icon(
          Icons.check_circle,
          size: 28.0,
          color: Color.fromARGB(255, 0, 255, 8),
        ),
        duration: Duration(seconds: 2),
        leftBarIndicatorColor: Color.fromARGB(255, 0, 255, 8),
        backgroundColor: const Color.fromARGB(255, 55, 52, 52),
      ).show(context);

      await Future.delayed(Duration(seconds: 1));

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      await Flushbar(
        message: 'Error al restablecer la contraseña',
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
            SizedBox(height: 60.0), // Espacio extra al principio
            // Logo
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
            // Mensaje de confirmación
            Text(
              'Confirmar Contraseña',
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
            // Code field
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Código de Acceso',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            // New password field
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20.0),
            // Confirm button
            ElevatedButton(
              onPressed: _confirmPassword,
              child: Text('Restablecer Contraseña'),
            ),
            SizedBox(height: 20.0),
            // Cancel button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            SizedBox(height: 60.0), // Espacio extra al final
          ],
        ),
      ),
    );
  }
}
