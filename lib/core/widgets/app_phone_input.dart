import 'package:alma_desktop/core/theme/app_styles.dart';
import 'package:alma_desktop/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flagCode;
  final String phoneRegex;

  Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flagCode,
    required this.phoneRegex,
  });

  static final Country kuwait = Country(
    name: 'الكويت',
    code: 'KW',
    dialCode: '+965',
    flagCode: 'KW',
    phoneRegex: r'^(\+965|965|0)?[5-9]\d{7}$',
  );
}

class AppPhoneInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool? isEnabled;
  final Function(String)? onChanged;
  final String? Function(String)? validator;
  final Country? initialCountry;
  final Widget? suffixIcon;
  final Function(String)? onCountryChanged;

  const AppPhoneInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.isEnabled,
    this.onChanged,
    this.validator,
    this.initialCountry,
    this.suffixIcon,
    this.onCountryChanged,
  });

  @override
  State<AppPhoneInput> createState() => _AppPhoneInputState();
}

class _AppPhoneInputState extends State<AppPhoneInput> {
  Country? _selectedCountry;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? _countries.first;
    // Delay the callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCountryChanged?.call(_selectedCountry!.dialCode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCountryPicker() {
    _searchController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCountryPickerSheet(),
    );
  }

  Widget _buildCountryPickerSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        List<Country> filteredCountries = _countries;

        void filterCountries(String query) {
          setSheetState(() {
            if (query.isEmpty) {
              filteredCountries = _countries;
            } else {
              filteredCountries = _countries.where((country) {
                return country.name.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    country.dialCode.contains(query) ||
                    country.code.toLowerCase().contains(query.toLowerCase());
              }).toList();
            }
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: AppTheme.baseWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Text(
                      'اختر الدولة',
                      style: AppStyles.titleLarge.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppTheme.gray500),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Search field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: TextField(
                  controller: _searchController,
                  onChanged: filterCountries,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن الدولة...',
                    hintStyle: AppStyles.bodyMedium.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray500,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppTheme.gray500),
                    filled: true,
                    fillColor: AppTheme.gray25,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: AppTheme.gray200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: AppTheme.brandMain2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Countries list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  itemCount: filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = filteredCountries[index];
                    final isSelected = _selectedCountry?.code == country.code;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                        });
                        widget.onCountryChanged?.call(country.dialCode);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.brandMain2_100
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            // Flag
                            Image.network(
                              'https://flagsapi.com/${country.flagCode}/flat/64.png',
                              width: 32.w,
                              height: 32.w,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 32.w,
                                  height: 32.w,
                                  decoration: BoxDecoration(
                                    color: AppTheme.gray200,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.flag,
                                    size: 20.sp,
                                    color: AppTheme.gray500,
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 12.w),
                            // Country name
                            Expanded(
                              child: Text(
                                country.name,
                                style: AppStyles.bodyMedium.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.gray800,
                                ),
                              ),
                            ),
                            // Dial code
                            Text(
                              country.dialCode,
                              style: AppStyles.bodyMedium.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.gray500,
                              ),
                            ),
                            if (isSelected) ...[
                              SizedBox(width: 12.w),
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.brandMain2,
                                size: 20.sp,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppStyles.titleSmall.copyWith()),
          SizedBox(height: 8.h),
        ],
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            enabled: widget.isEnabled ?? true,
            onChanged: widget.onChanged,
            validator: widget.validator != null
                ? (value) => widget.validator!(value ?? '')
                : (value) => _validatePhoneNumber(value ?? ''),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppStyles.bodyMedium.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray500,
              ),
              errorStyle: AppStyles.bodySmall.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.error500,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppTheme.error500),
              ),
              prefixIcon: InkWell(
                onTap: widget.isEnabled != false ? _openCountryPicker : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        'https://flagsapi.com/${_selectedCountry?.flagCode ?? 'SA'}/flat/64.png',
                        width: 24.w,
                        height: 24.w,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: AppTheme.gray200,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Icon(
                              Icons.flag,
                              size: 16.sp,
                              color: AppTheme.gray500,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _selectedCountry?.dialCode ?? '+966',
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray800,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16.sp,
                        color: AppTheme.gray500,
                      ),
                    ],
                  ),
                ),
              ),
              suffixIcon: widget.suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  String? _validatePhoneNumber(String value) {
    if (value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }

    // Remove any spaces, dashes, or other non-digit characters except +
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Get the regex pattern for the selected country
    final regexPattern =
        _selectedCountry?.phoneRegex ?? _countries.first.phoneRegex;
    final regex = RegExp(regexPattern);

    if (!regex.hasMatch(cleanedValue)) {
      return 'رقم الهاتف غير صحيح';
    }

    return null;
  }

  // List of GCC countries with their codes, dial codes, and phone regex patterns
  static final List<Country> _countries = [
    // Saudi Arabia: 9 digits starting with 5 (mobile) or 1 (landline)
    // Format: +966 5XXXXXXXX or +966 1XXXXXXXX
    Country(
      name: 'السعودية',
      code: 'SA',
      dialCode: '+966',
      flagCode: 'SA',
      phoneRegex: r'^(\+966|966|0)?[15]\d{8}$',
    ),
    // UAE: 9 digits starting with 5
    // Format: +971 5XXXXXXXX
    Country(
      name: 'الإمارات العربية المتحدة',
      code: 'AE',
      dialCode: '+971',
      flagCode: 'AE',
      phoneRegex: r'^(\+971|971|0)?[5]\d{8}$',
    ),
    Country.kuwait,
    // Qatar: 8 digits starting with 3, 5, 6, or 7
    // Format: +974 [3,5-7]XXXXXXX
    Country(
      name: 'قطر',
      code: 'QA',
      dialCode: '+974',
      flagCode: 'QA',
      phoneRegex: r'^(\+974|974|0)?[3567]\d{7}$',
    ),
    // Bahrain: 8 digits starting with 3
    // Format: +973 3XXXXXXX
    Country(
      name: 'البحرين',
      code: 'BH',
      dialCode: '+973',
      flagCode: 'BH',
      phoneRegex: r'^(\+973|973|0)?[3]\d{7}$',
    ),
    // Oman: 8 digits starting with 7 or 9
    // Format: +968 [79]XXXXXXX
    Country(
      name: 'عُمان',
      code: 'OM',
      dialCode: '+968',
      flagCode: 'OM',
      phoneRegex: r'^(\+968|968|0)?[79]\d{7}$',
    ),
  ];
}
