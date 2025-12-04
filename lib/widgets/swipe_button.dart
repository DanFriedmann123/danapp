import 'package:flutter/material.dart';

class SwipeButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onSwipe;
  final double threshold;
  final double height;
  final bool enabled;

  const SwipeButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onSwipe,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    this.threshold = 0.8,
    this.height = 60,
    this.enabled = true,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  double _dragDistance = 0.0;
  bool _isSwiped = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onSwipeComplete() {
    if (!_isSwiped && widget.enabled) {
      setState(() {
        _isSwiped = true;
      });
      _animationController.forward().then((_) {
        widget.onSwipe();
        _resetButton();
      });
    }
  }

  void _resetButton() {
    setState(() {
      _isSwiped = false;
      _dragDistance = 0.0;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _onSwipeComplete : null,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(color: widget.backgroundColor, width: 2),
        ),
        child: Stack(
          children: [
            // Background with text
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: widget.textColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Sliding button
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Positioned(
                  left:
                      _dragDistance *
                      (MediaQuery.of(context).size.width - 40 - widget.height),
                  child: GestureDetector(
                    onPanUpdate:
                        widget.enabled
                            ? (details) {
                              setState(() {
                                _dragDistance +=
                                    details.delta.dx /
                                    (MediaQuery.of(context).size.width -
                                        40 -
                                        widget.height);
                                _dragDistance = _dragDistance.clamp(0.0, 1.0);
                              });
                            }
                            : null,
                    onPanEnd:
                        widget.enabled
                            ? (details) {
                              if (_dragDistance >= widget.threshold) {
                                _onSwipeComplete();
                              } else {
                                _resetButton();
                              }
                            }
                            : null,
                    child: Container(
                      width: widget.height,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: widget.backgroundColor,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SwipeActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final bool enabled;

  const SwipeActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(25),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
