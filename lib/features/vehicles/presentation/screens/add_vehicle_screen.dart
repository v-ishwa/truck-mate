import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/vehicle_form.dart';
import '../../domain/repositories/vehicle_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kBodyTypes = [
  'Container',
  'Open Body',
  'Mini (Dost)',
  'Tanker',
  'Tipper',
  'Trailer',
  'Flatbed',
  'Refrigerated',
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class AddVehicleScreen extends StatefulWidget {
  /// Called after a vehicle is successfully saved.
  final void Function(VehicleForm vehicle)? onVehicleSaved;

  const AddVehicleScreen({super.key, this.onVehicleSaved});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final VehicleRepository _repository = VehicleRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();

  String _selectedBodyType = _kBodyTypes.first;
  XFile? _pickedImage;
  bool _isSaving = false;

  // ── Image picker ────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          color: bg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Vehicle photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 20),
              _SourceTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take photo',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from gallery',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);
    try {
      await _repository.addVehicle(
        bodyType: _selectedBodyType,
        tyreCount: 0,
        vehicleNumber: _vehicleNumberController.text.trim(),
        imageUrl: _pickedImage?.path,
      );

      final form = VehicleForm(
        bodyType: _selectedBodyType,
        tyreCount: 0,
        vehicleNumber: _vehicleNumberController.text.trim(),
        imageUrl: _pickedImage?.path,
      );

      widget.onVehicleSaved?.call(form);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vehicle saved!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, form);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save vehicle: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final labelColor = isDark ? const Color(0xFFB0B8D0) : const Color(0xFF3B4A68);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFD1D5DB);
    final accentBlue = const Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, cardBg, textColor),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // ── Vehicle image upload ──────────────────────────────────────
            _SectionLabel(text: 'Vehicle image', color: labelColor),
            const SizedBox(height: 8),
            _ImageUploadBox(
              pickedImage: _pickedImage,
              isDark: isDark,
              cardBg: cardBg,
              accentBlue: accentBlue,
              borderColor: borderColor,
              onTap: _pickImage,
            ),
            const SizedBox(height: 20),

            // ── Body type dropdown ────────────────────────────────────────
            _SectionLabel(text: 'Body type', color: labelColor),
            const SizedBox(height: 8),
            _StyledDropdown<String>(
              value: _selectedBodyType,
              items: _kBodyTypes,
              itemLabel: (v) => v,
              onChanged: (v) => setState(() => _selectedBodyType = v!),
              isDark: isDark,
              cardBg: cardBg,
              textColor: textColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 20),

            // ── Vehicle number field ──────────────────────────────────────
            _SectionLabel(text: 'Vehicle number', color: labelColor),
            const SizedBox(height: 8),
            _VehicleNumberField(
              controller: _vehicleNumberController,
              isDark: isDark,
              cardBg: cardBg,
              textColor: textColor,
              borderColor: borderColor,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),

            // ── Save button ───────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBlue,
                  disabledBackgroundColor: accentBlue.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Save vehicle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      bool isDark, Color cardBg, Color textColor) {
    return AppBar(
      backgroundColor: cardBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Add Vehicle',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image upload box
// ─────────────────────────────────────────────────────────────────────────────
class _ImageUploadBox extends StatelessWidget {
  final XFile? pickedImage;
  final bool isDark;
  final Color cardBg;
  final Color accentBlue;
  final Color borderColor;
  final VoidCallback onTap;

  const _ImageUploadBox({
    required this.pickedImage,
    required this.isDark,
    required this.cardBg,
    required this.accentBlue,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0D1B3E)
              : const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentBlue.withValues(alpha: 0.5),
            width: 1.5,
            // Dash effect via custom border (workaround: just use solid with low alpha)
          ),
        ),
        child: pickedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(
                  File(pickedImage!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: accentBlue.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF90A4C8)
                          : const Color(0xFF3B5998),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG or PNG, up to 5MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF6B7E9F)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic styled dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color borderColor;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF1A3A6B).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
          dropdownColor: cardBg,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle number text field
// ─────────────────────────────────────────────────────────────────────────────
class _VehicleNumberField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color borderColor;
  final ValueChanged<String>? onChanged;

  const _VehicleNumberField({
    required this.controller,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.borderColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        hintText: 'TN 45 AB 1234',
        hintStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white30 : const Color(0xFFB0B8C8),
          letterSpacing: 0.5,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image source tile (in bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252545) : const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1565C0)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

