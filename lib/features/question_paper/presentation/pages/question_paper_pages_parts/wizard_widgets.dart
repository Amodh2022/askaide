part of '../question_paper_pages.dart';

// ---- Wizard helper widgets --------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.steps, required this.onTap});
  final int current;
  final List<String> steps;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: context.cardDecoration(),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: () => onTap(i + 1),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: current == i + 1 ? c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (i + 1) < current ? LucideIcons.circleCheck : LucideIcons.circle,
                        size: 16,
                        color: current == i + 1
                            ? Colors.white
                            : ((i + 1) < current ? c.success : c.textMuted),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          steps[i],
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(
                              current == i + 1 ? Colors.white : c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 18, color: c.accent),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.h3(c.textPrimary)),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.trailing});
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TextInput extends StatefulWidget {
  const _TextInput({required this.value, required this.hint, required this.onChanged});
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _TextInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) _ctrl.text = widget.value;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: _ctrl,
      style: AppTypography.bodyLarge(c.textPrimary),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTypography.bodyMedium(c.textMuted),
        filled: true,
        fillColor: c.bgRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.minus, size: 16),
            onPressed: value - step >= min ? () => onChanged(value - step) : null,
          ),
          SizedBox(
            width: 44,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge(c.textPrimary)),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 16),
            onPressed: value + step <= max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

class _DifficultyCounter extends StatelessWidget {
  const _DifficultyCounter({
    required this.label,
    required this.marks,
    required this.color,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String marks;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.bodyMedium(c.textPrimary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: Icon(LucideIcons.minus, size: 14, color: c.textMuted),
              ),
              SizedBox(
                width: 32,
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge(c.textPrimary)),
              ),
              InkWell(
                onTap: () => onChanged(value + 1),
                child: Icon(LucideIcons.plus, size: 14, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(marks, style: AppTypography.bodySmall(c.textMuted)),
        ],
      ),
    );
  }
}

class _InstructionAdder extends StatefulWidget {
  const _InstructionAdder({required this.onAdd});
  final ValueChanged<String> onAdd;
  @override
  State<_InstructionAdder> createState() => _InstructionAdderState();
}

class _InstructionAdderState extends State<_InstructionAdder> {
  final _ctrl = TextEditingController();

  void _add() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onAdd(_ctrl.text);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: AppTypography.bodyLarge(c.textPrimary),
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText: 'e.g. Use blue/black ink pen only',
              hintStyle: AppTypography.bodyMedium(c.textMuted),
              filled: true,
              fillColor: c.bgRaised,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _add,
          style: FilledButton.styleFrom(
              backgroundColor: c.accent, foregroundColor: Colors.white),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Pill-shaped chip button — accent-filled when selected, outlined otherwise.
class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.bgRaised,
          border: Border.all(color: selected ? c.accent : c.border),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(selected ? Colors.white : c.textPrimary),
        ),
      ),
    );
  }
}
