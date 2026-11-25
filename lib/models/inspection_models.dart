class PreTripInspection {
  final bool? fuelOk;
  final bool? airOk;
  final bool? brakesOk;
  final bool? tyresOk;
  final bool? lightsOk;
  final bool? doorsOk;
  final bool? hornOk;
  final bool? mirrorsOk;
  final bool? firstAidOk;
  final bool otherIssuePresent;
  final String? otherIssueDescription;
  final String? otherIssueLocalPhotoPath;
  final String? otherIssuePhotoUrl;
  final String? inspectorNotes;
  final DateTime? inspectedAt;
  final List<VehicleProblemReport> issues;

  const PreTripInspection({
    this.fuelOk,
    this.airOk,
    this.brakesOk,
    this.tyresOk,
    this.lightsOk,
    this.doorsOk,
    this.hornOk,
    this.mirrorsOk,
    this.firstAidOk,
    this.otherIssuePresent = false,
    this.otherIssueDescription,
    this.otherIssueLocalPhotoPath,
    this.otherIssuePhotoUrl,
    this.inspectorNotes,
    this.inspectedAt,
    this.issues = const [],
  });

  /// Factory for empty pending inspection (0 of 7 completed)
  factory PreTripInspection.empty() => const PreTripInspection();

  /// Factory for when all standard items pass and no other issue is reported
  factory PreTripInspection.allPassed({
    String? driverId,
    String? vehicleId,
  }) {
    return PreTripInspection(
      fuelOk: true,
      airOk: true,
      brakesOk: true,
      tyresOk: true,
      lightsOk: true,
      doorsOk: true,
      hornOk: true,
      mirrorsOk: true,
      firstAidOk: true,
      otherIssuePresent: false,
      inspectedAt: DateTime.now(),
      issues: const [],
    );
  }

  /// Total count of the 7 core safety checklist items
  int get totalChecksCount => 7;

  /// Dynamically count how many of the 7 checks have been verified OK
  int get completedChecksCount {
    int count = 0;
    if (brakesOk == true) count++;
    if (tyresOk == true) count++;
    if (lightsOk == true) count++;
    if (doorsOk == true) count++;
    if (hornOk == true) count++;
    if (mirrorsOk == true) count++;
    if (firstAidOk == true) count++;
    return count;
  }

  /// Progress as a decimal fraction between 0.0 and 1.0
  double get progressFraction => totalChecksCount > 0 ? (completedChecksCount / totalChecksCount).clamp(0.0, 1.0) : 0.0;

  /// Whether the driver has started checking items
  bool get isStarted => completedChecksCount > 0;

  /// Have the standard items been reviewed/set by the driver?
  bool get isReviewed =>
      brakesOk != null &&
      tyresOk != null &&
      lightsOk != null &&
      doorsOk != null &&
      hornOk != null &&
      mirrorsOk != null &&
      firstAidOk != null;

  /// Are all 7 core items OK with zero problems and no other issue?
  bool get isAllPassed =>
      brakesOk == true &&
      tyresOk == true &&
      lightsOk == true &&
      (doorsOk ?? true) &&
      (hornOk ?? true) &&
      (mirrorsOk ?? true) &&
      (firstAidOk ?? true) &&
      !otherIssuePresent &&
      issues.isEmpty;

  /// True strictly when all 7 checks are explicitly verified true with no issues
  bool get isFullyCompleted => completedChecksCount == 7 && !hasIssues;

  /// Is there any problem or other issue reported?
  bool get hasIssues =>
      brakesOk == false ||
      tyresOk == false ||
      lightsOk == false ||
      doorsOk == false ||
      hornOk == false ||
      mirrorsOk == false ||
      firstAidOk == false ||
      otherIssuePresent ||
      issues.isNotEmpty;

  bool get hasCriticalIssue => hasIssues;

  /// Human-readable description of the first failing safety item
  String? get failedItemSummary {
    if (brakesOk == false) return 'Brake inspection failed';
    if (tyresOk == false) return 'Tyre inspection failed';
    if (lightsOk == false) return 'Light inspection failed';
    if (doorsOk == false) return 'Door mechanism failed';
    if (hornOk == false) return 'Horn inspection failed';
    if (mirrorsOk == false) return 'Mirror check failed';
    if (firstAidOk == false) return 'First Aid Kit missing';
    if (otherIssuePresent) return otherIssueDescription ?? 'Vehicle issue reported';
    return null;
  }

  PreTripInspection toggleCheck(String key, bool value) {
    switch (key.toLowerCase()) {
      case 'brakes':
        return copyWith(brakesOk: value);
      case 'tyres':
      case 'tires':
        return copyWith(tyresOk: value);
      case 'lights':
        return copyWith(lightsOk: value);
      case 'doors':
        return copyWith(doorsOk: value);
      case 'horn':
        return copyWith(hornOk: value);
      case 'mirrors':
        return copyWith(mirrorsOk: value);
      case 'firstaid':
      case 'firstaidkit':
      case 'first aid':
      case 'first aid kit':
        return copyWith(firstAidOk: value);
      default:
        return this;
    }
  }

  PreTripInspection copyWith({
    bool? fuelOk,
    bool? airOk,
    bool? brakesOk,
    bool? tyresOk,
    bool? lightsOk,
    bool? doorsOk,
    bool? hornOk,
    bool? mirrorsOk,
    bool? firstAidOk,
    bool? otherIssuePresent,
    String? otherIssueDescription,
    String? otherIssueLocalPhotoPath,
    String? otherIssuePhotoUrl,
    String? inspectorNotes,
    DateTime? inspectedAt,
    List<VehicleProblemReport>? issues,
  }) {
    return PreTripInspection(
      fuelOk: fuelOk ?? this.fuelOk,
      airOk: airOk ?? this.airOk,
      brakesOk: brakesOk ?? this.brakesOk,
      tyresOk: tyresOk ?? this.tyresOk,
      lightsOk: lightsOk ?? this.lightsOk,
      doorsOk: doorsOk ?? this.doorsOk,
      hornOk: hornOk ?? this.hornOk,
      mirrorsOk: mirrorsOk ?? this.mirrorsOk,
      firstAidOk: firstAidOk ?? this.firstAidOk,
      otherIssuePresent: otherIssuePresent ?? this.otherIssuePresent,
      otherIssueDescription: otherIssueDescription ?? this.otherIssueDescription,
      otherIssueLocalPhotoPath: otherIssueLocalPhotoPath ?? this.otherIssueLocalPhotoPath,
      otherIssuePhotoUrl: otherIssuePhotoUrl ?? this.otherIssuePhotoUrl,
      inspectorNotes: inspectorNotes ?? this.inspectorNotes,
      inspectedAt: inspectedAt ?? this.inspectedAt,
      issues: issues ?? this.issues,
    );
  }

  Map<String, dynamic> toJson({String? driverId, String? vehicleId}) => {
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'fuel_ok': fuelOk ?? false,
        'air_ok': airOk ?? false,
        'brakes_ok': brakesOk ?? false,
        'tyres_ok': tyresOk ?? false,
        'lights_ok': lightsOk ?? false,
        'doors_ok': doorsOk ?? false,
        'horn_ok': hornOk ?? false,
        'mirrors_ok': mirrorsOk ?? false,
        'first_aid_ok': firstAidOk ?? false,
        'other_issue_present': otherIssuePresent,
        'other_issue_description': otherIssueDescription,
        'other_issue_photo_url': otherIssuePhotoUrl,
        'is_passed': isAllPassed,
        'has_issues': hasIssues,
        'notes': inspectorNotes,
        'created_at': (inspectedAt ?? DateTime.now()).toIso8601String(),
      };
}

class VehicleProblemReport {
  final String id;
  final String problemType;
  final String description;
  final String? localPhotoPath;
  final String? photoUrl;
  final DateTime reportedAt;
  final String status;

  const VehicleProblemReport({
    required this.id,
    required this.problemType,
    required this.description,
    this.localPhotoPath,
    this.photoUrl,
    required this.reportedAt,
    this.status = 'REPORTED',
  });

  Map<String, dynamic> toJson({String? inspectionId, String? driverId, String? vehicleId}) => {
        'id': id,
        'inspection_id': inspectionId,
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'problem_type': problemType,
        'description': description,
        'photo_url': photoUrl,
        'status': status,
        'created_at': reportedAt.toIso8601String(),
      };
}
