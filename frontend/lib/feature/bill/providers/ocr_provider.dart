import 'dart:io';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' hide TextLine;
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';

final ocrProvider =
    StateNotifierProvider<OcrNotifier, AsyncValue<Map<String, String>?>>((ref) {
      return OcrNotifier();
    });

class OcrNotifier extends StateNotifier<AsyncValue<Map<String, String>?>> {
  OcrNotifier() : super(const AsyncValue.data(null));

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  /// Scans bill using Camera
  Future<void> scanFromCamera() async {
    state = const AsyncValue.loading();
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        state = const AsyncValue.data(null);
        return;
      }
      await _processImageFile(File(image.path));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Uploads bill image from Gallery
  Future<void> scanFromGallery() async {
    state = const AsyncValue.loading();
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        state = const AsyncValue.data(null);
        return;
      }
      await _processImageFile(File(image.path));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Uploads bill PDF
  Future<void> scanFromPdf() async {
    state = const AsyncValue.loading();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final document = PdfDocument(
        inputBytes: await File(result.files.single.path!).readAsBytes(),
      );
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      final parsedData = _parseBillText(text);
      state = AsyncValue.data(parsedData);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _processImageFile(File file) async {
    try {
      final preprocessedFile = await _preprocessImage(file);

      final inputImage = InputImage.fromFile(preprocessedFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final parsedData = _parseBillFromBlocks(recognizedText);

      // Convert to base64 for database and UI preview
      try {
        final originalBytes = await file.readAsBytes();
        final base64String = base64Encode(originalBytes);
        parsedData['imageBase64'] = base64String;
      } catch (e) {
        // Continue even if image encoding fails
      }

      state = AsyncValue.data(parsedData);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<File> _preprocessImage(File originalImage) async {
    final bytes = await originalImage.readAsBytes();
    img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return originalImage;

    img.grayscale(decodedImage);
    img.adjustColor(decodedImage, contrast: 1.5);

    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/preprocessed_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(img.encodeJpg(decodedImage, quality: 90));
    return tempFile;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Smart spatial table parser
  // Maps labels to numbers by finding text blocks on the same logical Y-axis row
  // ─────────────────────────────────────────────────────────────────────────────
  Map<String, String> _parseBillFromBlocks(RecognizedText recognizedText) {
    final data = <String, String>{};
    final allLines = <TextLine>[];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }

    final numberRe = RegExp(r'-?([\d,]+\.\d+|[\d,]+)');

    String? findValueSpaces(
      List<RegExp> keywords, {
      bool allowNegative = true,
      bool preferNegative = false,
    }) {
      for (final kw in keywords) {
        for (final line in allLines) {
          if (!kw.hasMatch(line.text)) continue;

          // 1. Same block extraction
          final mMatch = kw.firstMatch(line.text)!;
          final after = line.text.substring(mMatch.end);
          final numMatch = RegExp(r'-?([\d,]+\.\d+|[\d,]+)').firstMatch(after);
          if (numMatch != null) {
            String v = numMatch.group(0)!.replaceAll(',', '');
            if (preferNegative && !v.contains('-'))
              continue; // Skip if we specifically want a negative sign
            if (!allowNegative && v.contains('-'))
              continue; // Skip if we explicitly want positive
            if (double.tryParse(v) != null) return v.replaceAll('-', '');
          }

          // 2. Spatial Row Search
          final vCenter = (line.boundingBox.top + line.boundingBox.bottom) / 2;

          final sameRowLines = allLines.where((l) {
            if (l == line) return false;
            // DENSE TABLE TIGHTNESS: Use 12px margin instead of 18px
            final lCenter = (l.boundingBox.top + l.boundingBox.bottom) / 2;
            if ((lCenter - vCenter).abs() > 12) return false;
            if (l.boundingBox.left < line.boundingBox.left) return false;
            return true;
          }).toList();

          // Sort by preference (negative sign first if requested, otherwise closest X)
          sameRowLines.sort((a, b) {
            if (preferNegative) {
              final aNeg = a.text.contains('-');
              final bNeg = b.text.contains('-');
              if (aNeg && !bNeg) return -1;
              if (bNeg && !aNeg) return 1;
            }
            return a.boundingBox.left.compareTo(b.boundingBox.left);
          });

          for (final rowLine in sameRowLines) {
            final possibleNumMatch = numberRe.firstMatch(rowLine.text);
            if (possibleNumMatch != null) {
              String v = possibleNumMatch.group(0)!.replaceAll(',', '');
              if (preferNegative && !v.contains('-')) continue;
              if (!allowNegative && v.contains('-')) continue;
              if (double.tryParse(v) != null) return v.replaceAll('-', '');
            }
          }
        }
      }
      return null;
    }

    // ── 1. Subsidy MUST match first (it's the most unique with its minus sign) ─
    final subVal = findValueSpaces([
      RegExp(r'M\.?P\.?\s+Govt\.?\s+Subsidy', caseSensitive: false),
      RegExp(r'Subsidy|Govt\.?\s+Subsidy', caseSensitive: false),
    ], preferNegative: true);
    if (subVal != null) {
      data['subsidyAmount'] = subVal;
    }

    // ── 2. Net Payable (Positive only) ───────────────────────────────────────
    final netVal = findValueSpaces([
      RegExp(r'Current\s+Month\s+Bill\s+Amount', caseSensitive: false),
      RegExp(r'Total\s+Amount\s+Payable', caseSensitive: false),
    ], allowNegative: false);
    if (netVal != null) {
      data['amountExact'] = netVal;
      data['netPayable'] = netVal;
    }

    // ── 3. Gross Amount (Positive only) ──────────────────────────────────────
    final grossVal = findValueSpaces([
      RegExp(r'^Month\s+Bill\s+Amount', caseSensitive: false),
      RegExp(r'Energy\s+Charges', caseSensitive: false),
    ], allowNegative: false);
    if (grossVal != null) {
      data['grossAmount'] = grossVal;
    }

    // ── 4. Units ─────────────────────────────────────────────────────────────
    // Fuzzy search for "Consumption" or "Units" using raw text context
    String? unitsVal;
    {
      final rawLines = recognizedText.text
          .split('\n')
          .map((l) => l.trim())
          .toList();
      // Extremely fuzzy to catch "Consumption", "Conumntion", "Consumption Detail"
      final consumptionKw = RegExp(
        r'(Final\s+Cons|Metered\s+Unit|Units?\s+Cons|Total\s+Units|Con[su].*tion|Unit)',
        caseSensitive: false,
      );
      final decimalOnlyRe = RegExp(r'^\s*(\d+\.\d+)\s*$');
      final simpleNumRe = RegExp(r'(\d+\.\d+|\d+)');

      for (int i = 0; i < rawLines.length; i++) {
        if (consumptionKw.hasMatch(rawLines[i])) {
          // 1. Look for decimal on the next 4 lines
          for (int j = i + 1; j < rawLines.length && j <= i + 4; j++) {
            final m = decimalOnlyRe.firstMatch(rawLines[j]);
            if (m != null) {
              unitsVal = m.group(1);
              break;
            }
          }
          if (unitsVal != null) break;

          // 2. Look for any number on the same line after keyword
          final afterIdx = rawLines[i].toLowerCase().indexOf('unit');
          final afterText = afterIdx != -1
              ? rawLines[i].substring(afterIdx)
              : rawLines[i];
          final sm = simpleNumRe.firstMatch(afterText);
          if (sm != null && i < 150) {
            // Safety check to keep it in main sections
            unitsVal = sm.group(1);
            break;
          }
        }
      }
    }
    if (unitsVal != null) data['units'] = unitsVal;

    // ── 5. Setup raw fallbacks ───────────────────────────────────────────────
    final fallbackData = _parseBillText(recognizedText.text);
    if (!data.containsKey('dueDate') && fallbackData.containsKey('dueDate')) {
      data['dueDate'] = fallbackData['dueDate']!;
    }
    if (!data.containsKey('consumerNumber') &&
        fallbackData.containsKey('consumerNumber')) {
      data['consumerNumber'] = fallbackData['consumerNumber']!;
    }

    data['rawText'] = recognizedText.text;
    return data;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Standard String Parser (Used for PDFs and as a fallback)
  // ─────────────────────────────────────────────────────────────────────────────
  Map<String, String> _parseBillText(String text) {
    final data = <String, String>{};

    // Split into non-empty trimmed lines
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // ── DEBUG: print raw OCR text to Flutter console ────────────────────────
    // TODO: Remove this before production build
    dev.log('══════════ OCR RAW TEXT START ══════════');
    dev.log(text);
    dev.log('══════════ OCR RAW TEXT END ════════════');
    dev.log('── LINES (${lines.length} total) ──');
    for (int i = 0; i < lines.length; i++) {
      dev.log('[$i] ${lines[i]}');
    }
    dev.log('────────────────────────────────────────');

    // ── Regex to extract the first number from a string ──────────────────────
    // Matches decimals like 613.31 or plain integers like 87
    final numberRe = RegExp(r'([\d,]+\.\d+|[\d,]+)');

    String? extractNumber(String s) {
      final m = numberRe.firstMatch(s);
      if (m == null) return null;
      final v = m.group(1)!.replaceAll(',', '');
      final parsed = double.tryParse(v);
      return (parsed != null && parsed > 0) ? v : null;
    }

    // ── Generic keyword→value search ─────────────────────────────────────────
    // Returns the first numeric value found after any of the provided keywords,
    // checking same-line or next-line. Falls through all keywords in order.
    String? findValue(List<RegExp> keywords) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final kw in keywords) {
          final kwMatch = kw.firstMatch(line);
          if (kwMatch != null) {
            // Case A: value on same line, after keyword
            final after = line.substring(kwMatch.end);
            final sameLineVal = extractNumber(after);
            if (sameLineVal != null) return sameLineVal;

            // Case B: value on the next line (short number-only line)
            if (i + 1 < lines.length) {
              final next = lines[i + 1];
              // Accept next line only if it looks like a standalone value
              // (≤25 chars, no alphabetical label keywords)
              if (next.length <= 25 &&
                  !RegExp(r'[A-Za-z]{4,}').hasMatch(next)) {
                final nextVal = extractNumber(next);
                if (nextVal != null) return nextVal;
              }
            }
          }
        }
      }
      return null;
    }

    // ── 1. Net Payable = Current Month Bill Amount ───────────────────────────
    final netVal = findValue([
      RegExp(r'Current\s+Month\s+Bill\s+Amount', caseSensitive: false),
      RegExp(r'Current\s+Month\s+Bill\s+Amt', caseSensitive: false),
    ]);
    if (netVal != null) {
      data['amountExact'] = netVal;
      data['netPayable'] = netVal;
    }

    // ── 2. Gross Amount = Month Bill Amount (before subsidy) ─────────────────
    //    We specifically look for lines beginning with "Month Bill Amount"
    //    (without "Current" prefix) to get the pre-subsidy total (613.31).
    String? grossVal;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Must start with Month Bill Amount (not the "Current" variant)
      if (RegExp(
        r'^Month\s+Bill\s+Amount',
        caseSensitive: false,
      ).hasMatch(line)) {
        final after = line.replaceFirst(
          RegExp(r'^Month\s+Bill\s+Amount', caseSensitive: false),
          '',
        );
        grossVal = extractNumber(after);
        if (grossVal == null && i + 1 < lines.length) {
          final next = lines[i + 1];
          if (next.length <= 25 && !RegExp(r'[A-Za-z]{4,}').hasMatch(next)) {
            grossVal = extractNumber(next);
          }
        }
        if (grossVal != null) break;
      }
    }
    // Fallback: Energy Charges line
    grossVal ??= findValue([RegExp(r'Energy\s+Charges', caseSensitive: false)]);
    if (grossVal != null) data['grossAmount'] = grossVal;

    // ── 3. Subsidy Amount ────────────────────────────────────────────────────
    //    Bills print subsidy as a negative: "-513.31" so we strip the sign.
    final subsidyRe = RegExp(
      r'(?:M\.?P\.?\s+Govt\.?\s+Subsidy|Govt\.?\s+Subsidy|Subsidy\s+Amount|Subsidy)',
      caseSensitive: false,
    );
    // Wider number match allowing leading minus
    final subsidyNumRe = RegExp(r'-?([\d,]+\.\d+|[\d,]+)');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (subsidyRe.hasMatch(line)) {
        final kwMatch = subsidyRe.firstMatch(line)!;
        final after = line.substring(kwMatch.end);
        final m = subsidyNumRe.firstMatch(after);
        if (m != null) {
          final v = m.group(1)!.replaceAll(',', '');
          if (double.tryParse(v) != null) {
            data['subsidyAmount'] = v;
            break;
          }
        }
        // Try next line
        if (!data.containsKey('subsidyAmount') && i + 1 < lines.length) {
          final next = lines[i + 1];
          if (next.length <= 25) {
            final m2 = subsidyNumRe.firstMatch(next);
            if (m2 != null) {
              final v = m2.group(1)!.replaceAll(',', '');
              if (double.tryParse(v) != null) {
                data['subsidyAmount'] = v;
                break;
              }
            }
          }
        }
      }
    }

    // ── 4. Units Consumed ─────────────────────────────────────────────────────
    final unitsVal = findValue([
      RegExp(r'Final\s+Consumption', caseSensitive: false),
      RegExp(r'Metered\s+Unit\s+Consumption', caseSensitive: false),
      RegExp(r'Units\s+Consumed', caseSensitive: false),
      RegExp(r'Total\s+Units', caseSensitive: false),
    ]);
    if (unitsVal != null) data['units'] = unitsVal;

    // ── 5. Due Date ───────────────────────────────────────────────────────────
    final dueDateRegexes = [
      RegExp(
        r'Due\s+Date\s*[:\-]?\s*(\d{2}[-/]\d{2}[-/]\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(
        r'Due\s+Date\s*[:\-]?\s*(\d{2}[a-zA-Z]+\d{2,4})',
        caseSensitive: false,
      ),
    ];
    for (final re in dueDateRegexes) {
      final m = re.firstMatch(text);
      if (m != null) {
        data['dueDate'] = m.group(1) ?? '';
        break;
      }
    }
    // Multi-line fallback
    if (!data.containsKey('dueDate')) {
      for (int i = 0; i < lines.length; i++) {
        if (RegExp(r'Due\s+Date', caseSensitive: false).hasMatch(lines[i])) {
          if (i + 1 < lines.length) {
            final dateMatch = RegExp(
              r'\d{2}[-/]\d{2}[-/]\d{2,4}',
            ).firstMatch(lines[i + 1]);
            if (dateMatch != null) {
              data['dueDate'] ??= dateMatch.group(0) ?? '';
              break;
            }
          }
        }
      }
    }

    // ── 6. Consumer Number ────────────────────────────────────────────────────
    for (int i = 0; i < lines.length; i++) {
      final m = RegExp(
        r'(?:Consumer\s+No\.?|IVRS\s+No\.?|Account\s+No\.?)\s*[:\-]?\s*([A-Z0-9\-_]{4,})',
        caseSensitive: false,
      ).firstMatch(lines[i]);
      if (m != null) {
        data['consumerNumber'] = m.group(1) ?? '';
        break;
      }
    }

    // ── 7. Billing Period dates ───────────────────────────────────────────────
    final dateRegex = RegExp(r'\b(\d{2}[/\-]\d{2}[/\-]\d{4})\b');
    final allDates = dateRegex
        .allMatches(text)
        .map((m) => m.group(1))
        .whereType<String>()
        .toList();
    if (allDates.length >= 2) {
      data['periodStart'] = allDates[1];
      data['periodEnd'] = allDates[0];
    } else if (allDates.isNotEmpty) {
      data['periodEnd'] = allDates[0];
    }

    data['rawText'] = text;
    return data;
  }
}
