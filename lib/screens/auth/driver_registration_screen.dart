import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/driver_auth_service.dart';
import '../../widgets/cityride_logo.dart';
import 'driver_login_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = DriverAuthService();
  final _picker = ImagePicker();

  // Module 1: Personal Information Controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController(text: '1992-05-18');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Tumakuru');
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Module 2: Driver Information Controllers
  final _licenceController = TextEditingController();
  final _licenceExpiryController = TextEditingController(text: '2032-05-17');
  String _experience = '3-5 Years';
  String _driverCategory = 'Heavy Passenger Vehicle (HPV)';
  String _depot = 'Tumakuru Central City Depot #1 (Ashoka Road)';

  // Module 3: Driver Photo
  File? _photoFile;

  // Module 4: Account Security Controllers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;

  // State Management
  bool _isSubmitting = false;
  String? _errorMessage;
  RegistrationResult? _successResult;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _licenceController.dispose();
    _licenceExpiryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() {
          _photoFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('[Registration] Image pick error: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Upload Driver Photo",
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: CityRideTheme.primaryGreen),
                title: const Text("Take Photo with Camera"),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: CityRideTheme.primaryGreen),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool isFuture = false}) async {
    final now = DateTime.now();
    final initialDate = isFuture ? now.add(const Duration(days: 365 * 5)) : DateTime(1990, 1, 1);
    final firstDate = isFuture ? now : DateTime(1950);
    final lastDate = isFuture ? DateTime(2050) : now.subtract(const Duration(days: 365 * 18));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: CityRideTheme.primaryGreen),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please complete all required fields correctly.');
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please agree to CityRide Transit Operational Guidelines.');
      return;
    }

    final pwd = _passwordController.text;
    final confirmPwd = _confirmPasswordController.text;

    if (pwd != confirmPwd) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (!Validators.isPasswordValid(pwd)) {
      setState(() => _errorMessage = 'Password must be at least 8 characters and contain uppercase, lowercase & numbers.');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _authService.registerDriver(
      fullName: _nameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      mobile: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactNumber: _emergencyPhoneController.text.trim(),
      licenceNumber: _licenceController.text.trim(),
      licenceExpiry: _licenceExpiryController.text.trim(),
      experience: _experience,
      driverCategory: _driverCategory,
      depot: _depot,
      password: pwd,
      photoFile: _photoFile,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result.success) {
        setState(() => _successResult = result);
      } else {
        setState(() => _errorMessage = result.message ?? 'Registration failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_successResult != null) {
      return _buildSuccessScreen(_successResult!);
    }

    final pwdStrength = Validators.getPasswordStrength(_passwordController.text);
    final pwdStrengthLabel = Validators.getPasswordStrengthLabel(pwdStrength);

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Driver Registration",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: CityRideTheme.textDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: CityRideTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Branding
                Center(
                  child: Column(
                    children: [
                      const CityRideDriverLogo(size: 32, showDriverBadge: true),
                      const SizedBox(height: 8),
                      Text(
                        "CITYRIDE DRIVER REGISTRATION",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: CityRideTheme.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Create your secure CityRide driver account",
                        style: GoogleFonts.inter(fontSize: 12.5, color: CityRideTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: CityRideTheme.errorColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: CityRideTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // MODULE 1: PERSONAL INFORMATION
                _buildModuleContainer(
                  icon: Icons.person_outline_rounded,
                  title: "PERSONAL INFORMATION",
                  subtitle: "Driver identity and emergency contact",
                  headerBg: const Color(0xFFF0FDF4),
                  border: const Color(0xFFBBF7D0),
                  iconColor: CityRideTheme.primaryGreen,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "FULL NAME *",
                      hint: "e.g. Ramesh Gowda",
                      validator: (v) => v == null || v.trim().isEmpty ? "Full name is required" : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _dobController,
                            label: "DATE OF BIRTH *",
                            hint: "YYYY-MM-DD",
                            readOnly: true,
                            onTap: () => _selectDate(context, _dobController),
                            suffixIcon: Icons.calendar_today_rounded,
                            validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: "CITY *",
                            hint: "Tumakuru",
                            validator: (v) => v == null || v.trim().isEmpty ? "City is required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: "MOBILE NUMBER *",
                      hint: "e.g. 9845012345 (10 digits)",
                      keyboardType: TextInputType.phone,
                      validator: (v) => !Validators.isValidIndianMobile(v) ? "Enter valid 10-digit Indian mobile" : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      label: "EMAIL ADDRESS *",
                      hint: "e.g. ramesh.gowda@cityride.in",
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => !Validators.isValidEmail(v) ? "Enter valid email address" : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: "RESIDENTIAL ADDRESS *",
                      hint: "e.g. 14th Cross, SIT Main Road",
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty ? "Address is required" : null,
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    const SizedBox(height: 14),
                    Text(
                      "EMERGENCY CONTACT",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: CityRideTheme.textMuted, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emergencyNameController,
                      label: "CONTACT PERSON NAME & RELATION *",
                      hint: "e.g. Smt. Suma Gowda (Spouse)",
                      validator: (v) => v == null || v.trim().isEmpty ? "Emergency contact name is required" : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emergencyPhoneController,
                      label: "EMERGENCY PHONE NUMBER *",
                      hint: "e.g. 9845099887",
                      keyboardType: TextInputType.phone,
                      validator: (v) => !Validators.isValidIndianMobile(v) ? "Enter valid 10-digit phone number" : null,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // MODULE 2: DRIVER INFORMATION
                _buildModuleContainer(
                  icon: Icons.directions_bus_rounded,
                  title: "DRIVER INFORMATION",
                  subtitle: "Licence details & assigned operating depot",
                  headerBg: const Color(0xFFECFDF5),
                  border: const Color(0xFFD1FAE5),
                  iconColor: CityRideTheme.primaryGreen,
                  children: [
                    _buildTextField(
                      controller: _licenceController,
                      label: "DRIVING LICENCE NUMBER *",
                      hint: "e.g. KA-06-2012-0048291",
                      validator: (v) => !Validators.isValidLicenceNumber(v) ? "Enter valid Driving Licence number" : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _licenceExpiryController,
                      label: "LICENCE EXPIRY DATE *",
                      hint: "YYYY-MM-DD",
                      readOnly: true,
                      onTap: () => _selectDate(context, _licenceExpiryController, isFuture: true),
                      suffixIcon: Icons.calendar_today_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? "Expiry date is required" : null,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField(
                      label: "DRIVING EXPERIENCE *",
                      value: _experience,
                      items: const ['1-3 Years', '3-5 Years', '5-10 Years', '10+ Years'],
                      onChanged: (val) => setState(() => _experience = val!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField(
                      label: "DRIVER CATEGORY *",
                      value: _driverCategory,
                      items: const [
                        'Heavy Passenger Vehicle (HPV)',
                        'Medium Transit Vehicle (MTV)',
                        'Electric City Bus (EV)',
                      ],
                      onChanged: (val) => setState(() => _driverCategory = val!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField(
                      label: "DEPOT / OPERATING LOCATION *",
                      value: _depot,
                      items: const [
                        'Tumakuru Central City Depot #1 (Ashoka Road)',
                        'Tumakuru North Depot #2 (Batawadi)',
                        'Tumakuru South Depot #3 (Heggere)',
                      ],
                      onChanged: (val) => setState(() => _depot = val!),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: CityRideTheme.primaryGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Unique Driver ID (e.g. TUM-DRV-1043) will be auto-generated by the system upon account creation.",
                              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF166534)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // MODULE 3: DRIVER PHOTO
                _buildModuleContainer(
                  icon: Icons.camera_alt_outlined,
                  title: "DRIVER PHOTO",
                  subtitle: "Upload professional driver profile photo",
                  headerBg: const Color(0xFFF8FAFC),
                  border: const Color(0xFFE2E8F0),
                  iconColor: CityRideTheme.primaryGreen,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: CityRideTheme.scaffoldBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: CityRideTheme.dividerColor, width: 2),
                            ),
                            child: ClipOval(
                              child: _photoFile != null
                                  ? Image.file(_photoFile!, fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 48, color: CityRideTheme.textLight),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showImageSourceDialog,
                                icon: const Icon(Icons.upload_file_rounded, size: 16),
                                label: Text(_photoFile == null ? "Upload Photo" : "Replace Photo"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CityRideTheme.primaryGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (_photoFile != null) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => setState(() => _photoFile = null),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    textStyle: GoogleFonts.inter(fontSize: 12),
                                  ),
                                  child: const Text("Remove"),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Supported formats: JPG, JPEG, PNG (Max 5MB). If omitted, initials will be used.",
                            style: GoogleFonts.inter(fontSize: 11, color: CityRideTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // MODULE 4: ACCOUNT SECURITY
                _buildModuleContainer(
                  icon: Icons.security_rounded,
                  title: "ACCOUNT SECURITY",
                  subtitle: "Set your password for driver console access",
                  headerBg: const Color(0xFFEFF6FF),
                  border: const Color(0xFFBFDBFE),
                  iconColor: CityRideTheme.routeAccent,
                  children: [
                    _buildTextField(
                      controller: _passwordController,
                      label: "CREATE PASSWORD *",
                      hint: "Minimum 8 characters",
                      obscureText: _obscurePassword,
                      onChanged: (val) => setState(() {}),
                      suffixWidget: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: CityRideTheme.textMuted,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) => !Validators.isPasswordValid(v ?? '')
                          ? "Min 8 chars with uppercase, lowercase & number"
                          : null,
                    ),
                    const SizedBox(height: 8),

                    // Password Strength Indicator
                    Row(
                      children: [
                        Text(
                          "Strength: ",
                          style: GoogleFonts.inter(fontSize: 11, color: CityRideTheme.textMuted),
                        ),
                        Text(
                          pwdStrengthLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pwdStrength < 0.3
                                ? CityRideTheme.errorColor
                                : (pwdStrength < 0.6 ? CityRideTheme.warningColor : CityRideTheme.accentGreen),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pwdStrength,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pwdStrength < 0.3
                                    ? CityRideTheme.errorColor
                                    : (pwdStrength < 0.6 ? CityRideTheme.warningColor : CityRideTheme.accentGreen),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: "CONFIRM PASSWORD *",
                      hint: "Re-enter your password",
                      obscureText: _obscureConfirmPassword,
                      onChanged: (val) => setState(() {}),
                      suffixWidget: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: CityRideTheme.textMuted,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (v) => v != _passwordController.text ? "Passwords do not match" : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Terms & Guidelines Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        activeColor: CityRideTheme.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "I certify that all information provided is accurate and agree to abide by CityRide Transit Safety & Operational Policies.",
                        style: GoogleFonts.inter(fontSize: 12, color: CityRideTheme.textDark, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CityRideTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "CREATING ACCOUNT...",
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          )
                        : Text(
                            "CREATE DRIVER ACCOUNT",
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // REGISTRATION SUCCESS SCREEN
  // ===========================================================================
  Widget _buildSuccessScreen(RegistrationResult result) {
    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                  boxShadow: [
                    BoxShadow(
                      color: CityRideTheme.primaryGreen.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.check_circle_rounded, color: CityRideTheme.accentGreen, size: 44),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "ACCOUNT CREATED SUCCESSFULLY",
                      style: GoogleFonts.inter(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: CityRideTheme.textDark,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your CityRide Driver Profile is registered and ready.",
                      style: GoogleFonts.inter(fontSize: 13, color: CityRideTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    // Generated Driver ID Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "YOUR UNIQUE DRIVER ID",
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: CityRideTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.driverId ?? "TUM-DRV-1043",
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: CityRideTheme.primaryGreen,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.profile?.name ?? "Driver",
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: CityRideTheme.textDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      "You can now log in to the Driver Console using your Driver ID (${result.driverId}) or Email.",
                      style: GoogleFonts.inter(fontSize: 12.5, color: CityRideTheme.textMuted, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CityRideTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "GO TO LOGIN",
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI HELPER BUILDERS
  // ===========================================================================
  Widget _buildModuleContainer({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color headerBg,
    required Color border,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tinted Module Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: CityRideTheme.textDark,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 10.5, color: CityRideTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    IconData? suffixIcon,
    Widget? suffixWidget,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: CityRideTheme.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: CityRideTheme.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 12.5, color: CityRideTheme.textLight),
            filled: true,
            fillColor: CityRideTheme.scaffoldBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CityRideTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CityRideTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CityRideTheme.primaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CityRideTheme.errorColor),
            ),
            suffixIcon: suffixWidget ??
                (suffixIcon != null
                    ? Icon(suffixIcon, size: 18, color: CityRideTheme.primaryGreen)
                    : null),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: CityRideTheme.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: CityRideTheme.scaffoldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CityRideTheme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: CityRideTheme.primaryGreen),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: CityRideTheme.textDark),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
