import 'package:flutter/material.dart';

class CustomPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const CustomPhoneField({
    super.key,
    required this.controller,
    this.onChanged,
    this.errorText,
  });

  @override
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onControllerChange);
    _showClearButton = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onControllerChange() {
    final showClear = widget.controller.text.isNotEmpty;
    if (showClear != _showClearButton) {
      setState(() {
        _showClearButton = showClear;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError
                  ? Colors.red.shade400
                  : (_isFocused ? const Color(0xFF0095F6) : Colors.grey.shade300),
              width: _isFocused || hasError ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF0095F6).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Country Code Prefix
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🇮🇳',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
                // Vertical Divider
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                // Text Field Input
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                      letterSpacing: 0.8,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter Mobile Number',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.0,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                // Clear Button
                if (_showClearButton)
                  GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      if (widget.onChanged != null) {
                        widget.onChanged!('');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
