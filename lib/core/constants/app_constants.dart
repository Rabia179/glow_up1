/// Application Constants for GLOW UP - Beauty & Skincare
class AppConstants {
  static const String appName = 'GLOW UP';
  static const String appTagline = 'Your beauty, your ritual.';
  static const String currencyPrefix = 'PKR';

  // Fallback high quality beauty image URLs from Stitch reference
  static const String fallbackHeroImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuATQMpSlAv7pihDABSfoS5LAix8ecpfvxtauX7X56NFEdhJmk7YJV11jbB3Yw2nal1s4DrB3fwrDQfXC-SvQD2r_rQOti6cBsgG_S4Spl9Z2gElhY8ZrXBqd-ESUasnsr86B1elsJSvbcI-VpSlOOGjPBl_CB_DcowWgrfVYIkhW5_QKUJ7WzuceE0-i6rBIIVeGdrbp-3QlBK-hA9RQFxqhDSlEVdsZoxIOmBhOcxziXKMQYNeEJ1VaA';

  static const String fallbackLogoUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCWWn8LC_r-Klyyb8CMAQ7pa9NR9m7xyyp6QCBASe9kRFNIN9DKVEe25zGIxLRfYyybbbD9EoZGsv5tF8SMIefb92DoL4itNdWAay4qRS1Tkje8Zw6QlqUQ0xmBr-PQTIMlVG8gETwbXcb95-ggWWOBY4Wj0Yj7gp0tvtU6xERPWIjIrCWXhff_WEw4szvDsB2RpEu7OHPHd-yHW20CrykMzzxlRdwcmtcV35X5dbT6e8Tig84NxGE3Lg';

  static const String fallbackAvatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBKUzX9mTN3xmR3TtGiYusLV1irimKDqgmxP-Zr0yR_mDC_FnYwFA3O7DKfm9qbcb1u0JtMGVbNKpR59qRcQtrHKhnymXpMM45x2DYj3s-0_zR2GYkMyfsJyZPwTtpnTFb8UWDolfU24oO9wRvv22drJVLWy5D-hZoNgbpvX_sOzQ-19L0vgrPKufiPwoly2yIfAaEHJAxgNsLr0a0pPC5_9fX1-8EN6tD-bQrOa8Rlav0LynCUyBtjEQ';

  /// Utility method to format price in PKR
  static String formatPrice(int amount) {
    // Add comma separation for thousands
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = amount.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$currencyPrefix $result';
  }
}
