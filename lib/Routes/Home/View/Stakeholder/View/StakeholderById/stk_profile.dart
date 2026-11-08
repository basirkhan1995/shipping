import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Features/Widgets/znavigator.dart';
import 'package:shipping/Routes/Home/View/Report/AccountStatement/acc_statement.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/bloc/stakeholder_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/stk_form.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../Features/Other/image_helper.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../Transactions/View/CashWD/cash_wd.dart';
import '../../../Transactions/View/Exchange/exchange.dart';
import '../../../Transactions/View/FundTransfer/fund_transfer.dart';
import '../../model/stk_model.dart';
import '../StkAccount/bloc/stk_accounts_bloc.dart';
import '../StkAccount/bloc/stk_accounts_event.dart';
import '../StkAccount/bloc/stk_accounts_state.dart';
import '../StkAccount/stk_acc_form.dart';
import 'bloc/stakeholder_by_id_bloc.dart';
import 'bloc/stakeholder_by_id_event.dart';
import 'bloc/stakeholder_by_id_state.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/View/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../View/Security/bloc/stk_security_bloc.dart';

// ═══════════════════════════════════════════════════════════════════
// Entry point
// ═══════════════════════════════════════════════════════════════════
class StakeholderByIdView extends StatelessWidget {
  final StakeholdersModel ind;

  /// Optional hint — if `true`, the caller already verified at the
  /// moment of navigation. The actual lock state is re-evaluated live
  /// against `StkSecurityBloc`, so this is only a starting point.
  final bool verified;

