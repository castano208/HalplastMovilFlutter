import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:halplast/misPedidosActuales.dart';
import 'package:halplast/misPedidosTerminados.dart';
import 'package:halplast/main.dart';
import 'package:halplast/chat.dart' as chat;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PqrsPagina extends StatefulWidget {
  final String correo;
  final String pedidoId;
  final String nombre;
  final String id;

  PqrsPagina({required this.correo, required this.pedidoId,required this.nombre, required this.id});

  @override
  _PqrsPaginaState createState() => _PqrsPaginaState(correo: correo);
}

class _PqrsPaginaState extends State<PqrsPagina> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String correo;
  String? selectedType;
  String? selectedReason;
  List<String> types = [];
  Map<String, List<String>> reasons = {};
  final TextEditingController _descriptionController = TextEditingController();
  late bool isChatActive = false;

  _PqrsPaginaState({required this.correo});

  @override
  void initState() {
    super.initState();
    fetchData();
    _verificarEstadoChat();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('https://apihalplast.onrender.com/api/tipoPqrs'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        types = data['tipos'].map<String>((tipo) => tipo['nombre'] as String).toList();
        reasons = Map.fromIterable(data['tipos'],
          key: (tipo) => tipo['nombre'] as String,
          value: (tipo) => (tipo['motivos'] as List).map<String>((motivo) => motivo['nombre'] as String).toList(),
        );
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _sendPqrs() async {
    final String url = 'https://apihalplast.onrender.com/api/pqrs';
    final Map<String, dynamic> pqrsData = {
      'remitente': widget.correo,
      'pedido': widget.pedidoId,
      'razon': {
        'tipo': selectedType,
        'motivo': selectedReason,
      },
      'descripcion': _descriptionController.text,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(pqrsData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PQRS enviado correctamente')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaginaPedidos(correo: widget.correo, nombre: widget.nombre, id: widget.id),
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar PQRS')),
      );
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

  void _loadChatInfo() async {
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
        throw Exception('Failed to load chat data');
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
                Scaffold.of(context).openDrawer();
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
                  fontSize: 24,
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
                  MaterialPageRoute(builder: (context) => PaginaPedidos(correo: widget.correo, nombre: widget.nombre, id: widget.id)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Historial de pedidos'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaginaPedidosTerminados(correo: widget.correo, nombre: widget.nombre, id: widget.id)),
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
                widget.nombre,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'PQRS',
                style: TextStyle(fontSize: 30.0),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedType,
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                    selectedReason = null;
                  });
                },
                items: types.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Motivo',
                  border: OutlineInputBorder(),
                ),
                value: selectedReason,
                items: reasons[selectedType ?? '']?.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList() ?? [],
                onChanged: (String? newValue) {
                  setState(() {
                    selectedReason = newValue;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendPqrs,
                child: Text('Enviar'),
              ),
            ],
          ),
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
