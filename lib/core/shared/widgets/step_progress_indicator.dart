import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../shared/app_text.dart';
import '../../utils/size_utils.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step circles with connectors
        SizedBox(
          height: 32.v, // Fixed height for alignment
          child: Row(
            children: [
              // First step with special handling
              _buildStepCircle(0),

              // Connector + Step 2
              Expanded(
                child: Row(children: [_buildConnector(0), _buildStepCircle(1)]),
              ),

              // Connector + Step 3
              Expanded(
                child: Row(children: [_buildConnector(1), _buildStepCircle(2)]),
              ),

              // Connector + Step 4
              Expanded(
                child: Row(children: [_buildConnector(2), _buildStepCircle(3)]),
              ),
            ],
          ),
        ),

        // Labels below steps with precise alignment
        if (stepLabels != null && stepLabels!.length == totalSteps) ...[
          Gap.v(8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.h,
            ), // Adjust for alignment
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // First label - left aligned
                SizedBox(
                  width: 56.h, // Fixed width for alignment
                  child: AppText(
                    stepLabels![0],
                    size: 12.fSize,
                    color:
                        currentStep >= 0
                            ? AppColors.progressActive
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    align: TextAlign.center,
                  ),
                ),

                // Second label
                SizedBox(
                  width: 56.h,
                  child: AppText(
                    stepLabels![1],
                    size: 12.fSize,
                    color:
                        currentStep >= 1
                            ? AppColors.progressActive
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    align: TextAlign.center,
                  ),
                ),

                // Third label
                SizedBox(
                  width: 56.h,
                  child: AppText(
                    stepLabels![2],
                    size: 12.fSize,
                    color:
                        currentStep >= 2
                            ? AppColors.progressActive
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    align: TextAlign.center,
                  ),
                ),

                // Fourth label - right aligned
                SizedBox(
                  width: 56.h,
                  child: AppText(
                    stepLabels![3],
                    size: 12.fSize,
                    color:
                        currentStep >= 3
                            ? AppColors.progressActive
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    align: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepCircle(int index) {
    bool isCompleted = index < currentStep;
    bool isCurrent = index == currentStep;
    bool isInactive = index > currentStep;

    Color circleColor =
        isCompleted
            ? AppColors.success
            : isCurrent
            ? AppColors.progressActive
            : AppColors.progressInactive;

    return Container(
      width: 28.adaptSize,
      height: 28.adaptSize,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        border:
            isInactive ? Border.all(color: AppColors.border, width: 1.5) : null,
      ),
      child: Center(
        child:
            isCompleted
                ? Icon(Icons.check, size: 16.fSize, color: AppColors.white)
                : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color:
                        isInactive ? AppColors.textSecondary : AppColors.white,
                    fontSize: 12.fSize,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
      ),
    );
  }

  Widget _buildConnector(int index) {
    bool isCompleted = index < currentStep;

    return Expanded(
      child: Container(
        height: 2.adaptSize,
        margin: EdgeInsets.only(right: 8.h, left: 8.h),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.success : AppColors.progressInactive,
          borderRadius: BorderRadius.circular(1.adaptSize),
        ),
      ),
    );
  }
}
