import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

// ignore_for_file: use_build_context_synchronously
class DrawPage extends StatefulWidget {
  const DrawPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _DrawPageState createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  List<Offset> points = [];
  String? encryptedPoints;
  late String pointsString;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    color: const Color(0xFF4B6191),
                    width: 367,
                    height: 303,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          RenderBox renderBox =
                              context.findRenderObject() as RenderBox;
                          points.add(
                              renderBox.globalToLocal(details.globalPosition));
                        });
                      },
                      onPanEnd: (details) {},
                      child: CustomPaint(
                        painter: DrawingPainter(points: points),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      points.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(367, 45),
                    backgroundColor: const Color(0xFF4B6191),
                  ),
                  child: const Text(
                    'Clear Drawing',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (points.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content:
                              Text('Please draw something before encrypting!'),
                        ),
                      );
                    } else {
                      pointsString = points
                          .map((offset) => '${offset.dx},${offset.dy}')
                          .join(';');
                      setState(() {
                        encryptedPoints = _encryptPoints(pointsString);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(367, 45),
                    backgroundColor: const Color(0xFF4B6191),
                  ),
                  child: const Text(
                    'Encrypt',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (points.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Please draw something before saving!'),
                        ),
                      );
                    } else {
                      pointsString = points
                          .map((offset) => '${offset.dx},${offset.dy}')
                          .join(';');
                      final encryptedPointsString =
                          _encryptPoints(pointsString);
                      CollectionReference collref =
                          FirebaseFirestore.instance.collection('aes_crypto');
                      collref.add({'data': encryptedPointsString});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Encrypted data added to the database!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(367, 45),
                    backgroundColor: const Color(0xFF4B6191),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (points.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content:
                              Text('Please draw something before checking!'),
                        ),
                      );
                    } else {
                      QuerySnapshot querySnapshot = await FirebaseFirestore
                          .instance
                          .collection('aes_crypto')
                          .get();

                      bool isMatched = false;
                      for (QueryDocumentSnapshot document
                          in querySnapshot.docs) {
                        String encryptedData = document.get('data');
                        String decryptedData = _decryptPoints(encryptedData);
                        if (decryptedData == pointsString) {
                          isMatched = true;
                          break;
                        }
                      }

                      if (isMatched) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Encrypted data exists in the database'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                                'Encrypted data does not exist in the database'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(367, 45),
                    backgroundColor: const Color(0xFF4B6191),
                  ),
                  child: const Text(
                    'Check',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                if (encryptedPoints != null)
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: TextField(
                      maxLines: null,
                      readOnly: true,
                      controller: TextEditingController(
                        text: encryptedPoints,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Encrypted Text',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _encryptPoints(String pointsString) {
    final key = encrypt.Key.fromUtf8("1234567890123456");
    final iv = encrypt.IV.fromUtf8('0123456789012345');

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(pointsString, iv: iv);
    return encrypted.base64;
  }

  String _decryptPoints(String encryptedPointsString) {
    final key = encrypt.Key.fromUtf8("1234567890123456");
    final iv = encrypt.IV.fromUtf8('0123456789012345');

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt64(encryptedPointsString, iv: iv);
    return decrypted;
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
