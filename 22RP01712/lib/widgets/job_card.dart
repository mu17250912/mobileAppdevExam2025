import 'package:flutter/material.dart';
import '../models/job.dart';
import '../styles/app_styles.dart';

class JobCard extends StatelessWidget {
  final Job job;
  const JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final deadline = DateTime.parse(job.deadline);
    final isExpired = deadline.isBefore(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Title and Company
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: AppStyles.heading5.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppStyles.verticalSpaceS,
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 16,
                          color: AppStyles.textTertiary,
                        ),
                        AppStyles.horizontalSpaceS,
                        Expanded(
                          child: Text(
                            job.company,
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppStyles.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacingS,
                  vertical: AppStyles.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  border: Border.all(
                    color: AppStyles.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  job.jobType,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppStyles.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          AppStyles.verticalSpaceM,
          
          // Job Details
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppStyles.textTertiary,
                    ),
                    AppStyles.horizontalSpaceS,
                    Expanded(
                      child: Text(
                        job.location,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppStyles.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              AppStyles.horizontalSpaceM,
              Row(
                children: [
                  Icon(
                    Icons.attach_money_outlined,
                    size: 16,
                    color: AppStyles.textTertiary,
                  ),
                  AppStyles.horizontalSpaceS,
                  Text(
                    job.salary,
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppStyles.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          AppStyles.verticalSpaceS,
          
          // Experience Level
          Row(
            children: [
              Icon(
                Icons.work_outline,
                size: 16,
                color: AppStyles.textTertiary,
              ),
              AppStyles.horizontalSpaceS,
              Text(
                job.experienceLevel,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppStyles.textTertiary,
                ),
              ),
            ],
          ),
          
          AppStyles.verticalSpaceM,
          
          // Description Preview
          Text(
            job.description,
            style: AppStyles.bodyMedium.copyWith(
              color: AppStyles.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          AppStyles.verticalSpaceM,
          
          // Deadline and View Details
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: isExpired ? AppStyles.errorColor : AppStyles.warningColor,
                    ),
                    AppStyles.horizontalSpaceS,
                    Text(
                      'Deadline: ${deadline.toLocal().toString().split(' ')[0]}',
                      style: AppStyles.bodySmall.copyWith(
                        color: isExpired ? AppStyles.errorColor : AppStyles.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isExpired) ...[
                      AppStyles.horizontalSpaceS,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacingXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppStyles.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radiusS),
                        ),
                        child: Text(
                          'EXPIRED',
                          style: AppStyles.caption.copyWith(
                            color: AppStyles.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    'View Details',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppStyles.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppStyles.horizontalSpaceS,
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppStyles.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
} 