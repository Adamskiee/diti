import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../providers/history_providers.dart';

class SessionVerificationSheet extends ConsumerStatefulWidget {
  const SessionVerificationSheet({super.key});

  @override
  ConsumerState<SessionVerificationSheet> createState() =>
      _SessionVerificationSheetState();
}

class _SessionVerificationSheetState
    extends ConsumerState<SessionVerificationSheet> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(sessionVerificationControllerProvider);
    _titleController = TextEditingController(text: draft.draftRoutineName);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionVerificationControllerProvider);
    final controller = ref.read(sessionVerificationControllerProvider.notifier);
    final theme = Theme.of(context);

    final isCompleted =
        state.candidateSession?.outcome == SessionOutcome.completed;
    final outcomeColor =
        isCompleted ? theme.colorScheme.primary : Colors.orange;
    final outcomeLabel = isCompleted ? 'Completed' : 'Cancelled';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Verify Focus Session',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    avatar: Icon(
                      isCompleted ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: outcomeColor,
                    ),
                    label: Text(
                      outcomeLabel,
                      style: TextStyle(
                        color: outcomeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: outcomeColor.withAlpha(30),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Activity Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Activity / Routine Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
                onChanged: controller.setRoutineName,
              ),
              const SizedBox(height: 20),

              // Duration Display & Quick Adjustment
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Focus Time',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DurationFormatter.formatMs(state.draftDurationMs),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ActionChip(
                            label: const Text('-5m'),
                            onPressed: () => controller
                                .adjustDuration(const Duration(minutes: -5)),
                          ),
                          ActionChip(
                            label: const Text('-1m'),
                            onPressed: () => controller
                                .adjustDuration(const Duration(minutes: -1)),
                          ),
                          ActionChip(
                            label: const Text('+1m'),
                            onPressed: () => controller
                                .adjustDuration(const Duration(minutes: 1)),
                          ),
                          ActionChip(
                            label: const Text('+5m'),
                            onPressed: () => controller
                                .adjustDuration(const Duration(minutes: 5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Validation Error Banner
              if (state.validationError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.validationError!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: state.isSaving
                          ? null
                          : () async {
                              final shouldDiscard = state.draftDurationMs >
                                      300000 // > 5 mins
                                  ? await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Discard Session?'),
                                          content: const Text(
                                            'This session will not be saved to your history or analytics.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Keep Editing'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                'Discard',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false
                                  : true;

                              if (shouldDiscard) {
                                await controller.discard();
                                if (context.mounted) {
                                  Navigator.of(context).maybePop();
                                }
                              }
                            },
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        state.isSaving ? 'Saving...' : 'Save to Analytics',
                      ),
                      onPressed: state.isSaving
                          ? null
                          : () async {
                              final success = await controller.confirmSave();
                              if (success && context.mounted) {
                                Navigator.of(context).maybePop();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
