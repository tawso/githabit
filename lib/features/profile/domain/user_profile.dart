enum ProfileCardStyle { obsidian, liquidSunset }

class UserProfile {
  final String name;
  final String role;
  final String company;
  final ProfileCardStyle style;
  final bool isAvailableForHire;

  const UserProfile({
    this.name = 'Developer',
    this.role = 'Software Engineer',
    this.company = 'Personal Workspace',
    this.style = ProfileCardStyle.obsidian,
    this.isAvailableForHire = true,
  });

  UserProfile copyWith({
    String? name,
    String? role,
    String? company,
    ProfileCardStyle? style,
    bool? isAvailableForHire,
  }) {
    return UserProfile(
      name: name ?? this.name,
      role: role ?? this.role,
      company: company ?? this.company,
      style: style ?? this.style,
      isAvailableForHire: isAvailableForHire ?? this.isAvailableForHire,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'company': company,
        'style': style.name,
        'isAvailableForHire': isAvailableForHire,
      };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    final rawName = map['name'] as String?;
    final rawRole = map['role'] as String?;
    final rawCompany = map['company'] as String?;

    return UserProfile(
      name: (rawName == null || rawName == 'Alex Turner') ? 'Developer' : rawName,
      role: (rawRole == null || rawRole == 'Lead Mobile Architect')
          ? 'Software Engineer'
          : rawRole,
      company: (rawCompany == null || rawCompany == 'GitHabit Pro')
          ? 'Personal Workspace'
          : rawCompany,
      style: map['style'] == 'liquidSunset'
          ? ProfileCardStyle.liquidSunset
          : ProfileCardStyle.obsidian,
      isAvailableForHire: (map['isAvailableForHire'] as bool?) ?? true,
    );
  }
}

