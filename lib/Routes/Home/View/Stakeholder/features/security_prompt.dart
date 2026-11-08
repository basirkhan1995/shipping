import 'package:flutter/material.dart';
import '../View/Security/verify_lock.dart';
import '../model/stk_model.dart';

/// Runs the admin verification flow for a locked stakeholder.
/// Returns `true` when it's safe to proceed (either the stakeholder is
/// not locked, or the user just passed verification).
///
/// If the user cancels, or verification fails, returns `false` and the
/// caller should abort.
Future<bool> ensureStakeholderUnlocked(
    BuildContext context, {
      required StakeholdersModel stakeholder,
    }) async {
  if (!stakeholder.isLocked) return true;
  final perID = stakeholder.perId;
  if (perID == null) return true;

  return LockVerifyDialog.show(
    context,
    perID: perID,
    stakeholderName: stakeholder.fullName,
    mode: LockVerifyMode.verifyOnly,
  );
}