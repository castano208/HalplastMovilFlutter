import 'package:flutter/material.dart';
import 'package:halplast/main.dart';
import 'package:halplast/misPedidosActuales.dart';
import 'package:halplast/misPedidosTerminados.dart';
import 'package:halplast/chat.dart' as chat;
import 'package:http/http.dart' as http;
import 'dart:convert';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class VistaGeneral extends StatefulWidget {
  final String id;
  final String correo;
  VistaGeneral({required this.id, required this.correo});

  @override
  _VistaGeneralState createState() => _VistaGeneralState();
}

class _VistaGeneralState extends State<VistaGeneral> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String nombre;
  late bool isLoading;
  late bool isChatActive = false;

  @override
  void initState() {
    super.initState();
    nombre = '';
    isLoading = true;
    _obtenerDatosUsuario();
    _verificarEstadoChat();
  }

  Future<void> _obtenerDatosUsuario() async {
    final response = await http.get(
      Uri.parse('https://apihalplast.onrender.com/api/usuarios/' + widget.id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        nombre = data['nombre'] ?? '';
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al obtener datos del usuario'),
      ));
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _verificarEstadoChat() async {
    try {
      final response1 = await http.get(Uri.parse('https://apihalplast.onrender.com/api/chatPqrs/unico/${widget.id}'));
      if (response1.statusCode == 200) {
        final Map<String, dynamic> chatInfo1 = jsonDecode(response1.body);
        String ChatId = chatInfo1['_id'];
        final response = await http.get(
          Uri.parse('https://apihalplast.onrender.com/api/chatPqrs/estado/$ChatId'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['estado'] == "Activo") {
            setState(() {
              isChatActive = true;
            });
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _loadChatInfo() async {
    try {
      final response = await http.get(Uri.parse('https://apihalplast.onrender.com/api/chatPqrs/unico/${widget.id}'));
      if (response.statusCode == 200) {
        String OtroUsuario;
        final Map<String, dynamic> chatInfo = jsonDecode(response.body);
        String sistemaChatId = chatInfo['_id'];
        if (widget.correo != chatInfo['cliente']) {
          OtroUsuario = chatInfo['cliente'];
        } else {
          OtroUsuario = chatInfo['empleado'];
        }
        final response2 = await http.get(Uri.parse('https://apihalplast.onrender.com/api/usuario/rol/${widget.correo}'));
        if (response2.statusCode == 200) {
          final Map<String, dynamic> RolInfo = jsonDecode(response2.body);
          String RolUsuario = RolInfo['rol'];
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => chat.ChatScreen(sistemaChatId: sistemaChatId, userId: widget.correo, userRol: RolUsuario, OtroUsuario: OtroUsuario)),
          );
        }
      } else {
        throw Exception('Fallo cargando informacion del chat');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void notificacionCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.lightBlue[50],
          child: WillPopScope(
            onWillPop: () async => false,
            child: Container(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20.0),
                  Text(
                    'Cerrando sesión...',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Halplast'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            );
          },
        ),
        backgroundColor: Color.fromARGB(255, 186, 224, 233),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 186, 224, 233),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.align_horizontal_left_rounded),
              title: Text('Opciones de pedido'),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Mis pedidos actuales'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaginaPedidos(correo: widget.correo, nombre: nombre, id: widget.id)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Historial de pedidos'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaginaPedidosTerminados(correo: widget.correo, nombre: nombre, id: widget.id)),
                );
              },
            ),
            if (isChatActive)
              ListTile(
                leading: Icon(Icons.chat),
                title: Text('Chat'), 
                onTap: _loadChatInfo,
              ),
            SizedBox(height: 190),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Cerrar sesión'),
              onTap: () {
                notificacionCerrarSesion(context);
              },
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.all(50),
                child: Image.network(
                  "https://www.iconpacks.net/icons/2/free-user-icon-3296-thumb.png",
                ),
              ),
              Text(
                nombre,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
              SizedBox(height: 20),
              Text(
                widget.correo,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '¡Hola! $nombre, te damos la bienvenida.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '¿En qué podemos ayudarte hoy?',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    navigatorKey: navigatorKey,
    home: MyApp(),
  ));
}
