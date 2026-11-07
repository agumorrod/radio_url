import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'home_screen.dart';
import 'radios_screen.dart';
import 'favorites_screen.dart';

/// Shell principal con la barra de navegación inferior
/// Contiene las 3 pestañas: Inicio, Emisoras, Favoritos
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RadiosScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Al cambiar de pestaña soltamos el foco del buscador (si lo tenía)
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radio_outlined),
              activeIcon: Icon(Icons.radio),
              label: 'Emisoras',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
          ],
        ),
      ),
    );
  }
}
