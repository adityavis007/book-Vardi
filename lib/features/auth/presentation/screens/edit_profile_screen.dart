import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/stationery_background.dart';
import '../../domain/user_model.dart';
import '../controllers/auth_controller.dart';

/// 1:1 Edit Profile Screen matching Book Vardi website aesthetics & color palette.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _rollNoController;
  late TextEditingController _schoolController;
  late TextEditingController _gradeController;

  late TextEditingController _addressLineController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;
  late String _selectedAddressTag;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;

    _nameController = TextEditingController(text: user?.name ?? 'Rahul');
    _emailController = TextEditingController(text: user?.email ?? 'rahul@gmail.com');
    _phoneController = TextEditingController(text: user?.phone ?? '3213213212');
    _rollNoController = TextEditingController(
      text: user?.rollNo ?? user?.studentId ?? 'SC-5425',
    );
    _schoolController = TextEditingController(
      text: user?.schoolName ?? "Children's College Azamgarh",
    );
    _gradeController = TextEditingController(
      text: user?.grade ?? 'Class 9 (9th Standard)',
    );

    _addressLineController = TextEditingController(
      text: user?.addressLine ?? 'abc, Sector 4',
    );
    _cityController = TextEditingController(text: user?.city ?? 'Lucknow');
    _stateController = TextEditingController(text: user?.stateName ?? 'Uttar Pradesh');
    _pincodeController = TextEditingController(text: user?.pincode ?? '226028');
    _landmarkController = TextEditingController(text: user?.landmark ?? 'Near Metro Station');
    _selectedAddressTag = user?.addressLabel ?? 'Home';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rollNoController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final currentUser = ref.read(authControllerProvider).user;

    if (currentUser == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save profile changes.')),
      );
      return;
    }

    final updatedUser = currentUser.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      rollNo: _rollNoController.text.trim(),
      studentId: _rollNoController.text.trim(),
      schoolName: _schoolController.text.trim(),
      grade: _gradeController.text.trim(),
      addressLine: _addressLineController.text.trim(),
      city: _cityController.text.trim(),
      stateName: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      landmark: _landmarkController.text.trim(),
      addressLabel: _selectedAddressTag,
    );

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(updatedUser);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details updated successfully!'),
          backgroundColor: Color(0xFF0F291E),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final displayName = _nameController.text.isNotEmpty ? _nameController.text : 'Rahul';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F291E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: StationeryBackground(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Dark Green Profile Header
                _buildDarkHeader(displayName, user),

                // Form Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    children: [
                      // 2. Personal Information Card
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 18.0),

                      // 3. Primary Home / Delivery Address Card
                      _buildAddressCard(),
                      const SizedBox(height: 18.0),

                      // 4. Save Changes Action Button
                      _buildSaveButton(),
                      const SizedBox(height: 32.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkHeader(String displayName, UserModel? user) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'R';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0F291E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 68.0,
                height: 68.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A2F),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFBBF24),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 28.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ),
              // Yellow Edit Pill Badge
              Positioned(
                top: -4,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4.0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 11.0,
                        color: Colors.black,
                      ),
                      SizedBox(width: 3.0),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Student Pill Badge
              Positioned(
                bottom: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 3.0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Text(
                      'STUDENT',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16.0),

          // User Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),
                Text(
                  _schoolController.text.isNotEmpty
                      ? '${_schoolController.text} • ${_gradeController.text}'
                      : "Children's College Azamgarh • Class 9",
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6.0),
                // Verified Student Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12.0, color: Color(0xFF34D399)),
                      SizedBox(width: 4.0),
                      Text(
                        'Verified Student',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'EDITABLE',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // FULL NAME
          _buildTextField(
            key: const Key('edit_profile_name_field'),
            label: 'FULL NAME',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            validator: (val) => val == null || val.trim().isEmpty ? 'Name cannot be empty' : null,
          ),
          const SizedBox(height: 14.0),

          // EMAIL ADDRESS
          _buildTextField(
            key: const Key('edit_profile_email_field'),
            label: 'EMAIL ADDRESS',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14.0),

          // MOBILE PHONE NUMBER
          _buildTextField(
            key: const Key('edit_profile_phone_field'),
            label: 'MOBILE PHONE NUMBER',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14.0),

          // STUDENT ROLL NO.
          _buildTextField(
            key: const Key('edit_profile_roll_field'),
            label: 'STUDENT ROLL NO.',
            controller: _rollNoController,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 14.0),

          // SCHOOL / INSTITUTION
          _buildTextField(
            key: const Key('edit_profile_school_field'),
            label: 'SCHOOL / INSTITUTION',
            controller: _schoolController,
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 14.0),

          // CLASS / STANDARD
          _buildTextField(
            key: const Key('edit_profile_grade_field'),
            label: 'CLASS / STANDARD',
            controller: _gradeController,
            icon: Icons.menu_book_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18.0, color: Color(0xFF0F291E)),
              const SizedBox(width: 6.0),
              const Expanded(
                child: Text(
                  'Primary Home / Delivery Address',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // HOUSE / FLAT NO, BUILDING, STREET
          _buildTextField(
            key: const Key('edit_profile_address_field'),
            label: 'HOUSE / FLAT NO, BUILDING, STREET ADDRESS',
            controller: _addressLineController,
            icon: Icons.home_outlined,
          ),
          const SizedBox(height: 14.0),

          // CITY & STATE
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  key: const Key('edit_profile_city_field'),
                  label: 'CITY / DISTRICT',
                  controller: _cityController,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildTextField(
                  key: const Key('edit_profile_state_field'),
                  label: 'STATE',
                  controller: _stateController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // PIN CODE & LANDMARK
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  key: const Key('edit_profile_pincode_field'),
                  label: 'PIN CODE',
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildTextField(
                  key: const Key('edit_profile_landmark_field'),
                  label: 'LANDMARK (OPTIONAL)',
                  controller: _landmarkController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // ADDRESS TAG / LABEL CHIPS
          const Text(
            'ADDRESS TAG / LABEL',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: ['Home', 'School', 'Work'].map((tag) {
              final isSelected = _selectedAddressTag == tag;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  key: Key('address_tag_chip_$tag'),
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0F291E),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0F291E) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedAddressTag = tag);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    Key? key,
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          key: key,
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 18.0, color: const Color(0xFF64748B)) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF0F291E), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 50.0,
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('edit_profile_save_button'),
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F291E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22.0,
                height: 22.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 18.0),
                  SizedBox(width: 8.0),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
