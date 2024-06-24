import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:halplast/misPedidosTerminados.dart';
import 'package:halplast/misPedidosActuales.dart';
import 'package:halplast/main.dart';
import 'package:halplast/chat.dart' as chat;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PaginaDetallePedidos extends StatefulWidget {
  final String pedidoId;
  final String correo;
  final String nombre;
  final int numeroPedido;
  final String id;

  PaginaDetallePedidos({required this.pedidoId, required this.correo, required this.numeroPedido, required this.nombre, required this.id});

  @override
  _PaginaDetallePedidosState createState() => _PaginaDetallePedidosState();
}

class _PaginaDetallePedidosState extends State<PaginaDetallePedidos> {
  Pedido? _pedido;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late bool isChatActive = false;

  @override
  void initState() {
    super.initState();
    _fetchPedido();
    _verificarEstadoChat();
  }

  Future<void> _fetchPedido() async {
    try {
      final response = await http.get(
        Uri.parse('https://apihalplast.onrender.com/api/envios/detalles/' + widget.pedidoId),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _pedido = Pedido.fromJson(data);
        });
      } else {
        _showErrorSnackBar('Error al cargar el pedido');
      }
    } catch (error) {
      _showErrorSnackBar('Error de conexión');
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

  void _showErrorSnackBar(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

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
                Navigator.pop(context);
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
                Navigator.pop(context);
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
      body: _pedido == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Detalles del pedido número ${widget.numeroPedido}',
                        style: TextStyle(fontSize: 30.0),
                      ),
                      SizedBox(height: 20),
                      ExpansionPanelList(
                        expansionCallback: (int index, bool isExpanded) {
                          setState(() {
                            _pedido!.detalleVenta[index].isExpanded =
                                !_pedido!.detalleVenta[index].isExpanded;
                          });
                        },
                        children: _pedido!.detalleVenta
                            .asMap()
                            .entries
                            .map<ExpansionPanel>((entry) {
                          DetalleVenta detalle = entry.value;
                          return ExpansionPanel(
                            headerBuilder: (BuildContext context, bool isExpanded) {
                              return ListTile(
                                title: Text('Producto ${detalle.medidaVenta}'),
                              );
                            },
                            body: Column(
                              children: [
                                Card(
                                  elevation: 2.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text('Fecha de Venta: ${detalle.fechaVenta}',
                                            style: TextStyle(fontSize: 16)),
                                        SizedBox(height: 8),
                                        Text('Cantidad: ${detalle.cantidad}',
                                            style: TextStyle(fontSize: 16)),
                                        SizedBox(height: 8),
                                        Text('Color: ${detalle.color}',
                                            style: TextStyle(fontSize: 16)),
                                        SizedBox(height: 8),
                                        Text('Precio: \$${detalle.precio}',
                                            style: TextStyle(fontSize: 16)),
                                        if (detalle.descripcion != "vacio") ...[
                                          SizedBox(height: 8),
                                          Text('Descripcion: ${detalle.descripcion}',
                                              style: TextStyle(fontSize: 16)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                            isExpanded: detalle.isExpanded,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class Pedido {
  Pedido({
    required this.detalleVenta,
  });

  final List<DetalleVenta> detalleVenta;

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      detalleVenta: (json['detalleVenta'] as List)
          .map((item) => DetalleVenta.fromJson(item))
          .toList(),
    );
  }
}

class DetalleVenta {
  DetalleVenta({
    required this.fechaVenta,
    required this.medidaVenta,
    required this.descripcion,
    required this.cantidad,
    required this.color,
    required this.precio,
    this.isExpanded = false,
  });

  final String fechaVenta;
  final String medidaVenta;
  final String descripcion;
  final int cantidad;
  final String color;
  final double precio;
  bool isExpanded;

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      fechaVenta: json['fechaVenta'] ?? 'No especificada',
      medidaVenta: json['medidaVenta'] ?? 'No especificada',
      descripcion: json['descripcion'] ?? 'No especificada',
      cantidad: json['cantidad'] ?? 0,
      color: json['color'] ?? 'No especificado',
      precio: json['precio']?.toDouble() ?? 0.0,
    );
  }
}

void main() {
  runApp(MaterialApp(
    navigatorKey: navigatorKey,
    home: MyApp(),
  ));
}
