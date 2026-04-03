import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/feature/bill/widgets/upload_photo_button.dart';
import '../providers/fetch_bill_provider.dart';
import '../providers/ocr_provider.dart';
import 'ocr_scanning_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _billerIdController = TextEditingController();
  final _consumerNumberController = TextEditingController();
  final _unitsController = TextEditingController();
  final _amountController = TextEditingController(); // Net Payable
  final _grossAmountController = TextEditingController();
  final _subsidyAmountController = TextEditingController();

  final _dueDateController = TextEditingController();
  final _periodStartController = TextEditingController();
  final _periodEndController = TextEditingController();

  @override
  void dispose() {
    _billerIdController.dispose();
    _consumerNumberController.dispose();
    _unitsController.dispose();
    _amountController.dispose();
    _grossAmountController.dispose();
    _subsidyAmountController.dispose();

    _dueDateController.dispose();
    _periodStartController.dispose();
    _periodEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch state to update UI like loading indicators
    final fetchState = ref.watch(fetchBillProvider);
    final ocrState = ref.watch(ocrProvider);

    // Listen to OCR provider for side effects
    ref.listen(ocrProvider, (previous, next) {
      if (next.isLoading) return;

      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OCR Error: ${next.error.toString().split('Exception: ').last}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.hasValue &&
          next.value != null &&
          previous?.value != next.value) {
        final data = next.value!;

        setState(() {
          if (data['amountExact']?.isNotEmpty == true) {
            _amountController.text = data['amountExact']!;
          }
          if (data['grossAmount']?.isNotEmpty == true) {
            _grossAmountController.text = data['grossAmount']!;
          }
          if (data['subsidyAmount']?.isNotEmpty == true) {
            _subsidyAmountController.text = data['subsidyAmount']!;
          }
          if (data['consumerNumber']?.isNotEmpty == true) {
            _consumerNumberController.text = data['consumerNumber']!;
          }
          if (data['dueDate']?.isNotEmpty == true) {
            _dueDateController.text = data['dueDate']!;
          }
          if (data['units']?.isNotEmpty == true) {
            _unitsController.text = data['units']!;
          }
          if (data['periodStart']?.isNotEmpty == true) {
            _periodStartController.text = data['periodStart']!;
          }
          if (data['periodEnd']?.isNotEmpty == true) {
            _periodEndController.text = data['periodEnd']!;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill data extracted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Listen to provider for exactly-once side effects (snackbars) and state mutations
    ref.listen(fetchBillProvider, (previous, next) {
      if (next.isLoading) return;

      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.hasValue &&
          next.value != null &&
          previous?.value != next.value) {
        final data = next.value!;
        final amountDue =
            data['data']?['amountExact'] ?? data['amountExact'] ?? '';
        final billName =
            data['data']?['billerName'] ?? data['billerName'] ?? 'Your Bill';

        final consumerNumberExtracted =
            data['data']?['consumerNumber'] ?? data['consumerNumber'] ?? 'N/A';
        final dueDate = data['data']?['dueDate'] ?? data['dueDate'] ?? '';

        setState(() {
          _amountController.text = amountDue.toString();
          if (consumerNumberExtracted != 'N/A') {
            _consumerNumberController.text = consumerNumberExtracted.toString();
          }
          if (dueDate.toString().isNotEmpty) {
            _dueDateController.text = dueDate.toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill data fetched securely for $billName!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Add Bill",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UploadPhotoButton(
                onPressed: () async {
                  // Request camera and storage/photo permissions
                  final statuses = await [
                    Permission.camera,
                    Permission.storage,
                    Permission.photos,
                  ].request();

                  bool isAnyGranted = false;
                  bool isAnyPermanentlyDenied = false;

                  for (var status in statuses.values) {
                    if (status.isGranted || status.isLimited) {
                      isAnyGranted = true;
                    }
                    if (status.isPermanentlyDenied) {
                      isAnyPermanentlyDenied = true;
                    }
                  }

                  if (!context.mounted) return;

                  if (!isAnyGranted) {
                    if (isAnyPermanentlyDenied) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text(
                            'Permissions Required',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Camera and photos permissions are restricted. Please enable them in system settings to upload or scan a bill.',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                openAppSettings();
                              },
                              child: Text(
                                'Open Settings',
                                style: GoogleFonts.poppins(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Permissions are required to scan or upload files.',
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    return;
                  }

                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Scan Electricity Bill",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.primaryBlue,
                                ),
                                title: Text(
                                  "Scan bill using camera",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  ref
                                      .read(ocrProvider.notifier)
                                      .scanFromCamera();
                                  if (context.mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const OcrScanningScreen(),
                                      ),
                                    );
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.photo_library_rounded,
                                  color: AppColors.primaryBlue,
                                ),
                                title: Text(
                                  "Upload bill image from gallery",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  ref
                                      .read(ocrProvider.notifier)
                                      .scanFromGallery();
                                  if (context.mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const OcrScanningScreen(),
                                      ),
                                    );
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: AppColors.primaryBlue,
                                ),
                                title: Text(
                                  "Upload bill PDF",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  ref.read(ocrProvider.notifier).scanFromPdf();
                                  if (context.mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const OcrScanningScreen(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: Colors.grey.shade200),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "or fetch via BBPS",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary.withAlpha(150),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: Colors.grey.shade200),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleTextField(
                      label: "Biller ID",
                      hintText: "E.g. BESCOM",
                      controller: _billerIdController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSimpleTextField(
                      label: "Consumer No.",
                      hintText: "12345678",
                      controller: _consumerNumberController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: fetchState.isLoading || ocrState.isLoading
                      ? null
                      : () {
                          FocusScope.of(context).unfocus(); // Dismiss keyboard
                          ref
                              .read(fetchBillProvider.notifier)
                              .fetchBill(
                                billerId: _billerIdController.text.trim(),
                                consumerNumber: _consumerNumberController.text
                                    .trim(),
                              );
                        },
                  icon: fetchState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_download_rounded,
                          color: AppColors.primaryBlue,
                        ),
                  label: Text(
                    fetchState.isLoading
                        ? "Fetching from BBPS..."
                        : "Fetch Bill Data",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: Colors.grey.shade200),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "enter manually",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary.withAlpha(150),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: Colors.grey.shade200),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                "Billing Period",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextField(
                        controller: _periodStartController,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: "Start",
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          hintText: "mm/dd/yy",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextField(
                        controller: _periodEndController,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: "End",
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          hintText: "mm/dd/yy",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: AppColors.primaryBlue,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Usual cycle is 30 days",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildLabelledTextField(
                label: "Units Consumed",
                hintText: "0",
                controller: _unitsController,
                suffix: Text(
                  "kWh",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildLabelledTextField(
                label: "Total Amount (Net Payable)",
                hintText: "0.00",
                controller: _amountController,
                prefix: Text(
                  "₹  ",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildLabelledTextField(
                label: "Gross Amount",
                optional: true,
                hintText: "0.00",
                controller: _grossAmountController,
                prefix: Text(
                  "₹  ",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildLabelledTextField(
                label: "Subsidy Amount",
                optional: true,
                hintText: "0.00",
                controller: _subsidyAmountController,
                prefix: Text(
                  "₹  ",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildLabelledTextField(
                label: "CONSUMER NO. / IVRS NO.",
                hintText: "e.g. N3002011745",
                controller: _consumerNumberController,
                hintColor: AppColors.textSecondary.withAlpha(150),
              ),

              const SizedBox(height: 24),
              _buildLabelledTextField(
                label: "DUE DATE",
                optional: true,
                hintText: "mm/dd/yyyy",
                controller: _dueDateController,
                hintColor: AppColors.textSecondary.withAlpha(150),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: fetchState.isLoading || ocrState.isLoading
                      ? null
                      : () async {
                          final ocrData = ref.read(ocrProvider).valueOrNull;

                          final billData = {
                            'amountExact': _amountController.text.isNotEmpty
                                ? _amountController.text
                                : '0.00',
                            'grossAmount':
                                _grossAmountController.text.isNotEmpty
                                ? _grossAmountController.text
                                : '0.00',
                            'subsidyAmount':
                                _subsidyAmountController.text.isNotEmpty
                                ? _subsidyAmountController.text
                                : '0.00',
                            'billNumber':
                                'N/A', // Deprecated on UI but kept for backend
                            'dueDate': _dueDateController.text.isNotEmpty
                                ? _dueDateController.text
                                : 'N/A',
                            'consumerNumber': _consumerNumberController.text,
                            'billerId': _billerIdController.text,
                            'units': _unitsController.text.isNotEmpty
                                ? _unitsController.text
                                : '0',
                            'imageBase64': ocrData?['imageBase64'],
                          };

                          // Upload to MongoDB database via Backend API call
                          try {
                            await ApiClient.instance.post(
                              '/bills',
                              data: billData,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bill stored securely in DB!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            // Ignore error and continue saving locally if endpoint is not ready
                          }

                          if (!mounted) return;

                          // Store exactly what is in the text fields locally for UI updates
                          ref
                              .read(savedBillProvider.notifier)
                              .saveBill(billData);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Save Bill",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: fetchState.isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary.withAlpha(150),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelledTextField({
    required String label,
    bool optional = false,
    required String hintText,
    Color? hintColor,
    Widget? prefix,
    Widget? suffix,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: optional ? 0.5 : 0.0,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 4),
              Text(
                "(optional)",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary.withAlpha(150),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56, // Match design larger text fields
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                fontSize: 16,
                color: hintColor ?? AppColors.textPrimary,
              ),
              prefixIcon: prefix != null
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 8.0,
                        top: 16.0,
                        bottom: 16.0,
                      ),
                      child: prefix,
                    )
                  : null,
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.only(
                        right: 16.0,
                        top: 16.0,
                        bottom: 16.0,
                      ),
                      child: suffix,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
