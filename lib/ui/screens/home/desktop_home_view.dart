import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/data/constants.dart';
import 'package:tipitaka_pali/providers/navigation_provider.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import '../reader/reader_container.dart';
import 'dekstop_navigation_bar.dart';
import 'navigation_pane.dart';

class DesktopHomeView extends StatefulWidget {
  const DesktopHomeView({super.key});

  @override
  State<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends State<DesktopHomeView>
    with SingleTickerProviderStateMixin {
  late double panelWidth;

  late final AnimationController _animationController;
  late final Tween<double> _tween;
  late final Animation<double> _animation;

  late final NavigationProvider navigationProvider;

  @override
  void initState() {
    super.initState();
    // width = Prefs.panelSize.toDouble();
    panelWidth = Prefs.panelWidth;
    navigationProvider = context.read<NavigationProvider>();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: Prefs.animationSpeed.round()),
    );

    _tween = Tween(begin: 1.0, end: 0.0);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    navigationProvider.addListener(_openCloseChangedListener);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openCloseChangedListener() {
    final isOpened = navigationProvider.isNavigationPaneOpened;
    debugPrint('isOpened: $isOpened');
    debugPrint('is animation complete: ${_animationController.isCompleted}');
    debugPrint('animation value: ${_animationController.value}');
    debugPrint('tween value: ${_tween.evaluate(_animation)}');
    if (isOpened) {
      _animationController.reverse();
    } else {
      _animationController.forward();
      // _animatedIconController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // RydMike: Avoid things like this, prefer using themes correctly!
    //   But OK sometimes needed, but rarely. Not sure why this is used in
    //   conditional build below. Looks like some temp experiment. :)
    return Stack(
      children: [
        Row(
          children: [
            // Navigation Rail
            Container(
              decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey))),
              child: const DeskTopNavigationBar(),
            ),
            // Navigation Pane
            SizeTransition(
              sizeFactor: _tween.animate(_animation),
              axis: Axis.horizontal,
              axisAlignment: 1,
              child: SizedBox(
                width: panelWidth,
                child: const DetailNavigationPane(navigationCount: 7),
              ),
            ),
// drag bar
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  setState(() {
                    final screenWidth = MediaQuery.of(context)
                        .size
                        .width; // Get the current window width
                    final maxWidth = screenWidth -
                        300; // Assuming you want to leave at least 300px for the rest of the content
                    const minWidth = 250.0;

                    panelWidth += details.primaryDelta ?? 0;
                    panelWidth = panelWidth.clamp(
                        minWidth, maxWidth); // Apply dynamic constraints
                    Prefs.panelWidth =
                        panelWidth; // Optionally save the new width to preferences
                  });
                },
                child: Container(
                  alignment: Alignment.centerRight,
                  color: Colors.transparent, // Transparent outer container
                  width: 15, // Larger area for easier mouse interaction
                  child: Container(
                    width: 3,
                    color: Colors.grey, // Visible drag handle
                  ),
                ),
              ),
            ),

            // reader view
            const Expanded(child: ReaderContainer()),
          ],
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: SizedBox(
            width: navigationBarWidth,
            height: 64,
            child: Center(
              child: IconButton(
                  onPressed: () =>
                      context.read<NavigationProvider>().toggleNavigationPane(),
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.arrow_menu,
                    // progress: _animatedIconController,
                    progress: _animationController.view,
                  )),
            ),
          ),
        )
      ],
    );
  }
}
