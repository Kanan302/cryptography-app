import 'package:flutter/material.dart';
import 'package:cryptography_app/pages/draw.dart';
import 'package:cryptography_app/pages/gallery.dart';
import 'package:cryptography_app/pages/text.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectIndex = index;
    });
  }

  final List<Widget> _pages = [
    const GalleryPage(),
    const DrawPage(),
    const TextPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectIndex,
          onTap: _navigateBottomBar,
          backgroundColor: const Color(0xFF1F2F58),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.white,
          iconSize: 30,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Gallery'),
            BottomNavigationBarItem(icon: Icon(Icons.draw), label: 'Draw'),
            BottomNavigationBarItem(
                icon: Icon(Icons.description), label: 'Text')
          ]),
      body: _pages[_selectIndex],
    );
  }
}
