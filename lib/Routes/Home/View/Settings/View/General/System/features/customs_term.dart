import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../../l10n/app_localizations.dart';
import '../../../../Visibility/bloc/settings_visible_bloc.dart';

/// Inline editor for the invoice Terms & Conditions text.
///
/// • Saves via debounce (600 ms) to SharedPreferences through the bloc.
/// • Empty text is sent as `''` → bloc stores `null` → invoice falls back
///   to the translated defaults.
/// • A clear (×) button appears only when the field has text.
class CustomTermsEditor extends StatefulWidget {
  /// When true, the editor is visually greyed out (but still functional).
  /// Use this to reflect the parent `termsAndConditions` toggle.
  final bool enabled;

  const CustomTermsEditor({super.key, this.enabled = true});

  @override
  State<CustomTermsEditor> createState() => _CustomTermsEditorState();
}

class _CustomTermsEditorState extends State<CustomTermsEditor> {
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initial =
        context.read<SettingsVisibleBloc>().state.customTermsAndConditions;
    _ctrl = TextEditingController(text: initial ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      context.read<SettingsVisibleBloc>().add(
        UpdateSettingsEvent(customTermsAndConditions: value),
      );
    });
  }

  /// Clears the field and immediately persists the empty value.
  void _clear() {
    _debounce?.cancel();
    _ctrl.clear();
    // Keep focus so the user can keep typing after clearing.
    _focusNode.requestFocus();
    context.read<SettingsVisibleBloc>().add(
      const UpdateSettingsEvent(customTermsAndConditions: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<SettingsVisibleBloc, SettingsVisibilityState>(
      buildWhen: (prev, curr) =>
      prev.customTermsAndConditions != curr.customTermsAndConditions ||
          prev.termsAndConditions != curr.termsAndConditions,
      builder: (context, state) {
        // Sync controller when state changes externally (reset, load, etc.).
        final stateText = state.customTermsAndConditions ?? '';
        if (_ctrl.text != stateText && !_focusNode.hasFocus) {
          _ctrl.text = stateText;
        }

        return Padding(
          padding: const EdgeInsets.only(left: 32, right: 8, top: 6, bottom: 6),
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.55,
            duration: const Duration(milliseconds: 150),
            // Listen to the controller so the suffix reflects emptiness live.
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _ctrl,
              builder: (context, value, _) {
                final hasText = value.text.isNotEmpty;

                return TextFormField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 1000,
                  enabled: widget.enabled,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: tr.textTermsAndConditionsHint,
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

                    // ── Clear button (only when there is text) ──
                    suffixIcon: hasText && widget.enabled
                        ? Align(
                      alignment: Alignment.topRight,
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 4),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _clear,
                            child: Tooltip(
                              message: tr.clearFilters, // or add a `clear` key
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                        : null,

                    // Counter only when there is text — keeps empty field clean.
                    counterText: hasText ? null : '',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide:
                      BorderSide(color: scheme.primary, width: 1.2),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}