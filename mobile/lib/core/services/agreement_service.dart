import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:mobile/core/api/bookings_api.dart';

class AgreementService {
  static Future<void> generateAndShareAgreement(BookingResponse booking) async {
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
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.teal800),
                pw.SizedBox(height: 16),

                // Section 1: Parties
                pw.Text(
                  '1. CONTRACTING PARTIES',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Party Role', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Full Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('NIC Number', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('OWNER (Host)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(booking.ownerName, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(booking.ownerNic ?? 'Verified on App', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('RENTER (Guest)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(booking.renterName, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(booking.renterNic ?? 'Verified on App', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Section 2: Rental Specifications
                pw.Text(
                  '2. RENTAL ITEM & CHARGES',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                ),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Equipment Title: ${booking.listingTitle}', style: const pw.TextStyle(fontSize: 10)),
                pw.Bullet(text: 'Rental Start Date: ${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}', style: const pw.TextStyle(fontSize: 10)),
                pw.Bullet(text: 'Rental End Date: ${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year}', style: const pw.TextStyle(fontSize: 10)),
                pw.Bullet(text: 'Rental Fee: LKR ${booking.totalPrice.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                pw.Bullet(text: 'Refundable Security Deposit: LKR ${booking.securityDeposit.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                pw.Bullet(
                  text: 'Total Meetup Cash Payable: LKR ${(booking.totalPrice + booking.securityDeposit).toStringAsFixed(0)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.SizedBox(height: 20),

                // Section 3: Standard Terms
                pw.Text(
                  '3. GENERAL TERMS & CONDITIONS',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
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
                        pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.8, color: PdfColors.grey700)))),
                        pw.SizedBox(height: 4),
                        pw.Text('OWNER SIGNATURE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: ____/____/________', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.8, color: PdfColors.grey700)))),
                        pw.SizedBox(height: 4),
                        pw.Text('RENTER SIGNATURE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: ____/____/________', style: const pw.TextStyle(fontSize: 8)),
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

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/RentLanka_Agreement_${booking.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'RentLanka Rental Agreement - ${booking.listingTitle}',
    );
  }
}
