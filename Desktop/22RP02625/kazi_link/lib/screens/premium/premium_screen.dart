import 'package:flutter/material.dart';
import '../payment/payment_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:flutterwave_standard/flutterwave.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final benefits = [
      'Highlighted jobs in listings',
      'Unlimited job applications',
      'Access to premium workers/clients',
      'No ads',
      'Priority support',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.workspace_premium, color: Colors.amber.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Go Premium',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final isPremium = userProvider.isPremium;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upgrade to Premium',
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enjoy these exclusive benefits:',
                  style: GoogleFonts.poppins(fontSize: 18, color: colorScheme.onSurface.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...benefits.map((b) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.amber.shade700),
                        title: Text(b, style: GoogleFonts.poppins(fontSize: 16)),
                      ),
                    )),
                const Spacer(),
                if (!isPremium) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.workspace_premium, color: Colors.amber.shade700),
                    onPressed: () async {
                      // Simulate Flutterwave payment
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Simulate Payment', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          content: Text('Proceed with Flutterwave payment simulation?', style: GoogleFonts.poppins()),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.poppins())),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Pay', style: GoogleFonts.poppins())),
                          ],
                        ),
                      );
                      if (result == true) {
                        await userProvider.setPremiumStatus(true);
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Success', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              content: Text('You are now a premium user!', style: GoogleFonts.poppins()),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: GoogleFonts.poppins())),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    label: Text('Upgrade with Flutterwave', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.workspace_premium, color: Colors.amber.shade700),
                    label: Text('You are Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      backgroundColor: colorScheme.primary.withOpacity(0.5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
} 