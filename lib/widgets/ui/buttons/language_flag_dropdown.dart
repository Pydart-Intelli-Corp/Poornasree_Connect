import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/utils.dart';

class LanguageFlagDropdown extends StatefulWidget {
  final VoidCallback? onLanguageChanged;
  
  const LanguageFlagDropdown({
    super.key,
    this.onLanguageChanged,
  });

  @override
  State<LanguageFlagDropdown> createState() => _LanguageFlagDropdownState();
}

class _LanguageFlagDropdownState extends State<LanguageFlagDropdown> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  // Map languages to country flags (emojis)
  static const Map<String, String> _flagEmojis = {
    'en': '🇺🇸', // English - USA
    'ml': '🇮🇳', // Malayalam - India
    'hi': '🇮🇳', // Hindi - India
    'ta': '🇮🇳', // Tamil - India
    'mr': '🇮🇳', // Marathi - India
    'bn': '🇮🇳', // Bengali - India
    'te': '🇮🇳', // Telugu - India
    'kn': '🇮🇳', // Kannada - India
  };

  String _getFlagEmoji(String languageCode) {
    return _flagEmojis[languageCode] ?? '🌐';
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations();
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    // Get screen dimensions from SizeConfig
    final screenWidth = SizeConfig.screenWidth;
    final screenHeight = SizeConfig.screenHeight;
    
    // Dropdown dimensions
    final dropdownWidth = SizeConfig.normalize(280);
    final dropdownMaxHeight = SizeConfig.normalize(400);
    
    // Calculate horizontal position - align to right edge of button
    double horizontalOffset = 0;
    
    // Check if dropdown would go off-screen on the right
    if (offset.dx + dropdownWidth > screenWidth) {
      // Align dropdown's right edge with button's right edge
      horizontalOffset = size.width - dropdownWidth;
      
      // If still off-screen on the left, align with screen edge
      if (offset.dx + horizontalOffset < 0) {
        horizontalOffset = -offset.dx + SizeConfig.spaceSmall;
      }
    }
    
    // Calculate vertical position
    double verticalOffset = size.height + SizeConfig.spaceSmall;
    
    // Check if dropdown would go off-screen at bottom
    if (offset.dy + size.height + dropdownMaxHeight > screenHeight) {
      // Show above the button instead
      verticalOffset = -(dropdownMaxHeight + SizeConfig.spaceSmall);
    }

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeDropdown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: dropdownWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(horizontalOffset, verticalOffset),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(SizeConfig.radiusRegular + 2),
                  color: Colors.transparent,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: SizeConfig.normalize(400),
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBg2 : AppTheme.cardLight,
                      borderRadius: BorderRadius.circular(SizeConfig.radiusRegular + 2),
                      border: Border.all(
                        color: isDark 
                            ? AppTheme.primaryGreen.withOpacity(0.2)
                            : AppTheme.borderLight,
                        width: SizeConfig.normalize(1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.15),
                          blurRadius: SizeConfig.normalize(20),
                          offset: Offset(0, SizeConfig.normalize(8)),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SizeConfig.radiusRegular + 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: EdgeInsets.all(SizeConfig.spaceRegular),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen.withOpacity(0.1),
                                  AppTheme.primaryTeal.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark 
                                      ? AppTheme.borderDark.withOpacity(0.3)
                                      : AppTheme.borderLight,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(SizeConfig.spaceSmall - 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.primaryGreen, AppTheme.primaryTeal],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(SizeConfig.radiusSmall),
                                  ),
                                  child: Icon(
                                    Icons.translate_rounded,
                                    size: SizeConfig.iconSizeSmall + 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: SizeConfig.spaceSmall),
                                Text(
                                  'Select Language',
                                  style: TextStyle(
                                    fontSize: SizeConfig.fontSizeRegular,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Language list
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: AppLocale.values.length,
                              itemBuilder: (context, index) {
                                final locale = AppLocale.values[index];
                                final isSelected = l10n.currentLocale == locale;
                                
                                return InkWell(
                                  onTap: () async {
                                    await l10n.setLocale(locale);
                                    _closeDropdown();
                                    widget.onLanguageChanged?.call();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.spaceRegular,
                                      vertical: SizeConfig.spaceSmall + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryGreen.withOpacity(0.08)
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isDark 
                                              ? AppTheme.borderDark.withOpacity(0.2)
                                              : AppTheme.borderLight.withOpacity(0.4),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Flag
                                        Container(
                                          width: SizeConfig.normalize(36),
                                          height: SizeConfig.normalize(36),
                                          decoration: BoxDecoration(
                                            color: isDark 
                                                ? AppTheme.darkBg.withOpacity(0.5)
                                                : AppTheme.lightBg2,
                                            borderRadius: BorderRadius.circular(SizeConfig.radiusSmall),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppTheme.primaryGreen.withOpacity(0.3)
                                                  : (isDark 
                                                      ? AppTheme.borderDark.withOpacity(0.3)
                                                      : AppTheme.borderLight.withOpacity(0.5)),
                                              width: 1,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _getFlagEmoji(locale.code),
                                            style: TextStyle(
                                              fontSize: SizeConfig.fontSizeLarge,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: SizeConfig.spaceSmall),
                                        
                                        // Language names
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                locale.nativeName,
                                                style: TextStyle(
                                                  fontSize: SizeConfig.fontSizeRegular,
                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                  color: isSelected
                                                      ? AppTheme.primaryGreen
                                                      : (isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight),
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              SizedBox(height: SizeConfig.spaceTiny / 2),
                                              Text(
                                                locale.englishName,
                                                style: TextStyle(
                                                  fontSize: SizeConfig.fontSizeXSmall + 1,
                                                  color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                                  letterSpacing: 0.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Selected indicator
                                        if (isSelected)
                                          Container(
                                            padding: EdgeInsets.all(SizeConfig.spaceTiny),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primaryGreen,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: SizeConfig.iconSizeSmall - 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final l10n = AppLocalizations();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFlag = _getFlagEmoji(l10n.currentLocale.code);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.spaceSmall + 2,
              vertical: SizeConfig.spaceSmall - 2,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppTheme.darkBg2.withOpacity(0.6)
                  : AppTheme.cardLight.withOpacity(0.9),
              borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
              border: Border.all(
                color: _isOpen
                    ? AppTheme.primaryGreen.withOpacity(0.4)
                    : (isDark 
                        ? AppTheme.borderDark.withOpacity(0.3)
                        : AppTheme.borderLight.withOpacity(0.5)),
                width: SizeConfig.normalize(1),
              ),
              boxShadow: _isOpen
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        blurRadius: SizeConfig.normalize(8),
                        offset: Offset(0, SizeConfig.normalize(2)),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flag emoji
                Text(
                  currentFlag,
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeLarge + 2,
                  ),
                ),
                SizedBox(width: SizeConfig.spaceSmall - 2),
                
                // Dropdown icon
                Icon(
                  _isOpen ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                  size: SizeConfig.iconSizeMedium,
                  color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
