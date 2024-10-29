import 'package:flutter/material.dart';

class BottomNavBarWidget extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBarWidget({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  _BottomNavBarWidgetState createState() => _BottomNavBarWidgetState();
}

class _BottomNavBarWidgetState extends State<BottomNavBarWidget> {
  int _hoveredIndex = -1;

  void _onItemHover(int index) {
    setState(() {
      _hoveredIndex = index;
    });
  }

  void _onItemExit() {
    setState(() {
      _hoveredIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 54, 83, 56),
            Color.fromARGB(255, 54, 83, 56),
          ],
        ),
      ),
      child: SizedBox(
        height: 70,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 4,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: List.generate(
            5,
            (index) => BottomNavigationBarItem(
              icon: MouseRegion(
                onEnter: (_) => _onItemHover(index),
                onExit: (_) => _onItemExit(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: EdgeInsets.all(widget.selectedIndex == index
                      ? 6.0
                      : _hoveredIndex == index
                          ? 6.0
                          : 2.0),
                  decoration: BoxDecoration(
                    color: widget.selectedIndex == index
                        ? const Color.fromARGB(255, 90, 105, 91)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: widget.selectedIndex == index
                        ? [
                            BoxShadow(
                              color: const Color.fromARGB(255, 90, 105, 91)
                                  .withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  transform: widget.selectedIndex == index
                      ? Matrix4.translationValues(0, -12, 0)
                      : Matrix4.identity(),
                  child: Icon(
                    index == 0
                        ? Icons.person
                        : index == 1
                            ? Icons.devices
                            : index == 2
                                ? Icons.dashboard
                                : index == 3
                                    ? Icons.analytics
                                    : Icons.settings,
                    size: widget.selectedIndex == index ? 30 : 26,
                    color: widget.selectedIndex == index
                        ? Color(0xFFe8f5e9)
                        : null,
                  ),
                ),
              ),
              label: (index == 0
                  ? 'Profile'
                  : index == 1
                      ? 'Devices'
                      : index == 2
                          ? 'Dashboard'
                          : index == 3
                              ? 'History'
                              : 'Settings'),
            ),
          ),
          selectedLabelStyle: TextStyle(
            color: Colors.white,
          ),
          currentIndex: widget.selectedIndex,
          selectedItemColor: Color(0xFFe8f5e9),
          unselectedItemColor: const Color.fromARGB(255, 197, 194, 194),
          onTap: widget.onItemTapped,
          selectedFontSize: 10,
          unselectedFontSize: 9,
        ),
      ),
    );
  }
}
