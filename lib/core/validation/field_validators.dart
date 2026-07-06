/// Composable validation rules for form fields, applied in order via
/// [validateField] (Chain of Responsibility — the first failing rule wins).
abstract class FieldValidator {
  const FieldValidator();

  /// Returns an error message, or null if [value] passes.
  String? validate(String value);
}

class RequiredValidator extends FieldValidator {
  const RequiredValidator([this.message = 'This field is required']);
  final String message;

  @override
  String? validate(String value) => value.trim().isEmpty ? message : null;
}

class MinLengthValidator extends FieldValidator {
  const MinLengthValidator(this.minLength, {this.message});
  final int minLength;
  final String? message;

  @override
  String? validate(String value) =>
      value.length < minLength ? (message ?? 'At least $minLength characters') : null;
}

class EmailFormatValidator extends FieldValidator {
  const EmailFormatValidator([this.message = 'Enter a valid email address']);
  final String message;
  static final RegExp _pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  String? validate(String value) => _pattern.hasMatch(value.trim()) ? null : message;
}

/// Compares against another field's *current* value at validation time (e.g.
/// confirm-password vs. password), so it reads live controller text via
/// [other] rather than a snapshot.
class MatchesValidator extends FieldValidator {
  const MatchesValidator(this.other, {this.message = 'Passwords do not match'});
  final String Function() other;
  final String message;

  @override
  String? validate(String value) => value == other() ? null : message;
}

/// Runs [validators] in order and returns the first non-null error.
String? validateField(String value, List<FieldValidator> validators) {
  for (final validator in validators) {
    final error = validator.validate(value);
    if (error != null) return error;
  }
  return null;
}
