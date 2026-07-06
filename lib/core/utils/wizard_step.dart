/// Base contract shared by multi-step wizard state machines. Each concrete
/// step owns its own position, label and validity check against the wizard's
/// state [S], so views can dispatch on the step type with an exhaustive
/// `switch` instead of comparing a bare `int`.
abstract class WizardStep<S> {
  const WizardStep(this.ordinal, this.label);

  /// 0-based position in the wizard's step list.
  final int ordinal;

  /// Step-indicator label.
  final String label;

  bool isValid(S state) => true;

  String get validationMessage => '';
}
