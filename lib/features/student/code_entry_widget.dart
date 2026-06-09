// lib/features/student/code_entry_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';

/// 6-digit code entry with individual digit boxes.
class CodeEntryWidget extends StatefulWidget {
  const CodeEntryWidget({super.key, required this.onSubmit});

  final void Function(String code) onSubmit;

  @override
  State<CodeEntryWidget> createState() => _CodeEntryWidgetState();
}

class _CodeEntryWidgetState extends State<CodeEntryWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _focusNode.requestFocus,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < value.text.length;
                  final char = filled ? value.text[i] : '';
                  return Container(
                    width: 44,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: filled
                          ? AppTheme.primary.withOpacity(0.08)
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: filled ? AppTheme.primary : AppTheme.border,
                        width: filled ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      char,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),

        // Hidden text field to capture keyboard input
        SizedBox(
          height: 0,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              if (v.length == 6) widget.onSubmit(v);
              setState(() {});
            },
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: () {
              if (_controller.text.length == 6) {
                widget.onSubmit(_controller.text);
              } else {
                _focusNode.requestFocus();
              }
            },
            child: const Text('Verify Code'),
          ),
        ),
      ],
    );
  }
}