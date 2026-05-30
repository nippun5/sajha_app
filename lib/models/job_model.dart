enum JobType { fullTime, partTime, casual, contract, internship }

extension JobTypeLabel on JobType {
  String get label {
    switch (this) {
      case JobType.fullTime:   return 'Full-time';
      case JobType.partTime:   return 'Part-time';
      case JobType.casual:     return 'Casual';
      case JobType.contract:   return 'Contract';
      case JobType.internship: return 'Internship';
    }
  }
}

class JobModel {
  final String id;
  final String title;
  final String company;
  final String? companyLogoUrl;
  final String location;
  final double? salaryMin;
  final double? salaryMax;
  final String salaryCycle; // 'hourly' | 'weekly' | 'monthly' | 'yearly'
  final JobType jobType;
  final String description;
  final List<String> requirements;
  final DateTime postedAt;
  final DateTime? closingDate;
  final bool isRemote;

  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    this.companyLogoUrl,
    required this.location,
    this.salaryMin,
    this.salaryMax,
    required this.salaryCycle,
    required this.jobType,
    required this.description,
    this.requirements = const [],
    required this.postedAt,
    this.closingDate,
    this.isRemote = false,
  });

  String get salaryDisplay {
    if (salaryMin == null && salaryMax == null) return 'Competitive';
    final suffix = salaryCycle == 'hourly'
        ? '/hr'
        : salaryCycle == 'weekly'
            ? '/wk'
            : salaryCycle == 'monthly'
                ? '/mo'
                : '/yr';
    final prefix = (salaryMin != null && salaryMax != null)
        ? '\$${_fmt(salaryMin!)} – \$${_fmt(salaryMax!)}'
        : salaryMin != null
            ? '\$${_fmt(salaryMin!)}+'
            : 'Up to \$${_fmt(salaryMax!)}';
    return '$prefix$suffix';
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0);

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
        id: json['id'] as String,
        title: json['title'] as String,
        company: json['company'] as String,
        companyLogoUrl: json['company_logo_url'] as String?,
        location: json['location'] as String,
        salaryMin: (json['salary_min'] as num?)?.toDouble(),
        salaryMax: (json['salary_max'] as num?)?.toDouble(),
        salaryCycle: json['salary_cycle'] as String? ?? 'yearly',
        jobType: JobType.values.firstWhere(
          (e) => e.name == json['job_type'],
          orElse: () => JobType.fullTime,
        ),
        description: json['description'] as String,
        requirements: List<String>.from(json['requirements'] ?? []),
        postedAt: DateTime.parse(json['posted_at'] as String),
        closingDate: json['closing_date'] != null
            ? DateTime.parse(json['closing_date'] as String)
            : null,
        isRemote: json['is_remote'] as bool? ?? false,
      );
}