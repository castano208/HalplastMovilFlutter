import 'package:flutter/material.dart';
import 'package:halplast/crearNuevoPassword.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';

class RecuperarPasswordPagina extends StatefulWidget {
  @override
  RecuperarPassword createState() => RecuperarPassword();
}

 class RecuperarPassword extends State<RecuperarPasswordPagina> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _recoverPassword() async {
    final response = await http.post(
      Uri.parse('https://apihalplast.onrender.com/api/usuarios/recuperarPassword'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'correo': _emailController.text,
      }),
    );

    if (response.statusCode == 200) {
      await Flushbar(
        message: 'Correo enviado correctamente',
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
        MaterialPageRoute(builder: (context) => CrearNuevoPassword()),
      );
    } else {
      await Flushbar(
        message: 'Error al enviar el correo',
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
            Text(
              'Recuperar Contraseña',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _recoverPassword,
              child: Text('Confirmar Correo'),
            ),
             SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Iniciar Sesion'),
            ),
            SizedBox(height: 60.0),
          ],
        ),
      ),
    );
  }
}