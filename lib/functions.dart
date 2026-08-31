String getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first[0].toUpperCase();

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${d.day} ${months[d.month - 1]} ${d.year}, ';
}

/// Parses a timestamp coming from the backend and returns it in local time.
///
/// The backend sends UTC, but without a `Z`/offset suffix. `DateTime.parse`
/// treats such a string as local time, which makes `.toLocal()` a no-op, so we
/// tag it as UTC ourselves before converting.
DateTime parseServerDate(String? raw) {
  if (raw == null || raw.isEmpty) return DateTime.now();

  final value = raw.trim().replaceFirst(' ', 'T');
  final hasZone = value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);

  return DateTime.parse(hasZone ? value : '${value}Z').toLocal();
}

String getSpecialtyName(String specialty) {
  switch (specialty) {
    case "general_medicine":
      return "General Medicine";
    case "gynecology":
      return "Women's Health";
    case "psychotherapy":
      return "Mental Health";
    default:
      return specialty;
  }
}

String getDiagnosisStatus(String status) {
  const statuses = {
    "diagnosis": "Diagnosed",
    "questionnaire": "In Progress",
    "finalized": "Finalized",
    "prescription": "Prescribed",
  };

  return statuses[status] ?? status;
}

String formatKey(String key) {
  return key
      .replaceAll("_", " ")
      .split(" ")
      .map(
        (e) => e.isEmpty
        ? e
        : "${e[0].toUpperCase()}${e.substring(1).toLowerCase()}",
  )
      .join(" ");
}