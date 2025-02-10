import 'package:flutter/material.dart';
import 'package:raccoon/raccoon_service.dart';

class RaccoonOverlayWidget extends StatefulWidget {
  const RaccoonOverlayWidget({super.key});

  @override
  RaccoonOverlayWidgetState createState() => RaccoonOverlayWidgetState();
}

class RaccoonOverlayWidgetState extends State<RaccoonOverlayWidget>
    with SingleTickerProviderStateMixin {
  Offset position = const Offset(100, 100); // Initial position
  late Size screenSize;
  late double bottomSafeArea;

  void _snapToSideOnInit() {
    final double middleX = screenSize.width / 2;
    final double finalX = position.dx < middleX ? 0 : screenSize.width - 40;

    setState(() {
      position = Offset(
        finalX,
        position.dy.clamp(0, screenSize.height - 40 - bottomSafeArea),
      );
    });
  }

  void _snapToSide() {
    final double middleX = screenSize.width / 2;
    final double finalX = position.dx < middleX ? 0 : screenSize.width - 40;

    setState(() {
      position = Offset(
        finalX,
        position.dy.clamp(0, screenSize.height - 40 - bottomSafeArea),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _snapToSideOnInit();
    });
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    bottomSafeArea = MediaQuery.of(context).padding.bottom + 56;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
            position = Offset(
              position.dx.clamp(0, screenSize.width - 40),
              position.dy.clamp(0, screenSize.height - 40 - bottomSafeArea),
            );
          });
        },
        onPanEnd: (_) {
          _snapToSide();
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: RaccoonService().navigateToCallListScreen,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.bug_report,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
