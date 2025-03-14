import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  runApp(EmotionRecognitionApp());
}

class EmotionRecognitionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Recognition',
      debugShowCheckedModeBanner: false,
      home: EmotionRecognitionScreen(),
    );
  }
}

class EmotionRecognitionScreen extends StatefulWidget {
  @override
  _EmotionRecognitionScreenState createState() =>
      _EmotionRecognitionScreenState();
}

class _EmotionRecognitionScreenState extends State<EmotionRecognitionScreen> {
  File? _image;
  final picker = ImagePicker();

  // Configura o detector com contornos e classificação habilitados.
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  String _emotionResult = "Nenhuma emoção detectada";

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _emotionResult = "Analisando...";
      });
      await _analyzeEmotion();
    }
  }

  Future<void> _analyzeEmotion() async {
    if (_image == null) return;
    final inputImage = InputImage.fromFile(_image!);
    print("Iniciando detecção de rosto...");

    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);
      print("Detecção finalizada. Rostos encontrados: ${faces.length}");

      String resultText = "";
      if (faces.isEmpty) {
        resultText = "Nenhum rosto detectado.";
      } else {
        for (int i = 0; i < faces.length; i++) {
          Face face = faces[i];
          double? smileProb = face.smilingProbability;
          String emotion = "";
          if (smileProb != null) {
            if (smileProb > 0.8) {
              emotion = "Feliz";
            } else if (smileProb < 0.3) {
              emotion = "Triste";
            } else {
              emotion = "Neutro";
            }
            resultText +=
                "Rosto ${i + 1}: $emotion\nProbabilidade de sorriso: ${smileProb.toStringAsFixed(2)}\n\n";
          } else {
            resultText +=
                "Rosto ${i + 1}: Dados insuficientes para análise.\n\n";
          }
        }
      }

      setState(() {
        _emotionResult = resultText;
      });
    } catch (e) {
      print("Erro na detecção: $e");
      setState(() {
        _emotionResult = "Erro ao processar a imagem.";
      });
    }
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Emotion Recognition')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            _image != null
                ? Image.file(_image!, height: 300)
                : Icon(Icons.image, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                _emotionResult,
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            // Botões para capturar imagem ou selecionar da galeria
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: Text('Tirar Foto'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: Text('Escolher da Galeria'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
