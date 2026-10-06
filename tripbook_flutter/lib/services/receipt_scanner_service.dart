import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Accurate, On-Device, Offline Bill & Receipt Parser.
/// Uses Google ML Kit on-device text recognition with intelligent heuristic parsing.
class ReceiptScannerService {
  static final ReceiptScannerService _instance = ReceiptScannerService._internal();
  factory ReceiptScannerService() => _instance;
  ReceiptScannerService._internal();

  /// Scans an image file using on-device ML Kit OCR and extracts:
  /// - title (merchant/vendor name)
  /// - amount (grand total)
  /// - date (YYYY-MM-DD)
  /// - category_name
  /// - tax_amount
  /// - payment_method
  /// - items (list of line items)
  /// - raw_text
  Future<Map<String, dynamic>> scanReceiptFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      if (rawText.trim().isEmpty) {
        return _fallbackEmptyResult();
      }

      // Collect all lines in chronological/reading order
      final List<String> allLines = [];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final t = line.text.trim();
          if (t.isNotEmpty) {
            allLines.add(t);
          }
        }
      }

      return parseReceiptLines(allLines, rawText);
    } catch (e) {
      debugPrint('Error in ReceiptScannerService: $e');
      return _fallbackEmptyResult();
    } finally {
      await textRecognizer.close();
    }
  }

  /// Parses lines of recognized text with multi-tier heuristic recognition.
  Map<String, dynamic> parseReceiptLines(List<String> lines, String rawText) {
    final lowerRaw = rawText.toLowerCase();

    // 1. Amount Extraction (Grand Total)
    final double amount = _extractTotalAmount(lines, rawText);

    // 2. Date Extraction
    final String date = _extractDate(lines, rawText);

    // 3. Merchant / Vendor Title Extraction
    final List<String> candidates = _extractMerchantCandidates(lines, rawText);
    final String title = candidates.isNotEmpty ? candidates.first : 'Bill Expense';

    // 4. Category Classification
    final String category = _detectCategory(title, lowerRaw);

    // 5. Tax Extraction
    final double taxAmount = _extractTaxAmount(lines);

    // 6. Payment Method Detection
    final String paymentMethod = _detectPaymentMethod(lowerRaw);

    // 7. Line Items Extraction
    final List<Map<String, dynamic>> items = _extractLineItems(lines, amount);

    return {
      'title': title,
      'amount': amount,
      'date': date,
      'category_name': category,
      'tax_amount': taxAmount,
      'payment_method': paymentMethod,
      'confidence': amount > 0 ? 0.95 : 0.65,
      'items': items,
      'candidates': candidates,
      'raw_text': rawText,
    };
  }

  // =========================================================================
  // 1. TOTAL AMOUNT EXTRACTION
  // =========================================================================
  double _extractTotalAmount(List<String> lines, String rawText) {
    // Priority 1: Direct Grand Total keywords with number on same line
    final grandTotalRegex = RegExp(
      r'(?:grand\s*total|net\s*(?:amount|payable|total)|total\s*payable|amount\s*payable|total\s*paid|bill\s*amount|final\s*amount|final\s*total|total\s*due|amount\s*due)\s*[:.\-=\|\s]*\s*(?:₹|Rs\.?|INR|USD|\$|EUR|€|AED)?\s*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = grandTotalRegex.firstMatch(line);
      if (match != null) {
        final val = _parseNumber(match.group(1));
        if (val > 0 && val < 5000000) return val;
      }
    }

    // Priority 2: Keyword on one line, number on the very next line
    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].toLowerCase().trim();
      if (line == 'grand total' ||
          line == 'net payable' ||
          line == 'total payable' ||
          line == 'amount payable' ||
          line == 'total paid' ||
          line == 'total' ||
          line == 'net amount') {
        final nextLine = lines[i + 1].trim();
        final numMatch = RegExp(r'(?:₹|Rs\.?|INR|\$|€|AED)?\s*([0-9,]+\.?[0-9]*)').firstMatch(nextLine);
        if (numMatch != null) {
          final val = _parseNumber(numMatch.group(1));
          if (val > 0 && val < 5000000) return val;
        }
      }
    }

    // Priority 3: UPI / Digital Payment Screenshot (e.g. "₹ 1,500.00" or "Paid ₹1500")
    final upiAmountRegex = RegExp(
      r'(?:paid|sent|payment of|transfer(?:red)?)\s*(?:₹|Rs\.?|INR|\$)?\s*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = upiAmountRegex.firstMatch(line);
      if (match != null) {
        final val = _parseNumber(match.group(1));
        if (val > 0 && val < 5000000) return val;
      }
    }

    // Look for standalone prominent currency symbols: "₹ 1,450.00" or "₹1450"
    for (final line in lines) {
      final match = RegExp(r'^[₹]\s*([0-9,]+\.?[0-9]*)').firstMatch(line.trim());
      if (match != null) {
        final val = _parseNumber(match.group(1));
        if (val > 0 && val < 5000000) return val;
      }
    }

    // Priority 4: General "Total" keyword
    final generalTotalRegex = RegExp(
      r'(?<!sub\s)(?<!qty\s)(?<!items\s)\btotal\b\s*[:.\-=\|\s]*\s*(?:₹|Rs\.?|INR|\$|EUR|€|AED)?\s*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = generalTotalRegex.firstMatch(line);
      if (match != null) {
        final val = _parseNumber(match.group(1));
        if (val > 0 && val < 5000000) return val;
      }
    }

    // Priority 5: Sub Total if grand total is missing
    final subTotalRegex = RegExp(
      r'sub\s*total\s*[:.\-=\|\s]*\s*(?:₹|Rs\.?|INR|\$)?\s*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = subTotalRegex.firstMatch(line);
      if (match != null) {
        final val = _parseNumber(match.group(1));
        if (val > 0 && val < 5000000) return val;
      }
    }

    // Priority 6: Find all decimals with standard 2 decimal places and take the maximum
    // (excluding 10-digit phone numbers, GST numbers, timestamps, etc.)
    final List<double> candidates = [];
    final allNumbersRegex = RegExp(r'(?:₹|Rs\.?|INR|\$)?\s*([0-9]{1,6}\.[0-9]{2})\b');
    for (final m in allNumbersRegex.allMatches(rawText)) {
      final val = _parseNumber(m.group(1));
      if (val > 0 && val < 1000000) {
        candidates.add(val);
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort();
      return candidates.last;
    }

    return 0.0;
  }

  // =========================================================================
  // 2. DATE EXTRACTION
  // =========================================================================
  String _extractDate(List<String> lines, String rawText) {
    final now = DateTime.now();
    final defaultDate = '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}';

    // 1. DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyRegex = RegExp(r'\b([0-3]?[0-9])[\/\-\.]([0-1]?[0-9])[\/\-\.](20[2-3][0-9]|[2-3][0-9])\b');
    final dmyMatch = dmyRegex.firstMatch(rawText);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!) ?? 1;
      final month = int.tryParse(dmyMatch.group(2)!) ?? 1;
      var year = int.tryParse(dmyMatch.group(3)!) ?? now.year;
      if (year < 100) year += 2000;
      if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2020 && year <= 2030) {
        return '$year-${_twoDigits(month)}-${_twoDigits(day)}';
      }
    }

    // 2. YYYY-MM-DD or YYYY/MM/DD
    final ymdRegex = RegExp(r'\b(20[2-3][0-9])[\/\-\.]([0-1]?[0-9])[\/\-\.]([0-3]?[0-9])\b');
    final ymdMatch = ymdRegex.firstMatch(rawText);
    if (ymdMatch != null) {
      final year = int.tryParse(ymdMatch.group(1)!) ?? now.year;
      final month = int.tryParse(ymdMatch.group(2)!) ?? 1;
      final day = int.tryParse(ymdMatch.group(3)!) ?? 1;
      if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
        return '$year-${_twoDigits(month)}-${_twoDigits(day)}';
      }
    }

    // 3. Month Name: "12 Oct 2026" or "Oct 12, 2026" or "12-Oct-26"
    final monthNameRegex = RegExp(
      r'\b([0-3]?[0-9])?\s*(?:st|nd|rd|th)?\s*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s,\-]+([0-3]?[0-9])?[\s,\-]+(20[2-3][0-9]|[2-3][0-9])\b',
      caseSensitive: false,
    );
    final mMatch = monthNameRegex.firstMatch(rawText);
    if (mMatch != null) {
      final monthStr = (mMatch.group(2) ?? '').toLowerCase();
      final monthNum = _monthNameToNumber(monthStr);
      final d1 = int.tryParse(mMatch.group(1) ?? '');
      final d2 = int.tryParse(mMatch.group(3) ?? '');
      final day = d1 ?? d2 ?? now.day;
      var year = int.tryParse(mMatch.group(4) ?? '') ?? now.year;
      if (year < 100) year += 2000;
      return '$year-${_twoDigits(monthNum)}-${_twoDigits(day)}';
    }

    return defaultDate;
  }

  // =========================================================================
  // 3. MERCHANT / VENDOR NAME EXTRACTION
  // =========================================================================
  List<String> _extractMerchantCandidates(List<String> lines, String rawText) {
    final List<String> candidates = [];
    final blacklist = RegExp(
      r'(?:tax\s*invoice|bill|cash\s*memo|retail\s*invoice|receipt|original|duplicate|welcome|thank\s*you|customer|table|gstin|gst\s*no|fssai|phone|mobile|tel|address|date|time|pos|order|dine\s*in|take\s*away|delivery|invoice\s*no|token\s*no|cashier|biller)',
      caseSensitive: false,
    );

    // 1. Digital payment screenshot pattern: "Paid to XYZ" or "To: XYZ"
    final paidToRegex = RegExp(
      r"(?:paid to|payment to|to:)\s+([A-Za-z0-9\s&.'\-]{3,40})",
      caseSensitive: false,
    );
    final ptMatch = paidToRegex.firstMatch(rawText);
    if (ptMatch != null) {
      final name = ptMatch.group(1)?.trim();
      if (name != null && name.length >= 3) {
        final cleaned = _cleanTitle(name);
        if (cleaned.length >= 3 && !candidates.contains(cleaned)) {
          candidates.add(cleaned);
        }
      }
    }

    // 2. Scan top 12 lines of physical receipt
    for (int i = 0; i < lines.length && i < 12; i++) {
      final line = lines[i].trim();
      if (line.length < 3 || !RegExp(r'[a-zA-Z]').hasMatch(line)) continue;
      if (line.contains('+') || RegExp(r'^\d+$').hasMatch(line)) continue;
      if (blacklist.hasMatch(line)) continue;

      final cleaned = _cleanTitle(line);
      if (cleaned.length >= 3 && !candidates.contains(cleaned)) {
        candidates.add(cleaned);
      }
    }

    // Sort by store name heuristic score
    candidates.sort((a, b) {
      final scoreA = _scoreCandidateTitle(a);
      final scoreB = _scoreCandidateTitle(b);
      return scoreB.compareTo(scoreA);
    });

    return candidates;
  }

  int _scoreCandidateTitle(String t) {
    int score = 0;
    final lower = t.toLowerCase();
    // Keywords strongly indicating store/restaurant/business
    if (RegExp(r'(?:pizza|cafe|restaurant|hotel|bistro|kitchen|mart|store|bakery|dhaba|bar|lounge|fast\s*food|sweets|food|supermarket|enterprises|retreat|villa)').hasMatch(lower)) {
      score += 25;
    }
    final words = t.split(' ').where((w) => w.isNotEmpty).length;
    if (words >= 2) score += 12;
    if (words == 1 && t.length <= 4) score -= 15; // penalize fragments like "Opt", "No"
    if (t.length >= 6) score += 5;
    return score;
  }

  String _extractMerchantName(List<String> lines, String rawText) {
    final candidates = _extractMerchantCandidates(lines, rawText);
    if (candidates.isNotEmpty) {
      return candidates.first;
    }
    return 'Bill Expense';
  }

  // =========================================================================
  // 4. CATEGORY CLASSIFICATION
  // =========================================================================
  String _detectCategory(String title, String lowerText) {
    final combined = '${title.toLowerCase()} $lowerText';

    // Food & Dining (High priority: Check for food keywords, dining, pizza, cafe, etc.)
    if (RegExp(r'(?:pizza|burger|cafe|bistro|restaurant|food|kitchen|dine|dining|coffee|tea|sandwich|biryani|thali|paneer|chicken|dessert|bakery|fssai|swiggy|zomato|bar\b|pub\b)').hasMatch(combined)) {
      return 'Food & Dining';
    }

    // Fuel
    if (RegExp(r'(?:petrol|diesel|cng|fuel|hpcl|bpcl|iocl|indian\s*oil|bharat\s*petroleum|shell\b|fuel\s*station|pump)').hasMatch(combined)) {
      return 'Fuel';
    }

    // Stay & Hotel
    if (RegExp(r'(?:hotel|resort|lodge|\bstay\b|room\s*tariff|homestay|check\s*in|check\s*out|oyo\b|airbnb)').hasMatch(combined)) {
      return 'Stay & Hotel';
    }

    // Travel / Transport
    if (RegExp(r'(?:uber|ola\b|cab\b|taxi|toll\b|parking|flight|airline|train|irctc|metro|indigo|air\s*india|fastag|bus\b)').hasMatch(combined)) {
      return 'Travel';
    }

    // Entertainment
    if (RegExp(r'(?:movie|cinema|pvr|inox|cinepolis|theatre|concert|show|game|bowling|amusement|tickets)').hasMatch(combined)) {
      return 'Entertainment';
    }

    // Groceries
    if (RegExp(r'(?:supermarket|grocery|groceries|mart\b|dmart|reliance\s*fresh|blinkit|zepto|instamart|vegetable|fruit|dairy|milk|kirana)').hasMatch(combined)) {
      return 'Groceries';
    }

    // Shopping
    if (RegExp(r'(?:zara|h&m|pantaloons|trends|mall|clothing|apparel|footwear|fashion|decathlon|croma|shoppers\s*stop)').hasMatch(combined)) {
      return 'Shopping';
    }

    return 'Food & Dining'; // Default
  }

  // =========================================================================
  // 5. TAX AMOUNT EXTRACTION
  // =========================================================================
  double _extractTaxAmount(List<String> lines) {
    double totalTax = 0.0;
    final taxRegex = RegExp(
      r'(?:cgst|sgst|igst|gst|vat|sales\s*tax|service\s*tax|tax)\s*[:.\-=\|\s]*\s*(?:₹|Rs\.?|INR|\$)?\s*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = taxRegex.firstMatch(line);
      if (match != null) {
        final val = _parseNumber(match.group(1));
        if (val > 0 && val < 50000) {
          totalTax += val;
        }
      }
    }

    return totalTax;
  }

  // =========================================================================
  // 6. PAYMENT METHOD
  // =========================================================================
  String _detectPaymentMethod(String lowerText) {
    if (RegExp(r'(?:upi|gpay|google\s*pay|phonepe|paytm|bhim)').hasMatch(lowerText)) {
      return 'upi';
    }
    if (RegExp(r'(?:visa|mastercard|credit\s*card|debit\s*card|rupay|card)').hasMatch(lowerText)) {
      return 'card';
    }
    if (RegExp(r'(?:net\s*banking|neft|rtgs|imps|bank\s*transfer)').hasMatch(lowerText)) {
      return 'bank';
    }
    return 'cash';
  }

  // =========================================================================
  // 7. LINE ITEMS EXTRACTION
  // =========================================================================
  List<Map<String, dynamic>> _extractLineItems(List<String> lines, double grandTotal) {
    final List<Map<String, dynamic>> items = [];
    final skipKeywords = RegExp(
      r'(?:total|sub\s*total|grand\s*total|net\s*payable|cgst|sgst|gst|tax|discount|round\s*off|bill|invoice|date|time|fssai|gstin|cash|card|upi|balance|change|token|pax|table)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (skipKeywords.hasMatch(line)) continue;

      // Pattern: "Item Name 2 250.00" or "Item Name 250.00"
      final itemMatch = RegExp(
        r"^([A-Za-z0-9\s&.'\-]{3,35})\s+(?:(\d+)\s+)?(?:₹|Rs\.?|\$)?\s*([0-9,]+\.[0-9]{2})$",
      ).firstMatch(line.trim());

      if (itemMatch != null) {
        final name = _cleanTitle(itemMatch.group(1) ?? '');
        final qty = int.tryParse(itemMatch.group(2) ?? '') ?? 1;
        final price = _parseNumber(itemMatch.group(3));

        if (name.length >= 3 && price > 0 && (grandTotal == 0 || price <= grandTotal)) {
          items.add({
            'name': name,
            'price': price,
            'quantity': qty,
          });
        }
      }
    }

    return items;
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================
  double _parseNumber(String? raw) {
    if (raw == null) return 0.0;
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _cleanTitle(String raw) {
    var cleaned = raw.replaceAll(RegExp(r"[^\w\s()'&.-]"), '').trim();
    if (cleaned.length > 40) {
      cleaned = cleaned.substring(0, 40);
    }
    // Capitalize words
    return cleaned.split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : '');
    }).join(' ').trim();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  int _monthNameToNumber(String m) {
    switch (m.substring(0, 3).toLowerCase()) {
      case 'jan': return 1;
      case 'feb': return 2;
      case 'mar': return 3;
      case 'apr': return 4;
      case 'may': return 5;
      case 'jun': return 6;
      case 'jul': return 7;
      case 'aug': return 8;
      case 'sep': return 9;
      case 'oct': return 10;
      case 'nov': return 11;
      case 'dec': return 12;
      default: return 1;
    }
  }

  Map<String, dynamic> _fallbackEmptyResult() {
    final now = DateTime.now();
    return {
      'title': 'Bill Expense',
      'amount': 0.0,
      'date': '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}',
      'category_name': 'Food & Dining',
      'tax_amount': 0.0,
      'payment_method': 'cash',
      'confidence': 0.5,
      'items': <Map<String, dynamic>>[],
      'raw_text': '',
    };
  }
}
