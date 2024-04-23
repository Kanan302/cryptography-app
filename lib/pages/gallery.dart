import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

// ignore_for_file: use_build_context_synchronously
class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool textScanning = false;
  XFile? imageFile;
  String scannedText = "";
  String encryptedText = "";
  String decryptedText = "";

  void getImage() async {
    try {
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          textScanning = true;
          imageFile = pickedImage;
        });
        getRecognisedText(pickedImage);
      }
    } catch (e) {
      setState(() {
        textScanning = false;
        imageFile = null;
        scannedText = "Error: Something went wrong";
      });
    }
  }

  Future<void> getRecognisedText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognisedText =
        await textDetector.processImage(inputImage);
    await textDetector.close();
    setState(() {
      scannedText = recognisedText.text;
      textScanning = false;
    });

    final encrypted = _encryptAES(scannedText);
    setState(() {
      encryptedText = encrypted;
    });
  }

  String _encryptAES(String text) {
    final key = encrypt.Key.fromUtf8("1234567890123456");
    final iv = encrypt.IV.fromUtf8('0123456789012345');
    const signature = 'YourSignatureHere';

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(text + signature, iv: iv);
    return encrypted.base64;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  if (!textScanning && imageFile == null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        color: const Color(0xFF4B6191),
                        width: 307,
                        height: 253,
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (imageFile != null) Image.file(File(imageFile!.path)),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    maxLines: null,
                    readOnly: true,
                    controller: TextEditingController(text: scannedText),
                    decoration: const InputDecoration(
                      labelText: 'Scanned Text',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    encryptedText,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            shadowColor: Colors.grey[600],
                          ),
                          onPressed: () => getImage(),
                          child: const SizedBox(
                            width: 50,
                            height: 60,
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Icon(
                                  Icons.photo,
                                  color: Color(0xFF1F2F58),
                                ),
                                Text(
                                  'Gallery',
                                  style: TextStyle(color: Color(0xFF1F2F58)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (encryptedText.isNotEmpty) {
                                  CollectionReference collref =
                                      FirebaseFirestore.instance
                                          .collection('aes_crypto');
                                  collref.add({'data': encryptedText});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Encrypted data added to the database!'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.red,
                                      content:
                                          Text('No encrypted data to save'),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                fixedSize: const Size(100, 30),
                                backgroundColor: const Color(0xFF4B6191),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                QuerySnapshot querySnapshot =
                                    await FirebaseFirestore.instance
                                        .collection('aes_crypto')
                                        .where('data', isEqualTo: encryptedText)
                                        .get();

                                if (querySnapshot.docs.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                          'Encrypted data exists in the database'),
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
                              },
                              style: ElevatedButton.styleFrom(
                                  fixedSize: const Size(100, 30),
                                  backgroundColor: const Color(0xFF4B6191)),
                              child: const Text(
                                'Check',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
