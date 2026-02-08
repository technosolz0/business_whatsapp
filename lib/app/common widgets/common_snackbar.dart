import 'dart:async';
import 'package:flutter/material.dart';

enum SnackAlignment { TOP, CENTER, BOTTOM }

enum SnackType {
  ERROR(Icons.error),
  INFO(Icons.info_rounded),
  SUCCESS(Icons.check_circle);

  const SnackType(this.icon);
  final IconData icon;
}

class CustomSnackbar {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static OverlayEntry _createOverlayEntry(
    String? message,
    SnackAlignment alignment,
    SnackType type,
    bool leftAligned,
    bool rightAligned,
  ) {
    return OverlayEntry(
      builder: (context) => Stack(
        alignment: Alignment.center,
        // Without Stack we will not able to align our Snackbar at center of widget
        children: [
          Positioned(
            top: alignment == SnackAlignment.TOP ? kToolbarHeight + 10 : null,
            left: leftAligned ? 20 : null,
            right: rightAligned ? 20 : null,
            bottom: alignment == SnackAlignment.BOTTOM ? kToolbarHeight : null,
            child: Material(
              // color: Colors.black54,
              color: type == SnackType.ERROR
                  // ? Colors.red.shade300
                  ? Colors.red
                  : type == SnackType.SUCCESS
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
              borderRadius: BorderRadius.circular(5),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(type.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          if (_overlayEntry != null) {
                            if (_overlayEntry != null) {
                              _overlayEntry?.remove();
                              _overlayEntry = null;
                              _timer?.cancel();
                            }
                          }
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static show({
    String? message,
    required BuildContext context,
    SnackAlignment alignment = SnackAlignment.BOTTOM,
    SnackType type = SnackType.SUCCESS,
    bool leftAligned = false,
    bool rightAligned = false,
  }) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _timer?.cancel();
    }

    _overlayEntry = _createOverlayEntry(
      message!,
      alignment,
      type,
      leftAligned,
      rightAligned,
    );
    _insertOverlay(context);
  }

  static _insertOverlay(BuildContext context) async {
    Navigator.of(context).overlay!.insert(_overlayEntry!);

    _timer = Timer(const Duration(seconds: 3), () {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _timer?.cancel();
      }
    });
  }
}
