import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/app_textfield.dart';
import '../../../viewmodels/car_registration_viewmodel.dart';

// Car Makes List
List<String> carMakes = [
  'Toyota',
  'Honda',
  'Suzuki',
  'Hyundai',
  'Kia',
  'Nissan',
  'BMW',
  'Mercedes-Benz',
  'Audi',
  'Volkswagen',
  'Ford',
  'Chevrolet',
  'Mitsubishi',
  'Mazda',
  'Subaru',
  'Lexus',
  'Tesla',
  'Porsche',
  'Land Rover',
  'Jeep',
];


// Car Models Map (Make → Models)
Map<String, List<String>> carModels = {
  'Toyota': [
    'Corolla',
    'Yaris',
    'Camry',
    'Avalon',
    'Fortuner',
    'Prado',
    'Land Cruiser',
    'Hilux',
    'RAV4',
  ],

  'Honda': [
    'Civic',
    'City',
    'Accord',
    'BR-V',
    'CR-V',
    'HR-V',
    'Fit',
  ],

  'Suzuki': [
    'Alto',
    'Cultus',
    'Wagon R',
    'Swift',
    'Ciaz',
    'Mehran',
    'Bolan',
    'Every',
  ],

  'Hyundai': [
    'Elantra',
    'Sonata',
    'Accent',
    'Tucson',
    'Santa Fe',
    'Palisade',
  ],

  'Kia': [
    'Sportage',
    'Picanto',
    'Stonic',
    'Rio',
    'Sorento',
    'Carnival',
  ],

  'Nissan': [
    'Sunny',
    'Altima',
    'Sentra',
    'X-Trail',
    'Rogue',
    'Patrol',
  ],

  'BMW': [
    '1 Series',
    '3 Series',
    '5 Series',
    '7 Series',
    'X1',
    'X3',
    'X5',
    'X7',
  ],

  'Mercedes-Benz': [
    'A-Class',
    'C-Class',
    'E-Class',
    'S-Class',
    'GLA',
    'GLC',
    'GLE',
    'G-Class',
  ],

  'Audi': [
    'A3',
    'A4',
    'A6',
    'A8',
    'Q3',
    'Q5',
    'Q7',
  ],

  'Volkswagen': [
    'Polo',
    'Golf',
    'Passat',
    'Jetta',
    'Tiguan',
    'Atlas',
  ],

  'Ford': [
    'Fiesta',
    'Focus',
    'Fusion',
    'Mustang',
    'Explorer',
    'Ranger',
    'F-150',
  ],

  'Chevrolet': [
    'Spark',
    'Cruze',
    'Malibu',
    'Camaro',
    'Tahoe',
  ],

  'Mitsubishi': [
    'Mirage',
    'Lancer',
    'Outlander',
    'Pajero',
    'ASX',
  ],

  'Mazda': [
    'Mazda 2',
    'Mazda 3',
    'Mazda 6',
    'CX-3',
    'CX-5',
    'CX-9',
  ],

  'Subaru': [
    'Impreza',
    'Legacy',
    'Forester',
    'Outback',
    'XV',
  ],

  'Lexus': [
    'IS',
    'ES',
    'GS',
    'RX',
    'NX',
    'LX',
  ],

  'Tesla': [
    'Model S',
    'Model 3',
    'Model X',
    'Model Y',
  ],

  'Porsche': [
    '911',
    'Cayenne',
    'Macan',
    'Panamera',
    'Taycan',
  ],

  'Land Rover': [
    'Range Rover',
    'Range Rover Sport',
    'Defender',
    'Discovery',
  ],

  'Jeep': [
    'Wrangler',
    'Cherokee',
    'Grand Cherokee',
    'Compass',
  ],
};

// Car Colors List
List<String> carColors = [
  'Black',
  'White',
  'Silver',
  'Grey',
  'Dark Grey',
  'Red',
  'Maroon',
  'Blue',
  'Navy Blue',
  'Green',
  'Olive',
  'Brown',
  'Beige',
  'Yellow',
  'Orange',
  'Purple',
  'Gold',
];

// Car Years List (1995 → Current Year)
List<String> carYears = List.generate(
  DateTime.now().year - 1885,
  (index) => (DateTime.now().year - index).toString(),
);

