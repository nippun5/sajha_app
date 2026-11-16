import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/job_model.dart';

class JobDetailPage extends StatelessWidget {
  final JobModel job;

  const JobDetailPage({
    super.key,
    required this.job,
  });

  Future<void> _callEmployer() async {
    final Uri uri = Uri(
      scheme: 'tel',
      path: job.employerPhone,
    );

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Job Details'),
      ),

       bottomNavigationBar: SafeArea(
        child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: Color(0xFFEAEAEA)),
          ),
        ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Firebase chat later
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                ),
          
                const SizedBox(width: 12),
          
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:(){ 
                      _callEmployer();
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Company Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        job.company[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            job.location,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.payments),
                  const SizedBox(width: 8),
                  Text(job.salaryDisplay),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.work),
                  const SizedBox(width: 8),
                  Text(job.jobType.label),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.home_work),
                  const SizedBox(width: 8),
                  Text(
                    job.isRemote
                        ? 'Remote Available'
                        : 'On-site',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Job Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(job.description),

              const SizedBox(height: 24),

              const Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              ...job.requirements.map(
                (req) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(req)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Employer Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text('Name: ${job.employerName}'),
              Text('Phone: ${job.employerPhone}'),

              const SizedBox(height: 24),

              Text(
                'Posted ${DateFormat.yMMMd().format(job.postedAt)}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}