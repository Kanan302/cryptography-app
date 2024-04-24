import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore_for_file: use_build_context_synchronously
class TextPage extends StatefulWidget {
  const TextPage({Key? key}) : super(key: key);

  @override
  State<TextPage> createState() => _TextPageState();
}

class _TextPageState extends State<TextPage> {
  final TextEditingController _textController = TextEditingController();
  String _encryptedText = "";
  String _decryptedText = "";

  String _encryptAES(String text, String signature) {
    final key = encrypt.Key.fromUtf8("01234567890123456789012345678901");
    final iv = encrypt.IV.fromUtf8('0123456789012345');

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(text + signature, iv: iv);
    return encrypted.base64;
  }

  String _decryptAES(String encryptedText, String signature) {
    final key = encrypt.Key.fromUtf8("01234567890123456789012345678901");
    final iv = encrypt.IV.fromUtf8('0123456789012345');

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
    final decryptedText =
        decrypted.substring(0, decrypted.length - signature.length);
    return decryptedText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
              child: Padding(
            padding:
                const EdgeInsets.only(top: 30, left: 8, right: 8, bottom: 8),
            child: Column(
              children: [
                TextField(
                  maxLines: null,
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _encryptedText = _encryptAES(
                          _textController.text, 'YourSignatureHere');
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.of(context).size.width, 45),
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
                  onPressed: () {
                    setState(() {
                      _decryptedText =
                          _decryptAES(_encryptedText, 'YourSignatureHere');
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.of(context).size.width, 45),
                    backgroundColor: const Color(0xFF4B6191),
                  ),
                  child: const Text(
                    'Decrypt',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_encryptedText.isNotEmpty) {
                      CollectionReference collref =
                          FirebaseFirestore.instance.collection('aes_crypto');
                      collref.add({'data': _encryptedText});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Encrypted data added to the database!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('No encrypted data to save'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.of(context).size.width, 45),
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
                    QuerySnapshot querySnapshot = await FirebaseFirestore
                        .instance
                        .collection('aes_crypto')
                        .where('data', isEqualTo: _encryptedText)
                        .get();

                    if (querySnapshot.docs.isNotEmpty) {
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
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.of(context).size.width, 45),
                    backgroundColor: const Color(0xFF4B6191),
                  ),
                  child: const Text(
                    'Check',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Text(
                  _encryptedText,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  _decryptedText,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }
}
