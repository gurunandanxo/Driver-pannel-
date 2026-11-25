import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/driver_models.dart';
import '../../services/driver_auth_service.dart';
import '../../widgets/cityride_logo.dart';
import '../dashboard/driver_dashboard_screen.dart';
import 'forgot_password_modal.dart';

class DriverLoginScreen extends StatefulWidget {
  final String? initialDriverId;
  const DriverLoginScreen({super.key, this.initialDriverId});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  late final TextEditingController _idController;
  final TextEditingController _pwdController = TextEditingController(text: '1042');
  bool _obscurePassword = true;
  final _authService = DriverAuthService();

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialDriverId ?? 'TUM-DRV-1042');
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final driverId = _idController.text.trim();
    final pwd = _pwdController.text.trim();

    if (driverId.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Driver ID / Email and Password.'),
          backgroundColor: CityRideTheme.warningColor,
        ),
      );
      return;
    }

    final success = await _authService.login(driverId, pwd);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authService.errorMessage ?? 'Authentication failed. Please verify credentials.'),
          backgroundColor: CityRideTheme.errorColor,
        ),
      );
    }
  }

  void _openForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ForgotPasswordModal(),
    );
  }

  void _selectDemoDriver(DriverProfile driver, String pin) {
    setState(() {
      _idController.text = driver.driverId;
      _pwdController.text = pin;
    });
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo & Titles
                  const CityRideDriverLogo(size: 40, showDriverBadge: false),
                  const SizedBox(height: 12),
                  Text(
                    "DRIVER LOGIN",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: CityRideTheme.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "CityRide Smart Public Transportation Platform",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CityRideTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CityRideTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver ID / Email Field
                        Text(
                          "DRIVER ID / EMAIL",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CityRideTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _idController,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: CityRideTheme.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: "e.g. TUM-DRV-1042 or driver@cityride.in",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: CityRideTheme.textLight),
                            prefixIcon: const Icon(Icons.badge_outlined, color: CityRideTheme.primaryGreen),
                            filled: true,
                            fillColor: CityRideTheme.scaffoldBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: CityRideTheme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: CityRideTheme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: CityRideTheme.primaryGreen, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        Text(
                          "PASSWORD / PIN",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CityRideTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pwdController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: CityRideTheme.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter password or 4-digit PIN",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: CityRideTheme.textLight),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: CityRideTheme.primaryGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: CityRideTheme.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: CityRideTheme.scaffoldBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: CityRideTheme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: CityRideTheme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: CityRideTheme.primaryGreen, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 10),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openForgotPassword,
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: CityRideTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _authService.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CityRideTheme.primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _authService.isLoading
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
                                        "LOGGING IN...",
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ],
                                  )
                                : Text(
                                    "LOGIN TO CONSOLE",
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fast Demo Login Selector (Clearly marked development only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CityRideTheme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.developer_mode_rounded,
                              size: 16,
                              color: CityRideTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "DEMO / DEVELOPMENT ONLY",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: CityRideTheme.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...DriverAuthService.demoDrivers.take(3).map((driver) {
                          final pin = driver.driverId.split('-').last;
                          return InkWell(
                            onTap: () => _selectDemoDriver(driver, pin),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: CityRideTheme.dividerColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        driver.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: CityRideTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        "${driver.driverId} • PIN: $pin",
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: CityRideTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: CityRideTheme.primaryGreen,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
