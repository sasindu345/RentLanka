import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:mobile/core/api/bookings_api.dart';

class AgreementService {
  static Future<void> openAgreementPreview(
    BuildContext context,
    BookingResponse booking,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.7,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rental Agreement',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _AgreementHeader(booking: booking),
                          const SizedBox(height: 20),
                          _AgreementSection(
                            title: '1. Contracting Parties',
                            child: _AgreementTable(booking: booking),
                          ),
                          const SizedBox(height: 16),
                          _AgreementSection(
                            title: '2. Rental Item & Charges',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AgreementBullet(
                                  'Equipment Title: ${booking.listingTitle}',
                                ),
                                _AgreementBullet(
                                  'Rental Start Date: ${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                                ),
                                _AgreementBullet(
                                  'Rental End Date: ${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year}',
                                ),
                                _AgreementBullet(
                                  'Rental Fee: LKR ${booking.totalPrice.toStringAsFixed(0)}',
                                ),
                                _AgreementBullet(
                                  'Refundable Security Deposit: LKR ${booking.securityDeposit.toStringAsFixed(0)}',
                                ),
                                _AgreementBullet(
                                  'Total Meetup Cash Payable: LKR ${(booking.totalPrice + booking.securityDeposit).toStringAsFixed(0)}',
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AgreementSection(
                            title: '3. General Terms & Conditions',
                            child: Text(
                              _generalTermsText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AgreementSignatureRow(theme: theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await generateAndShareAgreement(booking);
                            },
                            child: const Text('Download PDF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Future<void> generateAndShareAgreement(BookingResponse booking) async {
    final pdf = await _buildAgreementPdf(booking);

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/RentLanka_Agreement_${booking.id.substring(0, 8)}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'RentLanka Rental Agreement - ${booking.listingTitle}');
  }

  static Future<pw.Document> _buildAgreementPdf(BookingResponse booking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'RENTLANKA EQUIPMENT RENTAL AGREEMENT',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} · Booking ID: ${booking.id}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.teal800),
                pw.SizedBox(height: 16),

                // Section 1: Parties
                pw.Text(
                  '1. CONTRACTING PARTIES',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.8,
                  ),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Party Role',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Full Name',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'NIC Number',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'OWNER (Host)',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            booking.ownerName,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            booking.ownerNic ?? 'Verified on App',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'RENTER (Guest)',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            booking.renterName,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            booking.renterNic ?? 'Verified on App',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Section 2: Rental Specifications
                pw.Text(
                  '2. RENTAL ITEM & CHARGES',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Bullet(
                  text: 'Equipment Title: ${booking.listingTitle}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Bullet(
                  text:
                      'Rental Start Date: ${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Bullet(
                  text:
                      'Rental End Date: ${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Bullet(
                  text:
                      'Rental Fee: LKR ${booking.totalPrice.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Bullet(
                  text:
                      'Refundable Security Deposit: LKR ${booking.securityDeposit.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Bullet(
                  text:
                      'Total Meetup Cash Payable: LKR ${(booking.totalPrice + booking.securityDeposit).toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Section 3: Standard Terms
                pw.Text(
                  '3. GENERAL TERMS & CONDITIONS',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '1. Ownership: The equipment remains the sole property of the Owner at all times.\n'
                  '2. Inspection: Renter shall inspect the equipment upon handover. Any pre-existing damages must be agreed upon physically before transfer.\n'
                  '3. Care & Return: Renter agrees to use the equipment carefully and return it on or before the End Date in the exact same condition received, subject to normal wear and tear.\n'
                  '4. Damages & Theft: Renter assumes full financial liability for any damage, loss, or theft during the rental term. The security deposit may be withheld to cover damages.\n'
                  '5. Delivery of Payment: The renter agrees to pay the total rental fee and security deposit in cash physically upon equipment handover.',
                  style: const pw.TextStyle(fontSize: 9, lineSpacing: 2.5),
                ),
                pw.SizedBox(height: 48),

                // Section 4: Signature columns
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                width: 0.8,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'OWNER SIGNATURE',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Date: ____/____/________',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                width: 0.8,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'RENTER SIGNATURE',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Date: ____/____/________',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  static const String _generalTermsText =
      '1. Ownership: The equipment remains the sole property of the Owner at all times.\n'
      '2. Inspection: Renter shall inspect the equipment upon handover. Any pre-existing damages must be agreed upon physically before transfer.\n'
      '3. Care & Return: Renter agrees to use the equipment carefully and return it on or before the End Date in the exact same condition received, subject to normal wear and tear.\n'
      '4. Damages & Theft: Renter assumes full financial liability for any damage, loss, or theft during the rental term. The security deposit may be withheld to cover damages.\n'
      '5. Delivery of Payment: The renter agrees to pay the total rental fee and security deposit in cash physically upon equipment handover.';
}

class _AgreementHeader extends StatelessWidget {
  const _AgreementHeader({required this.booking});

  final BookingResponse booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'RENTLANKA EQUIPMENT RENTAL AGREEMENT',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} · Booking ID: ${booking.id}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: theme.colorScheme.primary.withOpacity(0.4)),
      ],
    );
  }
}

class _AgreementSection extends StatelessWidget {
  const _AgreementSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _AgreementBullet extends StatelessWidget {
  const _AgreementBullet(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '• $text',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.4,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AgreementTable extends StatelessWidget {
  const _AgreementTable({required this.booking});

  final BookingResponse booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        width: 0.8,
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
      },
      children: [
        _tableRow(theme, 'Party Role', 'Full Name', 'NIC Number', header: true),
        _tableRow(
          theme,
          'OWNER (Host)',
          booking.ownerName,
          booking.ownerNic ?? 'Verified on App',
        ),
        _tableRow(
          theme,
          'RENTER (Guest)',
          booking.renterName,
          booking.renterNic ?? 'Verified on App',
        ),
      ],
    );
  }

  TableRow _tableRow(
    ThemeData theme,
    String first,
    String second,
    String third, {
    bool header = false,
  }) {
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: header ? FontWeight.w700 : FontWeight.w400,
      color: theme.colorScheme.onSurface,
    );
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(first, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(second, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(third, style: textStyle),
        ),
      ],
    );
  }
}

class _AgreementSignatureRow extends StatelessWidget {
  const _AgreementSignatureRow({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 1, color: theme.colorScheme.outline),
              const SizedBox(height: 6),
              Text(
                'OWNER SIGNATURE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Date: ____/____/________',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 1, color: theme.colorScheme.outline),
              const SizedBox(height: 6),
              Text(
                'RENTER SIGNATURE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Date: ____/____/________',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
