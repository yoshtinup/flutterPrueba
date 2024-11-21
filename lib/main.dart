import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Importa kIsWeb para saber si estás en Web

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subir Imagen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  String? _uploadedImageUrl; // Variable para almacenar la URL de la imagen subida
  final picker = ImagePicker();

  // Método para seleccionar la imagen (cámara o galería)
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No se ha seleccionado ninguna imagen.');
      }
    });
  }

  // Método para subir la imagen al servidor
  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se ha seleccionado ninguna imagen')));
      return;
    }

    final uri = Uri.parse('http://localhost:3000/upload'); // Cambia la URL según tu servidor
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    try {
      final response = await request.send();
      if (response.statusCode == 201) {
        final resString = await response.stream.bytesToString();
        final resData = json.decode(resString);

        setState(() {
          // Guardar la URL de la imagen subida
          _uploadedImageUrl = 'http://localhost:3000/image/${resData['filename']}';
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Imagen subida exitosamente')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al subir la imagen')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subir Imagen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image == null && _uploadedImageUrl == null)
              Text('No se ha seleccionado ninguna imagen.')
            else if (_uploadedImageUrl != null)
              kIsWeb
                  ? Image.network(_uploadedImageUrl!) // Mostrar la imagen subida en Flutter Web
                  : Image.network(_uploadedImageUrl!) // Mostrar la imagen subida en Android/iOS también
            else
              Image.file(_image!), // Mostrar la imagen seleccionada antes de subirla
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text('Seleccionar de Galería'),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Tomar una Foto'),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Subir Imagen'),
            ),
          ],
        ),
      ),
    );
  }
}