  const StakeholderByIdView({
    super.key,
    required this.ind,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _StakeholderByIdMobile(ind: ind, verified: verified),
      tablet: _StakeholderByIdDesktop(ind: ind, verified: verified),
      desktop: _StakeholderByIdDesktop(ind: ind, verified: verified),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _StakeholderByIdMobile extends StatelessWidget {
  final StakeholdersModel ind;
  final bool verified;
  const _StakeholderByIdMobile({required this.ind, required this.verified});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Overview')),
      body: const Center(child: Placeholder()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP / TABLET
// ═══════════════════════════════════════════════════════════════════
class _StakeholderByIdDesktop extends StatefulWidget {
  final StakeholdersModel ind;
  final bool verified;
  const _StakeholderByIdDesktop({required this.ind, required this.verified});

  @override
  State<_StakeholderByIdDesktop> createState() =>
      _StakeholderByIdDesktopState();
}

class _StakeholderByIdDesktopState extends State<_StakeholderByIdDesktop> {
  StakeholdersModel? individual;
  String? fullName;

  bool _listNeedsRefresh = false;

  /// Re-checks the security bloc every 15s. Needed because the bloc's
  /// own TTL timer can be paused while the app is in the background,
  /// and we want to re-lock the moment we notice the expiry.
  Timer? _recheckTimer;

  static const Duration _recheckEvery = Duration(seconds: 15);

  static Widget _buildHeroShuttle(
      BuildContext flightContext,
      Animation<double> animation,
      HeroFlightDirection direction,
      BuildContext fromHeroContext,
      BuildContext toHeroContext,
      ) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: (toHeroContext.widget as Hero).child,
      ),
    );
  }

  int? get _stkId => widget.ind.perId;

  // ── Balances visibility (live) ────────────────────────────────
  bool get _canSeeBalances {
    // Not locked → always visible.
    if (!widget.ind.isLocked) return true;
    // Locked → visible only while the security bloc says this perID
    // is currently verified and not expired.
    final id = _stkId;
    if (id == null) return false;
    return context.read<StkSecurityBloc>().isUnlockedFor(id);
  }

  String _fmtMoney(num? v, {String? ccy}) {
    if (v == null) return '—';
    if (!_canSeeBalances) {
      return ccy == null || ccy.isEmpty ? '••••••' : '•••••• $ccy';
    }
    final s = v.toDouble().toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    final formatted = '$intPart.${parts[1]}';
    return ccy == null || ccy.isEmpty ? formatted : '$formatted $ccy';
  }

  // ── Exchange dialog ───────────────────────────────────────────
  Future<void> _openExchangeDialog() async {
    final usrName = _loginName();
    if (usrName == null) return;

    final saved = await showExchangeDialog(
      context,
      usrName: usrName,
      baseCurrency: _baseCurrency(),
    );

    if (!mounted) return;
    if (saved == true) {
      _listNeedsRefresh = true;
      _reloadProfile();
      final tr = AppLocalizations.of(context)!;
      ToastManager.show(
        context: context,
        title: tr.save,
        message: tr.exchange,
        type: ToastType.success,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    individual = widget.ind;
    fullName = _composeName(widget.ind);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_stkId != null) {
        context.read<StkAccountsBloc>().add(
          LoadStkAccountsEvent(perId: _stkId!),
        );
        context.read<StakeholderByIdBloc>().add(
          LoadStakeholderByIdEvent(stkId: _stkId!),
        );
      }
    });

    // Periodic security recheck — catches "verified expired while the
    // app was backgrounded" that the bloc's own Timer might miss.
    _recheckTimer = Timer.periodic(_recheckEvery, (_) => _recheckSecurity());
  }

  @override
  void dispose() {
    _recheckTimer?.cancel();
    super.dispose();
  }

  void _recheckSecurity() {
    if (!mounted) return;
    final id = _stkId;
    if (id == null) return;

    final sec = context.read<StkSecurityBloc>();
    final s = sec.state;

    // The bloc thinks we're verified, but the TTL has expired (e.g.
    // device slept through the timer). Ask the bloc to relock.
    if (s is StkSecurityVerified && !sec.isUnlockedFor(id)) {
      sec.add(RelockEvent(id));
    }
  }

  String _composeName(StakeholdersModel m) {
    final first = m.perName ?? '';
    final last = m.perLastName ?? '';
    final combined = '$first $last'.trim();
    return combined.isEmpty ? '—' : combined;
  }

  void _reloadProfile() {
    if (_stkId != null) {
      context.read<StakeholderByIdBloc>().add(
        LoadStakeholderByIdEvent(stkId: _stkId!),
      );
    }
  }

  void _showError(String title, Object? error) {
    if (!mounted) return;
    final message = error?.toString() ?? 'Unknown error';
    ToastManager.show(
      context: context,
      title: title,
      message: message,
      type: ToastType.error,
    );
  }

  String? _loginName() {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthenticatedState ? auth.loginData.usrName : null;
  }

  String _baseCurrency() {
    final state = context.read<CompanyProfileBloc>().state;
    if (state is CompanyProfileLoadedState) {
      return state.company.comLocalCcy ?? '';
    }
    return '';
  }

  CashTxnSpec _cashSpecFor(BuildContext context, String code) {
    final tr = AppLocalizations.of(context)!;
    switch (code) {
      case 'CHDP':
        return CashTxnSpec(
          typeCode: 'CHDP',
          icon: Icons.arrow_downward_rounded,
          title: (_) => tr.cashDeposit,
          accountInclude: '8',
          allowReminder: true,
          perId: _stkId,
        );
      case 'CHWL':
        return CashTxnSpec(
          typeCode: 'CHWL',
          icon: Icons.arrow_upward_rounded,
          title: (_) => tr.cashWithdraw,
          accountInclude: '8',
          allowReminder: true,
          perId: _stkId,
        );
      default:
        throw ArgumentError('Unsupported cash type: $code');
    }
  }

  Future<void> _openCashDialog(String code) async {
    final usrName = _loginName();
    if (usrName == null) return;

    final saved = await showCashTxnDialog(
      context,
      spec: _cashSpecFor(context, code),
      usrName: usrName,
      baseCurrency: _baseCurrency(),
    );

    if (!mounted) return;
    if (saved == true) {
      _listNeedsRefresh = true;
      _reloadProfile();
      final tr = AppLocalizations.of(context)!;
      ToastManager.show(
        context: context,
        title: tr.save,
        message: code == 'CHDP' ? tr.cashDeposit : tr.cashWithdraw,
        type: ToastType.success,
      );
    }
  }

  Future<void> _openFundTransferDialog() async {
    final usrName = _loginName();
    if (usrName == null) return;

    final saved = await showFundTransferDialog(
      context,
      usrName: usrName,
      baseCurrency: _baseCurrency(),
    );

    if (!mounted) return;
    if (saved == true) {
      _listNeedsRefresh = true;
      _reloadProfile();
      final tr = AppLocalizations.of(context)!;
      ToastManager.show(
        context: context,
        title: tr.save,
        message: tr.fundTransfer,
        type: ToastType.success,
      );
    }
  }

  Future<void> _onEditProfile(StakeholdersModel data) async {
    if (data.perId == null) {
      _showError('Edit profile', 'perId is null');
      return;
    }
    try {
      final updated = await showDialog<StakeholdersModel>(
        context: context,
        builder: (_) => StakeholderFormDialog(existing: data),
      );
      if (updated == null || !mounted) return;
      context.read<StakeholderBloc>().add(UpdateStakeholderEvent(updated));
      _reloadProfile();
    } catch (e) {
      _showError('Edit profile', e);
    }
  }

  Future<void> _onAddAccount() async {
    if (_stkId == null) {
      _showError('Add account', 'perId is null');
      return;
    }
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => StkAccountFormDialog(perId: _stkId!),
      );
      if (!mounted) return;
      _listNeedsRefresh = true;
      context.read<StkAccountsBloc>().add(LoadStkAccountsEvent(perId: _stkId!));
    } catch (e) {
      _showError('Add account', e);
    }
  }

  Future<void> _onEditAccount(StkAccountModel account) async {
    if (account.accNumber == null) {
      _showError('Edit account', 'accNumber is null');
      return;
    }
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => StkAccountFormDialog(perId: _stkId!, account: account),
      );
      if (!mounted) return;
      _listNeedsRefresh = true;
    } catch (e) {
      _showError('Edit account', e);
    }
  }

  Future<void> _onStatement(StkAccountModel account) async {
    if (account.accNumber == null) {
      _showError('Statement', 'accNumber is null');
      return;
    }
    ZNavigator.goto(
      context: context,
      AccountStatementView(initialAccountNumber: account.accNumber),
    );
  }

  Future<void> _onDeleteAccount(StkAccountModel account) async {
    if (account.accNumber == null) {
      _showError('Delete account', 'accNumber is null');
      return;
    }
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete account'),
          content: Text(
            'Delete "${account.accName ?? account.accNumber}"? '
                'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok == true && mounted) {
        _listNeedsRefresh = true;
        context.read<StkAccountsBloc>().add(
          DeleteStkAccountEvent(_stkId!, account.accNumber!),
        );
      }
    } catch (e) {
      _showError('Delete account', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_listNeedsRefresh);
      },
      child: BlocListener<StkSecurityBloc, StkSecurityState>(
        // Whenever the security state leaves "verified" (expiry,
        // manual relock, error) — rebuild so balances re-mask.
        listenWhen: (prev, curr) =>
        curr is StkSecurityInitial || curr is StkSecurityDenied,
        listener: (context, _) {
          if (mounted) setState(() {});
        },
        child: Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            elevation: 0,
            title: Text(tr.profileOverview),
            actions: [
              _AppBarAction(
                icon: Icons.arrow_downward_rounded,
                tooltip: tr.cashDeposit,
                label: tr.cashDeposit,
                onPressed: () => _openCashDialog('CHDP'),
              ),
              _AppBarAction(
                icon: Icons.arrow_upward_rounded,
                tooltip: tr.cashWithdraw,
                label: tr.cashWithdraw,
                onPressed: () => _openCashDialog('CHWL'),
              ),
              _AppBarAction(
                icon: Icons.swap_horiz_rounded,
                tooltip: tr.fundTransfer,
                label: tr.fundTransfer,
                onPressed: _openFundTransferDialog,
              ),
              _AppBarAction(
                icon: Icons.swap_horiz_rounded,
                tooltip: tr.exchange,
                label: tr.exchange,
                onPressed: _openExchangeDialog,
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: ZOutlineButton(
                  onPressed: _onAddAccount,
                  height: 36,
                  icon: Icons.add,
                  isActive: true,
                  label: Text(tr.addAccount.toUpperCase()),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: BlocListener<StakeholderBloc, StakeholderState>(
            listenWhen: (p, c) =>
            c is UpdateStakeholderSuccessState ||
                c is UpdateStakeholderFailureState,
            listener: (context, state) {
              if (state is UpdateStakeholderSuccessState) {
                _listNeedsRefresh = true;
                _reloadProfile();
              } else if (state is UpdateStakeholderFailureState) {
                ToastManager.show(
                  context: context,
                  title: tr.failed,
                  message: 'Update failed: ${state.message}',
                  type: ToastType.error,
                );
              }
            },
            child: BlocListener<StkAccountsBloc, StkAccountsState>(
              listenWhen: (p, c) =>
              (c is StkAccountsLoadedState &&
                  c.successMessage != null) ||
                  (c is StkAccountsFailureState && c.errorMessage != null),
              listener: (context, state) {
                if (state is StkAccountsLoadedState &&
                    state.successMessage != null) {
                  _listNeedsRefresh = true;
                  _reloadProfile();
                  ToastManager.show(
                    context: context,
                    title: tr.successTitle,
                    message: '${state.successMessage}',
                    type: ToastType.success,
                  );
                } else if (state is StkAccountsFailureState) {
                  ToastManager.show(
                    context: context,
                    title: tr.failed,
                    message: '${state.errorMessage}',
                    type: ToastType.error,
                  );
                }
                context.read<StkAccountsBloc>().add(
                  const ClearStkAccountMessagesEvent(),
                );
              },
              child: BlocBuilder<StakeholderByIdBloc, StakeholderByIdState>(
                builder: (context, state) {
                  if (state is StakeholderByIdLoadedState) {
                    individual = state.stk;
                    fullName = _composeName(state.stk);
                  }

                  final data = individual ?? widget.ind;
                  final accounts = data.accounts;
                  final recent = data.recentTransactions;

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                            child: _buildProfileContent(context, color, data),
                          ),
                        ),
                        Container(
                          width: 1,
                          color: color.outlineVariant.withValues(alpha: 0.5),
                        ),
                        Expanded(
                          flex: 8,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!_canSeeBalances)
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        0, 8, 0, 4),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                      color.error.withValues(alpha: .08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: color.error
                                            .withValues(alpha: .3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock,
                                            size: 16, color: color.error),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tr.lockedBalancesNotice,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: color.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(
                                  height: 250,
                                  child: _AccountsSection(
                                    accounts: accounts,
                                    ownerName: fullName ?? '—',
                                    isLoading:
                                    state is StakeholderByIdLoadingState,
                                    masked: !_canSeeBalances,
                                    fmtMoney: _fmtMoney,
                                    onEdit: _onEditAccount,
                                    onDelete: _onDeleteAccount,
                                    onStatement: _onStatement,
                                  ),
                                ),
                                if (recent.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: _RecentTransactionsPanel(
                                      transactions: recent,
                                      masked: !_canSeeBalances,
                                      fmtMoney: _fmtMoney,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Profile column
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProfileContent(
      BuildContext context,
      ColorScheme color,
      StakeholdersModel data,
      ) {
    final dob = data.perDoB;
    final tr = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            Hero(
              tag: 'stakeholder_img_${data.perId}',
              flightShuttleBuilder: _buildHeroShuttle,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.primary.withValues(alpha: .1),
                  border: Border.all(
                    color: color.primary.withValues(alpha: .25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      spreadRadius: 2,
                      color: color.primary.withValues(alpha: .12),
                    ),
                  ],
                ),
                child: ImageHelper.stakeholderProfile(
                  onImageTap: () => ImageHelper.showImageViewer(
                    context: context,
                    imageName: data.imageProfile,
                    heroTag: 'stakeholder_viewer_${data.perId}',
                  ),
                  shapeStyle: ShapeStyle.circle,
                  imageName: data.imageProfile,
                  size: 120,
                ),
              ),
            ),
            InkWell(
              onTap: () => _onEditProfile(data),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.surface, width: 2),
                ),
                child:
                const Icon(Icons.edit, size: 15, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          fullName ?? '—',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (data.perPhone != null && data.perPhone!.isNotEmpty)
          _chip(
            icon: Icons.phone,
            label: data.perPhone!,
            fg: color.primary,
            bg: color.primary.withValues(alpha: .08),
          ),
        if (data.perEmail != null && data.perEmail!.isNotEmpty) ...[
          const SizedBox(height: 5),
          _chip(
            icon: Icons.email_outlined,
            label: data.perEmail!,
            fg: color.onSurfaceVariant,
            bg: color.surfaceContainerHighest.withValues(alpha: .5),
          ),
        ],
        const SizedBox(height: 20),
        _sectionDivider(color, tr.profile.toUpperCase()),
        const SizedBox(height: 14),
        _infoSection(
          context,
          icon: Icons.person_outline,
          title: tr.gender,
          value: data.perGender ?? '',
        ),
        if (dob != null)
          _infoSection(
            context,
            icon: Icons.cake_outlined,
            title: tr.dob,
            value: _formatDate(dob),
          ),
        if (data.perEnidNo != null && data.perEnidNo!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.badge_outlined,
            title: tr.nationalId,
            value: data.perEnidNo!,
          ),
        if (data.addName != null && data.addName!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.location_on_outlined,
            title: tr.address,
            value: data.addName!,
          ),
        if (data.addCity != null && data.addCity!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.location_city_outlined,
            title: tr.city,
            value: data.addCity!,
          ),
        if (data.addProvince != null && data.addProvince!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.map_outlined,
            title: tr.province,
            value: data.addProvince!,
          ),
        if (data.addCountry != null && data.addCountry!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.public_outlined,
            title: tr.country,
            value: data.addCountry!,
          ),
        if (data.addZipCode != null && data.addZipCode!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.markunread_mailbox_outlined,
            title: tr.zipCode,
            value: data.addZipCode!,
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider(ColorScheme color, String label) {
    return Row(
      children: [
        Expanded(child: Divider(color: color.outline.withValues(alpha: .2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: color.outline.withValues(alpha: .7),
            ),
          ),
        ),
        Expanded(child: Divider(color: color.outline.withValues(alpha: .2))),
      ],
    );
  }

  Widget _infoSection(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
      }) {
    final color = Theme.of(context).colorScheme;
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: color.outline.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? label;
  final VoidCallback? onPressed;

  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final button = ZOutlineButton(
      onPressed: onPressed,
      height: 36,
      isActive: false,
      icon: icon,
      label: Text(
        (label ?? tooltip).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(message: tooltip, child: button),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Accounts section — carries the masker down
// ═══════════════════════════════════════════════════════════════════
class _AccountsSection extends StatelessWidget {
  final List<StkAccountModel> accounts;
  final String ownerName;
  final bool isLoading;
  final bool masked;
  final String Function(num? v, {String? ccy}) fmtMoney;
  final ValueChanged<StkAccountModel> onEdit;
  final ValueChanged<StkAccountModel> onDelete;
  final ValueChanged<StkAccountModel> onStatement;

  const _AccountsSection({
    required this.accounts,
    required this.ownerName,
    required this.isLoading,
    required this.masked,
    required this.fmtMoney,
    required this.onEdit,
    required this.onDelete,
    required this.onStatement,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(
            children: [
              Text(
                tr.accounts.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${accounts.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const _ShimmerAccounts()
              : accounts.isEmpty
              ? const _EmptyAccounts()
              : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: accounts
                  .map(
                    (a) => SizedBox(
                  width: 320,
                  child: _BankCard(
                    account: a,
                    ownerName: ownerName,
                    masked: masked,
                    fmtMoney: fmtMoney,
                    onEdit: () => onEdit(a),
                    onDelete: () => onDelete(a),
                    onStatement: () => onStatement(a),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Recent transactions panel — carries the masker down
// ═══════════════════════════════════════════════════════════════════
class _RecentTransactionsPanel extends StatelessWidget {
  final List<RecentTransaction> transactions;
  final bool masked;
  final String Function(num? v, {String? ccy}) fmtMoney;

  const _RecentTransactionsPanel({
    required this.transactions,
    required this.masked,
    required this.fmtMoney,
  });

  static const double _wDate = 100;
  static const double _wRef = 220;
  static const double _wAccount = 150;
  static const double _wAmount = 150;
  static const double _wBalance = 150;
  static const double _wStatus = 84;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;
    final isEmpty = transactions.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.line_axis_rounded,
                    size: 20,
                    color: color.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  tr.recentTransactions,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${transactions.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: _wDate,
                  child: Text(
                    tr.date.toUpperCase(),
                    style: _headerStyle(color),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: Text(
                    tr.narration.toUpperCase(),
                    style: _headerStyle(color),
                  ),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: _wAccount,
                  child: Text(
                    tr.account.toUpperCase(),
                    textAlign: TextAlign.end,
                    style: _headerStyle(color),
                  ),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: _wAmount,
                  child: Text(
                    tr.amount.toUpperCase(),
                    textAlign: TextAlign.end,
                    style: _headerStyle(color),
                  ),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: _wBalance,
                  child: Text(
                    tr.balance.toUpperCase(),
                    textAlign: TextAlign.end,
                    style: _headerStyle(color),
                  ),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: _wStatus,
                  child: Text(
                    tr.status.toUpperCase(),
                    textAlign: TextAlign.end,
                    style: _headerStyle(color),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: isEmpty
                ? _EmptyTransactions(color: color)
                : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: transactions.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: color.outlineVariant.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, i) {
                return _RecentTxnRow(
                  tx: transactions[i],
                  color: color,
                  textTheme: textTheme,
                  masked: masked,
                  fmtMoney: fmtMoney,
                  wDate: _wDate,
                  wRef: _wRef,
                  wAccount: _wAccount,
                  wAmount: _wAmount,
                  wBalance: _wBalance,
                  wStatus: _wStatus,
                  gap: _gap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(ColorScheme color) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: color.onSurfaceVariant.withValues(alpha: .7),
  );
}

// ═══════════════════════════════════════════════════════════════════
// One recent-transaction row — now uses fmtMoney
// ═══════════════════════════════════════════════════════════════════
class _RecentTxnRow extends StatelessWidget {
  final RecentTransaction tx;
  final ColorScheme color;
  final TextTheme textTheme;
  final bool masked;
  final String Function(num? v, {String? ccy}) fmtMoney;
  final double wDate;
  final double wRef;
  final double wAccount;
  final double wAmount;
  final double wBalance;
  final double wStatus;
  final double gap;

  const _RecentTxnRow({
    required this.tx,
    required this.color,
    required this.textTheme,
    required this.masked,
    required this.fmtMoney,
    required this.wDate,
    required this.wRef,
    required this.wAccount,
    required this.wAmount,
    required this.wBalance,
    required this.wStatus,
    required this.gap,
  });

  bool get _isDebitIn => tx.drCr == 'Dr';
  Color get _amountColor => _isDebitIn ? const Color(0xFF16A34A) : color.error;
  IconData get _arrowIcon =>
      _isDebitIn ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

  /// Uses the shared masker for the amount (with sign) and the running
  /// balance. When [masked], the shared masker returns `••••••` — the
  /// same one used on the cards, so the two views stay in sync.
  String get _signedAmount {
    final body = fmtMoney(tx.amount, ccy: tx.currency);
    if (masked) return body;
    final sign = _isDebitIn ? '+' : '−';
    return '$sign$body';
  }

  String get _runningBalance =>
      fmtMoney(tx.runningBalance, ccy: tx.currency);

  @override
  Widget build(BuildContext context) {
    final balanceNegative = tx.runningBalance < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: wDate,
            child: _DateCell(tx: tx),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.reference ?? '—',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: color.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((tx.narration ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.narration!,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: wAccount,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.accountName ?? '—',
                  textAlign: TextAlign.end,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: color.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.account?.toString() ?? '—',
                  textAlign: TextAlign.end,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: wAmount,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(_arrowIcon, size: 14, color: _amountColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _signedAmount,
                    textAlign: TextAlign.end,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _amountColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: wBalance,
            child: Text(
              _runningBalance,
              textAlign: TextAlign.end,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (masked || !balanceNegative)
                    ? color.onSurface
                    : color.error,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: wStatus,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _TxnStatusPill(tx: tx),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Date cell — unchanged
// ═══════════════════════════════════════════════════════════════════
class _DateCell extends StatelessWidget {
  final RecentTransaction tx;
  const _DateCell({required this.tx});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final raw = tx.entryDate;
    if (raw == null) {
      return Text(
        '—',
        style: textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: color.onSurfaceVariant,
        ),
      );
    }

    final shamsi = raw.shamsiDateString;
    final gregorian = '${raw.year.toString().padLeft(4, '0')}-'
        '${raw.month.toString().padLeft(2, '0')}-'
        '${raw.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          shamsi,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          gregorian,
          style: textTheme.labelSmall?.copyWith(
            fontSize: 13,
            color: color.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Status pill — unchanged
// ═══════════════════════════════════════════════════════════════════
class _TxnStatusPill extends StatelessWidget {
  final RecentTransaction tx;
  const _TxnStatusPill({required this.tx});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final status = (tx.statusText ?? '').toLowerCase();

    final (Color bg, Color fg, String label) = switch (status) {
      'authorized' => (
      const Color(0xFF22C55E).withValues(alpha: isDark ? 0.18 : 0.12),
      isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
      tr.authorized,
      ),
      'pending' => (
      const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.12),
      isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
      tr.pending,
      ),
      'reversed' => (
      const Color(0xFF6366F1).withValues(alpha: isDark ? 0.20 : 0.12),
      isDark ? const Color(0xFFA5B4FC) : const Color(0xFF3730A3),
      tr.reversed,
      ),
      'deleted' => (
      const Color(0xFFEF4444).withValues(alpha: isDark ? 0.18 : 0.12),
      isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
      tr.deleted,
      ),
      _ => tx.isAuthorized
          ? (
      const Color(0xFF22C55E).withValues(alpha: isDark ? 0.18 : 0.12),
      isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
      tr.authorized,
      )
          : (
      const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.12),
      isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
      tr.pending,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Empty state — unchanged
// ═══════════════════════════════════════════════════════════════════
class _EmptyTransactions extends StatelessWidget {
  final ColorScheme color;
  const _EmptyTransactions({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: color.onSurfaceVariant.withValues(alpha: .35),
            ),
            const SizedBox(height: 10),
            Text(
              'No recent transactions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.onSurfaceVariant.withValues(alpha: .75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Bank card — uses fmtMoney for balance + limit
// ═══════════════════════════════════════════════════════════════════
class _BankCard extends StatelessWidget {
  final StkAccountModel account;
  final String ownerName;
  final bool masked;
  final String Function(num? v, {String? ccy}) fmtMoney;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatement;

  const _BankCard({
    required this.account,
    required this.ownerName,
    required this.masked,
    required this.fmtMoney,
    required this.onEdit,
    required this.onDelete,
    required this.onStatement,
  });

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color top, Color bottom) = _gradientFor(
      account.accCurrency ?? 'USD',
    );

    final isActive = account.accStatus == 1;
    final name = (account.accName?.isNotEmpty ?? false)
        ? account.accName!
        : AppLocalizations.of(context)!.account;
    final currency = account.accCurrency ?? '—';
    final accountNumber = account.accNumber?.toString() ?? '—';

    final borderRadius = BorderRadius.circular(_radius);

    return AspectRatio(
      aspectRatio: 1.586,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: bottom.withValues(alpha: isDark ? .55 : .35),
              blurRadius: 22,
              offset: const Offset(0, 14),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .35 : .12),
              blurRadius: 6,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [top, bottom],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0, .35, .6, 1],
                      colors: [
                        Colors.white.withValues(alpha: .14),
                        Colors.white.withValues(alpha: .04),
                        Colors.transparent,
                        Colors.black.withValues(alpha: .08),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -40,
                top: -40,
                child: _circle(160, Colors.white.withValues(alpha: .08)),
              ),
              Positioned(
                right: -20,
                bottom: -60,
                child: _circle(180, Colors.white.withValues(alpha: .06)),
              ),
              Positioned(
                left: -30,
                bottom: -50,
                child: _circle(140, Colors.white.withValues(alpha: .05)),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius - 1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .18),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _BankCardMenu(
                          onEdit: onEdit,
                          onDelete: onDelete,
                          onStatement: onStatement,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)!.balance.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .55),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            masked
                                ? '••••••'
                                : fmtMoney(
                              account.accBalance,
                              ccy: null,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currency,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!masked) ...[
                          const SizedBox(width: 8),
                          _BalancePositionBadge(balance: account.accBalance),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      accountNumber,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ownerName.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .75),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _limitLabel(account, masked: masked),
                        const SizedBox(width: 6),
                        _StatusDot(isActive: isActive),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _limitLabel(StkAccountModel a, {required bool masked}) {
    final text = a.isUnlimited
        ? '∞ LIMIT'
        : (a.limitValue != null
        ? 'LIMIT ${masked ? "••••" : fmtMoney(a.limitValue!, ccy: null)}'
        : null);
    if (text == null) return const SizedBox.shrink();
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: .65),
        fontSize: 8,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  (Color, Color) _gradientFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return (const Color(0xFF1E3A8A), const Color(0xFF0F172A));
      case 'EUR':
        return (const Color(0xFF4C1D95), const Color(0xFF1E1B4B));
      case 'AFN':
        return (const Color(0xFF166534), const Color(0xFF052E16));
      case 'PKR':
        return (const Color(0xFF7F1D1D), const Color(0xFF450A0A));
      default:
        return (const Color(0xFF334155), const Color(0xFF0F172A));
    }
  }
}

class _BalancePositionBadge extends StatelessWidget {
  final double balance;
  const _BalancePositionBadge({required this.balance});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final (label, bg, fg) = _resolve(balance, tr: tr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (String, Color, Color) _resolve(double balance, {AppLocalizations? tr}) {
    if (balance < 0) {
      return (
      tr!.debitor.toUpperCase(),
      const Color(0xFFEF4444).withValues(alpha: .18),
      const Color(0xFFFECACA),
      );
    }
    if (balance > 0) {
      return (
      tr!.creditor.toUpperCase(),
      const Color(0xFF22C55E).withValues(alpha: .18),
      const Color(0xFFBBF7D0),
      );
    }
    return (
    tr!.noBalance.toUpperCase(),
    Colors.white.withValues(alpha: .18),
    Colors.white.withValues(alpha: .85),
    );
  }
}

class _BankCardMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatement;

  const _BankCardMenu({
    required this.onEdit,
    required this.onDelete,
    required this.onStatement,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: 'Account actions',
      padding: EdgeInsets.zero,
      splashRadius: 16,
      iconSize: 20,
      icon: Icon(
        Icons.more_horiz,
        size: 20,
        color: Colors.white.withValues(alpha: .85),
      ),
      position: PopupMenuPosition.under,
      onSelected: (v) {
        switch (v) {
          case 'statement':
            onStatement();
            break;
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'statement',
          height: 40,
          child: Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 16),
              const SizedBox(width: 10),
              Text(tr.statement, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 16),
              const SizedBox(width: 10),
              Text(tr.edit, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(value: 'delete', height: 40, child: _DeleteItem()),
      ],
    );
  }
}

class _DeleteItem extends StatelessWidget {
  const _DeleteItem();

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Row(
      children: [
        Icon(Icons.delete_outline, size: 16, color: error),
        const SizedBox(width: 10),
        Text(
          AppLocalizations.of(context)!.delete,
          style: TextStyle(fontSize: 13, color: error),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isActive;
  const _StatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFF87171),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .9),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off_outlined,
            size: 44,
            color: color.onSurfaceVariant.withValues(alpha: .4),
          ),
          const SizedBox(height: 10),
          Text(
            'No accounts linked',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.onSurfaceVariant.withValues(alpha: .7),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shimmer — unchanged
// ═══════════════════════════════════════════════════════════════════

class _ShimmerAccounts extends StatelessWidget {
  const _ShimmerAccounts() : count = 3;

  final int count;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: List.generate(
          count,
              (_) => const SizedBox(width: 320, child: _ShimmerBankCard()),
        ),
      ),
    );
  }
}

class _ShimmerBankCard extends StatelessWidget {
  const _ShimmerBankCard();

  static const _top = Color(0xFF334155);
  static const _bottom = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final base = Colors.white.withValues(alpha: .08);
    final highlight = Colors.white.withValues(alpha: .22);

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_top, _bottom],
          ),
          boxShadow: [
            BoxShadow(
              color: _bottom.withValues(alpha: .3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: _circle(160, Colors.white.withValues(alpha: .08)),
              ),
              Positioned(
                right: -20,
                bottom: -60,
                child: _circle(180, Colors.white.withValues(alpha: .06)),
              ),
              Positioned(
                left: -30,
                bottom: -50,
                child: _circle(140, Colors.white.withValues(alpha: .05)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ShimmerBar(
                            width: double.infinity,
                            height: 11,
                            baseColor: base,
                            highlightColor: highlight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ShimmerBar(
                          width: 20,
                          height: 20,
                          radius: 10,
                          baseColor: base,
                          highlightColor: highlight,
                        ),
                      ],
                    ),
                    const Spacer(),
                    _ShimmerBar(
                      width: 56,
                      height: 8,
                      baseColor: base,
                      highlightColor: highlight,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ShimmerBar(
                          width: 120,
                          height: 22,
                          baseColor: base,
                          highlightColor: highlight,
                        ),
                        const SizedBox(width: 8),
                        _ShimmerBar(
                          width: 28,
                          height: 12,
                          baseColor: base,
                          highlightColor: highlight,
                        ),
                        const SizedBox(width: 8),
                        _ShimmerBar(
                          width: 62,
                          height: 16,
                          radius: 8,
                          baseColor: base,
                          highlightColor: highlight,
                        ),
                      ],
                    ),
                    const Spacer(),
                    _ShimmerBar(
                      width: 150,
                      height: 13,
                      baseColor: base,
                      highlightColor: highlight,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ShimmerBar(
                            width: double.infinity,
                            height: 9,
                            baseColor: base,
                            highlightColor: highlight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ShimmerBar(
                          width: 48,
                          height: 9,
                          baseColor: base,
                          highlightColor: highlight,
                        ),
                        const SizedBox(width: 8),
                        _ShimmerBar(
                          width: 44,
                          height: 12,
                          radius: 6,
                          baseColor: base,
                          highlightColor: highlight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _ShimmerBar extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    this.radius = 4,
  });

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}