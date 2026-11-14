import 'dart:async';

import 'package:flutter/material.dart';

class SearchBarField extends StatefulWidget {
  final String initialText;
  final String hintText;
  final Duration debounce;
  final ValueChanged<String> onQueryChanged;

  const SearchBarField({
    super.key,
    required this.onQueryChanged,
    this.initialText = '',
    this.hintText = 'Search',
    this.debounce = const Duration(milliseconds: 400),
  });

  @override
  State<SearchBarField> createState() => _SearchBarFieldState();
}

class _SearchBarFieldState extends State<SearchBarField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant SearchBarField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText &&
        widget.initialText != _controller.text) {
      _controller.text = widget.initialText;
      setState(() {});
    }
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () {
      widget.onQueryChanged(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      onSubmitted: widget.onQueryChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  _debounce?.cancel();
                  widget.onQueryChanged('');
                },
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}
