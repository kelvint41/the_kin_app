/// Client-side checks for the auth forms.
///
/// Both the sign-in and sign-up pages shipped with FlutterFlow's validator
/// hooks declared but never assigned (`emailFieldTextControllerValidator`
/// is null, so `asValidator` returns nothing) and with no `Form`/`formKey`
/// to call `validate()` against. The net effect was that submitting an
/// empty form went straight to Firebase, which answered with its own raw
/// error - "The password is invalid or the user does not have a password" -
/// on a form where the email was the empty field. That names the wrong
/// input and reads like an internal fault rather than something the person
/// can act on.
///
/// Kept as a plain function rather than added to KinServices: that class is
/// a wrapper around Firebase-backed button actions, and none of this
/// touches the network.
library;

// Deliberately permissive. The only job here is to catch input that cannot
// possibly be an address before spending a network round trip on it -
// anything stricter starts rejecting valid addresses, and the authoritative
// check is Firebase's own either way.
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Returns the first problem with these credentials as a sentence to show
/// the user, or null when the input is worth sending to Firebase.
///
/// Pass [name] only on sign-up, where a display name is collected. Pass
/// [minPasswordLength] as 6 on sign-up to match Firebase's own minimum, so
/// a too-short password is caught here with a clear message instead of
/// coming back as a server error after the round trip. Sign-in leaves it at
/// 1: an existing account's password only has to be non-empty to be worth
/// checking, and second-guessing its length would be wrong for anyone whose
/// password predates a rule change.
String? authFormError({
  String? name,
  required String email,
  required String password,
  int minPasswordLength = 1,
}) {
  if (name != null && name.trim().isEmpty) {
    return 'Enter your name.';
  }
  final trimmedEmail = email.trim();
  if (trimmedEmail.isEmpty) {
    return 'Enter your email address.';
  }
  if (!_emailPattern.hasMatch(trimmedEmail)) {
    return "That email address doesn't look right.";
  }
  if (password.isEmpty) {
    return 'Enter your password.';
  }
  if (password.length < minPasswordLength) {
    return 'Your password needs at least $minPasswordLength characters.';
  }
  return null;
}
