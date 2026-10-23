import 'package:flutter/material.dart';

class Popup {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, String message){

    if(_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ]
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )
                  )
                )
              ],
            )
          )
        ),
      )
    );

    Overlay.of(context).insert(_overlayEntry!);

  }

  static void hide(){
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
