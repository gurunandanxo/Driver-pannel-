import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/driver_auth_service.dart';

class ForgotPasswordModal extends StatefulWidget {
  const ForgotPasswordModal({super.key});

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  final TextEditingController _emailController = TextEditingController();
  final _authService = DriverAuthService();
  bool _isSent = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    final email = _emailController.text.trim();
    if (!Validators.isValidEmail(email)) {
      setState(() => _errorText = 'Please enter a valid email address.');
      return;
    }

    setState(() => _errorText = null);
    final success = await _authService.sendPasswordResetEmail(email);

    if (mounted) {
      if (success) {
        setState(() => _isSent = true);
      } else {
        setState(() => _errorText = _authService.errorMessage ?? 'Unable to send reset email.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: CityRideTheme.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RESET PASSWORD",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: CityRideTheme.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Receive a secure reset link via email",
                    style: GoogleFonts.inter(fontSize: 12, color: CityRideTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: CityRideTheme.dividerColor),
          const SizedBox(height: 16),

          if (_isSent) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 36, color: CityRideTheme.accentGreen),
                  const SizedBox(height: 10),
                  Text(
                    "Password Reset Link Sent!",
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: CityRideTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "We have sent instructions to ${_emailController.text.trim()}. Please check your inbox and follow the link to set your new password.",
                    style: GoogleFonts.inter(fontSize: 12.5, color: CityRideTheme.textMuted, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("RETURN TO LOGIN"),
              ),
            ),
          ] else ...[
            Text(
              "REGISTERED EMAIL ADDRESS",
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: CityRideTheme.textMuted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "e.g. ramesh.gowda@cityride.in",
                hintStyle: GoogleFonts.inter(fontSize: 13, color: CityRideTheme.textLight),
                prefixIcon: const Icon(Icons.email_outlined, color: CityRideTheme.primaryGreen, size: 20),
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
              onSubmitted: (_) => _handleSendReset(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: CityRideTheme.errorColor),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _authService.isLoading ? null : _handleSendReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _authService.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : Text(
                        "SEND RESET LINK",
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