class CarRegistrationView extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CarRegistrationView({super.key, this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: CarRegistrationContent(
              onNext: onNext,
              onBack: onBack ?? () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
}

class CarRegistrationContent extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CarRegistrationContent({super.key, this.onNext, this.onBack});

  // Helper method to build dropdown
  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          size: 14.fSize,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        Gap.v(8),
        Theme(
          data: Theme.of(context).copyWith(
            highlightColor: AppColors.primaryBlue,
            splashColor: AppColors.primaryBlue,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.adaptSize),
              color: AppColors.textFieldFillColor,
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.cardBackground,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
              menuMaxHeight: 300,
              decoration: InputDecoration(
                hintText: '$label',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                filled: true,
                fillColor: enabled
                    ? AppColors.textFieldFillColor
                    : AppColors.textFieldFillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.adaptSize),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.adaptSize),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.adaptSize),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.adaptSize),
                  borderSide: BorderSide.none,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              style: TextStyle(
                fontSize: 15,
                color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarRegistrationViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            /// 🔹 CARD
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20.adaptSize),
              ),
              padding: EdgeInsets.all(20.adaptSize),
              child: Column(
                children: [
                  /// Icon
                  Container(
                    height: 60.adaptSize,
                    width: 60.adaptSize,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  Gap.v(20),

                  /// Title
                  AppText(
                    'Car Registration',
                    size: 26.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),

                  Gap.v(8),

                  /// Subtitle
                  AppText(
                    'Enter your vehicle details for \nregistration',
                    size: 14.fSize,
                    align: TextAlign.center,
                    color: AppColors.textSecondary,
                  ),

                  Gap.v(32),

                  /// Plate Number Field
                  ReusableTextField(
                    controller: viewModel.plateNumberController,
                    label: 'Plate Number',
                    hintText: 'eg: AB12CD3456',
                    keyboardType: TextInputType.text,
                    borderRadius: 14.adaptSize,
                    fillColor: AppColors.textFieldFillColor,
                    textColor: AppColors.textPrimary,
                    required: true,
                    validator: (value) {
                      return viewModel.validatePlateNumber(value);
                    },
                    onChanged: (value) {
                      // Clear error message when user starts typing
                      if (viewModel.errorMessage != null && value.isNotEmpty) {
                        viewModel.errorMessage = null;
                      }
                    },
                  ),

                  /// Car Details Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Gap.v(20),

                      /// Row 1: Make & Model
                      Row(
                        children: [
                          /// Make
                          Expanded(
                            child: _buildDropdown(
                              context: context,
                              label: 'Make',
                              value: viewModel.selectedMake,
                              items: carMakes,
                              onChanged: (String? newValue) {
                                viewModel.setMake(newValue);
                              },
                            ),
                          ),

                          Gap.h(16),

                          /// Model
                          Expanded(
                            child: _buildDropdown(
                              context: context,
                              label: 'Model',
                              value: viewModel.selectedModel,
                              items: viewModel.selectedMake != null
                                  ? (carModels[viewModel.selectedMake] ?? [])
                                  : [],
                              onChanged: (String? newValue) {
                                viewModel.setModel(newValue);
                              },
                              enabled: viewModel.selectedMake != null,
                            ),
                          ),
                        ],
                      ),

                      Gap.v(20),

                      /// Row 2: Year & Color
                      Row(
                        children: [
                          /// Year
                          Expanded(
                            child: _buildDropdown(
                              context: context,
                              label: 'Year',
                              value: viewModel.selectedYear,
                              items: carYears,
                              onChanged: (String? newValue) {
                                viewModel.setYear(newValue);
                              },
                            ),
                          ),

                          Gap.h(16),

                          /// Color
                          Expanded(
                            child: _buildDropdown(
                              context: context,
                              label: 'Color',
                              value: viewModel.selectedColor,
                              items: carColors,
                              onChanged: (String? newValue) {
                                viewModel.setColor(newValue);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (viewModel.errorMessage != null) ...[
                    Gap.v(16),
                    AppText(
                      viewModel.errorMessage!,
                      size: 12.fSize,
                      color: AppColors.error,
                    ),
                  ],

                  Gap.v(28),

                  /// Verify Button
                  CustomButton(
                    text: viewModel.isLoading
                        ? 'Registering...'
                        : 'Register Car',
                    onPressed: viewModel.isLoading
                        ? () {}
                        : () {
                            viewModel.saveCarData(
                              onSuccess: () {
                                onNext?.call();
                              },
                              onError: (error) {
                                // Error is already set in viewModel.errorMessage and will be displayed on screen
                              },
                            );
                          },
                    backgroundColor: AppColors.primaryBlue,
                    textColor: AppColors.white,
                    borderRadius: 10.adaptSize,
                    height: 50.v,
                    width: double.infinity,
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.bold,
                    isDisabled: viewModel.isLoading,
                  ),

                  Gap.v(14),

                  /// Back Button
                  CustomButton(
                    text: 'Back to Phone',
                    onPressed: onBack ?? () {},
                    backgroundColor: AppColors.cardBackground,
                    textColor: AppColors.textPrimary,
                    borderRadius: 10.adaptSize,
                    height: 48.v,
                    width: double.infinity,
                    fontSize: 15.fSize,
                    fontWeight: FontWeight.w500,
                    borderColor: AppColors.border,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
