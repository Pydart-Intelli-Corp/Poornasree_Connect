import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../utils/utils.dart';

class PdfService {
  /// Generate PDF report similar to web application's jsPDF implementation
  static Future<Uint8List> generateCollectionReportPDF({
    required List<Map<String, dynamic>> records,
    required Map<String, dynamic> stats,
    required String dateRange,
    required List<String> selectedColumns,
    String? logoPath,
  }) async {
    final pdf = pw.Document();

    // Load custom font (optional)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Load logo if available
    pw.ImageProvider? logoImage;
    if (logoPath != null) {
      try {
        final logoBytes = await rootBundle.load(logoPath);
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (e) {
        print('Logo loading failed: $e');
        // Create a simple text logo as fallback
        logoImage = null;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header with Logo and Title
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo section
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 40,
                    child: pw.Image(logoImage),
                  )
                else
                  pw.Container(
                    width: 60,
                    height: 40,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'P',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                pw.SizedBox(width: 20),
                
                // Title section
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Daily Collection Report - LactoConnect Milk Collection System',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date From $dateRange',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 9,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'DETAILED COLLECTION DATA',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 12),
            
            // Data Table with selected columns
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.3,
              ),
              defaultColumnWidth: const pw.IntrinsicColumnWidth(),
              children: [
                // Header row with selected columns
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                  ),
                  children: selectedColumns.map((columnKey) {
                    String headerText = '';
                    switch (columnKey) {
                      case 'sl_no':
                        headerText = 'Sl.No';
                        break;
                      case 'date_time':
                        headerText = 'Date & Time';
                        break;
                      case 'farmer':
                        headerText = 'Farmer';
                        break;
                      case 'society':
                        headerText = 'Society';
                        break;
                      case 'machine':
                        headerText = 'Machine';
                        break;
                      case 'shift':
                        headerText = 'Shift';
                        break;
                      case 'channel':
                        headerText = 'Channel';
                        break;
                      case 'fat':
                        headerText = 'Fat %';
                        break;
                      case 'snf':
                        headerText = 'SNF %';
                        break;
                      case 'clr':
                        headerText = 'CLR';
                        break;
                      case 'protein':
                        headerText = 'Protein %';
                        break;
                      case 'lactose':
                        headerText = 'Lactose %';
                        break;
                      case 'salt':
                        headerText = 'Salt %';
                        break;
                      case 'water':
                        headerText = 'Water %';
                        break;
                      case 'temperature':
                        headerText = 'Temp (°C)';
                        break;
                      case 'rate':
                        headerText = 'Rate/L';
                        break;
                      case 'bonus':
                        headerText = 'Bonus';
                        break;
                      case 'qty':
                        headerText = 'Qty (L)';
                        break;
                      case 'amount':
                        headerText = 'Amount';
                        break;
                      case 'dispatch_id':
                        headerText = 'Dispatch ID';
                        break;
                      case 'count':
                        headerText = 'Count';
                        break;
                      default:
                        headerText = columnKey;
                    }
                    return _buildTableCell(headerText, fontBold, isHeader: true);
                  }).toList(),
                ),
                
                // Data rows with selected columns
                ...records.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final record = entry.value;
                    return pw.TableRow(
                      children: selectedColumns.map((columnKey) {
                        String cellValue = '';
                        switch (columnKey) {
                          case 'sl_no':
                            cellValue = '${index + 1}';
                            break;
                          case 'date_time':
                            cellValue = '${record['collection_date'] ?? ''} ${record['collection_time'] ?? ''}';
                            break;
                          case 'farmer':
                            cellValue = '${record['farmer_id'] ?? ''} - ${record['farmer_name'] ?? ''}';
                            break;
                          case 'society':
                            cellValue = '${record['society_name'] ?? ''}';
                            break;
                          case 'machine':
                            cellValue = '${record['machine_id'] ?? ''} (${record['machine_type'] ?? ''})';
                            break;
                          case 'shift':
                            cellValue = '${record['shift_type'] ?? ''}';
                            break;
                          case 'channel':
                            cellValue = _getChannelDisplay(record['channel']?.toString() ?? '');
                            break;
                          case 'fat':
                            cellValue = '${record['fat_percentage'] ?? ''}';
                            break;
                          case 'snf':
                            cellValue = '${record['snf_percentage'] ?? ''}';
                            break;
                          case 'clr':
                            cellValue = '${record['clr_value'] ?? ''}';
                            break;
                          case 'protein':
                            cellValue = '${record['protein_percentage'] ?? ''}';
                            break;
                          case 'lactose':
                            cellValue = '${record['lactose_percentage'] ?? ''}';
                            break;
                          case 'salt':
                            cellValue = '${record['salt_percentage'] ?? ''}';
                            break;
                          case 'water':
                            cellValue = '${record['water_percentage'] ?? ''}';
                            break;
                          case 'temperature':
                            cellValue = '${record['temperature'] ?? ''}';
                            break;
                          case 'rate':
                            cellValue = '${record['rate_per_liter'] ?? ''}';
                            break;
                          case 'bonus':
                            cellValue = '${record['bonus'] ?? ''}';
                            break;
                          case 'qty':
                            cellValue = '${record['quantity'] ?? ''}';
                            break;
                          case 'amount':
                            cellValue = '${record['total_amount'] ?? ''}';
                            break;
                          case 'dispatch_id':
                            cellValue = '${record['dispatch_id'] ?? ''}';
                            break;
                          case 'count':
                            cellValue = '${record['count'] ?? ''}';
                            break;
                          default:
                            cellValue = '';
                        }
                        return _buildTableCell(cellValue, font);
                      }).toList(),
                    );
                  },
                ).toList(),
              ],
            ),
            
            pw.SizedBox(height: 16),
            
            // Summary Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left side - Weighted Averages
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WEIGHTED AVERAGES',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Weighted Fat      : ${stats['weightedFat']?.toStringAsFixed(2) ?? '0.00'}',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Weighted SNF      : ${stats['weightedSnf']?.toStringAsFixed(2) ?? '0.00'}',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Weighted CLR      : ${stats['weightedClr']?.toStringAsFixed(2) ?? '0.00'}',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'OVERALL SUMMARY',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Total Collections  : ${stats['totalCollections'] ?? 0}',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Total Quantity (L) : ${stats['totalQuantity']?.toStringAsFixed(2) ?? '0.00'}',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Total Amount       : ${stats['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                
                // Right side - Report Notes
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'REPORT NOTES',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Prepared by: POORNASREE EQUIPMENTS',
                        style: pw.TextStyle(font: font, fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Contact: marketing@poornasree.com',
                        style: pw.TextStyle(font: font, fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'POORNASREE EQUIPMENTS',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Thank you for using LactoConnect',
                        style: pw.TextStyle(font: font, fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'For support, visit: www.poornasree.com',
                        style: pw.TextStyle(font: font, fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Generate CSV content similar to web application
  static String generateCollectionReportCSV({
    required List<Map<String, dynamic>> records,
    required Map<String, dynamic> stats,
    required String dateRange,
  }) {
    final now = DateTime.now();
    final currentDateTime = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    // Detailed data rows
    final dataRows = records.map((record) => [
      record['collection_date'] ?? '',
      record['collection_time'] ?? '',
      record['channel'] ?? '',
      record['shift_type'] ?? '',
      '${record['machine_id'] ?? ''} (${record['machine_type'] ?? ''})',
      '${record['society_name'] ?? ''} (${record['society_id'] ?? ''})',
      record['farmer_id'] ?? '',
      record['farmer_name'] ?? '',
      record['fat_percentage'] ?? '',
      record['snf_percentage'] ?? '',
      record['clr_value'] ?? '',
      record['water_percentage'] ?? '',
      record['rate_per_liter'] ?? '',
      record['quantity'] ?? '',
      record['total_amount'] ?? '',
      record['bonus'] ?? '',
    ].join(',')).toList();

    final csvLines = [
      'Admin Report - LactoConnect Milk Collection System',
      'Date From $dateRange',
      '',
      'DETAILED COLLECTION DATA',
      '',
      'Date,Time,Channel,Shift,Machine,Society,Farmer ID,Farmer Name,Fat (%),SNF (%),CLR,Water (%),Rate,Quantity (L),Total Amount,Incentive',
      ...dataRows,
      '',
      '',
      'OVERALL SUMMARY',
      'Total Collections:,${stats['totalCollections'] ?? 0}',
      'Total Quantity (L):,${stats['totalQuantity']?.toStringAsFixed(2) ?? '0.00'}',
      'Overall Weighted Fat (%):,${stats['weightedFat']?.toStringAsFixed(2) ?? '0.00'}',
      'Overall Weighted SNF (%):,${stats['weightedSnf']?.toStringAsFixed(2) ?? '0.00'}',
      'Overall Weighted CLR:,${stats['weightedClr']?.toStringAsFixed(2) ?? '0.00'}',
      'Total Amount (Rs):,${stats['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
      'Overall Average Rate (Rs/L):,${stats['averageRate']?.toStringAsFixed(2) ?? '0.00'}',
      '',
      'Thank you',
      'Poornasree Equipments',
      'Generated on: $currentDateTime'
    ];

    return csvLines.join('\n');
  }

  /// Send email with CSV and PDF attachments (similar to web app)
  static Future<Map<String, dynamic>> sendReportEmail({
    required String email,
    required String csvContent,
    required Uint8List pdfContent,
    required String reportType,
    required String dateRange,
    required Map<String, dynamic> stats,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendReportEmail),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
          'csvContent': csvContent,
          'pdfContent': base64Encode(pdfContent),
          'reportType': reportType,
          'dateRange': dateRange,
          'stats': stats,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Report sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to send email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Helper methods
  static pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 7 : 6,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static String _getChannelDisplay(String channel) {
    const channelMap = {
      'ch1': 'COW',
      'ch2': 'BUFFALO',
      'ch3': 'MIXED',
      'CH1': 'COW',
      'CH2': 'BUFFALO',
      'CH3': 'MIXED',
      'COW': 'COW',
      'BUFFALO': 'BUFFALO',
      'MIXED': 'MIXED',
      'cow': 'COW',
      'buffalo': 'BUFFALO',
      'mixed': 'MIXED',
      'BUF': 'BUFFALO',
      'MIX': 'MIXED',
    };
    return channelMap[channel] ?? channel.toUpperCase();
  }
}