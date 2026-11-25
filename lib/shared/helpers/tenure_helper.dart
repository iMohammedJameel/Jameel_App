/// Full years of service completed on [now] (defaults to today).
///
/// Returns `null` when the join date is unknown, in the future, or less than a
/// year ago, so the UI can simply hide the badge instead of showing "0 years".
int? yearsOfService(DateTime? joinDate, {DateTime? now}) {
  if (joinDate == null) return null;
  final today = now ?? DateTime.now();
  var years = today.year - joinDate.year;
  final anniversaryPassed = today.month > joinDate.month ||
      (today.month == joinDate.month && today.day >= joinDate.day);
  if (!anniversaryPassed) years--;
  return years >= 1 ? years : null;
}
