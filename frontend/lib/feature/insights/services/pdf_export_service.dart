import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:watt_sense/feature/insights/models/insights_data_model.dart';

class PdfExportService {
  static Future<void> exportInsightsToPdf(InsightsDataModel data) async {
    final pdf = pw.Document();

    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#448AFF'), // Blue Accent
    );
    final headerStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#1565C0'), // Blue 800
    );
    final bodyStyle = const pw.TextStyle(fontSize: 12, color: PdfColors.black);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('WattWise', style: titleStyle),
                  pw.Text(
                    'Insights Report - ${data.reportMonth}',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 30),

              // SECTION 1: Efficiency Score
              pw.Text('Efficiency Score', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EFF6FF'), // Blue 50
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          '${data.efficiencyScore}',
                          style: pw.TextStyle(
                            fontSize: 36,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1565C0'), // Blue 800
                          ),
                        ),
                        pw.Text(
                          '/100',
                          style: pw.TextStyle(
                            fontSize: 18,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Better than ',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.Text(
                          '${data.betterThanPercentage}%',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.green700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          ' of similar homes',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // SECTION 2: Appliance Breakdown
              pw.Text('Appliance Breakdown', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                cellAlignment: pw.Alignment.centerLeft,
                headers: <String>['Appliance', 'Usage (%)'],
                data: data.topAppliances
                    .map((a) => [a.name, '${a.percentage}%'])
                    .toList(),
              ),
              pw.SizedBox(height: 30),

              // SECTION 3: AI Insights
              pw.Text('AI Insights', style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FAFAFA'), // Grey 50
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Text(
                  data.aiInsightText,
                  style: bodyStyle.copyWith(lineSpacing: 1.5),
                ),
              ),

              // FOOTER
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Generated by WattWise AI',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'WattWise_Insights_${data.reportMonth.replaceAll(' ', '_')}.pdf',
    );
  }
}
