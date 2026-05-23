import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String? hintText;
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T?) onChanged;
  final IconData? prefixIcon;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.itemToString,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<T>(
          width: constraints.maxWidth,
          initialSelection: value,
          enableFilter: true,
          requestFocusOnTap: true,
          hintText: hintText,
          label: Text(label, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12)),
          leadingIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF64748B), size: 18) : null,
          textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
            labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
            elevation: WidgetStateProperty.all(8),
            maximumSize: WidgetStateProperty.all(const Size.fromHeight(300)),
          ),
          dropdownMenuEntries: items.map((T item) {
            return DropdownMenuEntry<T>(
              value: item,
              label: itemToString(item),
              style: MenuItemButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            );
          }).toList(),
          onSelected: onChanged,
        );
      },
    );
  }
}
