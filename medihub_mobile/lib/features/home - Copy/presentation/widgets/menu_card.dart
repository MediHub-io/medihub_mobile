import 'package:flutter/material.dart';

class MenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  State<MenuCard> createState() =>
      _MenuCardState();
}

class _MenuCardState
    extends State<MenuCard> {

  bool hovering = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor:
          SystemMouseCursors.click,

      onEnter: (_) {
        setState(() {
          hovering = true;
        });
      },

      onExit: (_) {
        setState(() {
          hovering = false;
        });
      },

      child: GestureDetector(
        onTap: widget.onTap,

        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 150,
          ),

          transform:
              Matrix4.identity()
                ..scale(
                  hovering
                      ? 1.03
                      : 1.0,
                ),

          decoration:
              BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(
              14,
            ),

            boxShadow: [
              BoxShadow(
                color: hovering
                    ? Colors.black26
                    : Colors.black12,

                blurRadius:
                    hovering
                        ? 12
                        : 4,

                offset:
                    const Offset(
                  0,
                  2,
                ),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              CircleAvatar(
                radius: 24,

                backgroundColor:
                    widget.color
                        .withOpacity(
                  .15,
                ),

                child: Icon(
                  widget.icon,
                  size: 28,
                  color:
                      widget.color,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                widget.title,

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}