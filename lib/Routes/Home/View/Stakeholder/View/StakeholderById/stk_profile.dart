import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
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

// ═══════════════════════════════════════════════════════════════════
// Entry point
// ═══════════════════════════════════════════════════════════════════
class StakeholderByIdView extends StatelessWidget {
  final IndividualsModel ind;
  const StakeholderByIdView({super.key, required this.ind});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _StakeholderByIdMobile(ind: ind),
      tablet: _StakeholderByIdDesktop(ind: ind),
      desktop: _StakeholderByIdDesktop(ind: ind),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _StakeholderByIdMobile extends StatelessWidget {
  final IndividualsModel ind;
  const _StakeholderByIdMobile({required this.ind});

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
  final IndividualsModel ind;
  const _StakeholderByIdDesktop({required this.ind});

  @override
  State<_StakeholderByIdDesktop> createState() =>
      _StakeholderByIdDesktopState();
}

class _StakeholderByIdDesktopState extends State<_StakeholderByIdDesktop> {
  IndividualsModel? individual;
  String? fullName;

  /// Set to `true` whenever an action on this screen modifies data that the
  /// stakeholders list (StakeholderBloc) displays — i.e. account balances.
  ///
  /// When `true`, the screen pops with `true` so the caller (StakeholderView)
  /// can refresh its list without a manual pull-to-refresh.
  bool _listNeedsRefresh = false;

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

  @override
  void initState() {
    super.initState();
    individual = widget.ind;
    fullName = _composeName(widget.ind);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_stkId != null) {
        context
            .read<StkAccountsBloc>()
            .add(LoadStkAccountsEvent(perId: _stkId!));
      }

      if (_stkId != null) {
        context
            .read<StakeholderByIdBloc>()
            .add(LoadStakeholderByIdEvent(stkId: _stkId!));
      }
    });
  }

  String _composeName(IndividualsModel m) {
    final first = m.perName ?? '';
    final last = m.perLastName ?? '';
    final combined = '$first $last'.trim();
    return combined.isEmpty ? '—' : combined;
  }

  void _reloadProfile() {
    if (_stkId != null) {
      context
          .read<StakeholderByIdBloc>()
          .add(LoadStakeholderByIdEvent(stkId: _stkId!));
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

  // ── Current user / base currency ────────────────────────────────
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

  // ── Cash specs for CHDP / CHWL ──────────────────────────────────
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

  // ── Cash dialog ─────────────────────────────────────────────────
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
      _listNeedsRefresh = true; // ← balances changed → list needs refresh
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

  // ── Fund-transfer dialog ────────────────────────────────────────
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
      _listNeedsRefresh = true; // ← balances changed → list needs refresh
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

  // ── Edit profile ────────────────────────────────────────────────
  Future<void> _onEditProfile(IndividualsModel data) async {
    if (data.perId == null) {
      _showError('Edit profile', 'perId is null');
      return;
    }
    try {
      final updated = await showDialog<IndividualsModel>(
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

  // ── Add account ─────────────────────────────────────────────────
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
      _listNeedsRefresh = true; // ← account list may have changed
      context
          .read<StkAccountsBloc>()
          .add(LoadStkAccountsEvent(perId: _stkId!));
    } catch (e) {
      _showError('Add account', e);
    }
  }

  // ── Edit account ────────────────────────────────────────────────
  Future<void> _onEditAccount(StakeholderAccount account) async {
    if (account.accNumber == null) {
      _showError('Edit account', 'accNumber is null');
      return;
    }
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => StkAccountFormDialog(
          perId: _stkId!,
          account: account,
        ),
      );
      if (!mounted) return;
      _listNeedsRefresh = true; // ← balance / limit may have changed
    } catch (e) {
      _showError('Edit account', e);
    }
  }

  // ── Statement ───────────────────────────────────────────────────
  Future<void> _onStatement(StakeholderAccount account) async {
    if (account.accNumber == null) {
      _showError('Statement', 'accNumber is null');
      return;
    }

    ZNavigator.goto(
      context: context,
      AccountStatementView(initialAccountNumber: account.accNumber),
    );
  }

  // ── Delete account ──────────────────────────────────────────────
  Future<void> _onDeleteAccount(StakeholderAccount account) async {
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
        _listNeedsRefresh = true; // ← account removed from totals
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

    // Intercept the pop so we can return whether the stakeholder list needs
    // a refresh (i.e. whether any balance-affecting action happened here).
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_listNeedsRefresh);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(tr.profileOverview),
          actions: [
            _AppBarAction(
              icon: Icons.arrow_downward_rounded,
              tooltip: tr.cashDeposit,
              onPressed: () => _openCashDialog('CHDP'),
            ),
            _AppBarAction(
              icon: Icons.arrow_upward_rounded,
              tooltip: tr.cashWithdraw,
              onPressed: () => _openCashDialog('CHWL'),
            ),
            _AppBarAction(
              icon: Icons.swap_horiz_rounded,
              tooltip: tr.fundTransfer,
              onPressed: _openFundTransferDialog,
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: ZOutlineButton(
                onPressed: _onAddAccount,
                height: 36,
                icon: Icons.add,
                isActive: true,
                label: Text(tr.addAccount),
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
              _listNeedsRefresh = true; // ← profile edit → list needs refresh
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
            (c is StkAccountsLoadedState && c.successMessage != null) ||
                (c is StkAccountsFailureState && c.errorMessage != null),
            listener: (context, state) {
              if (state is StkAccountsLoadedState &&
                  state.successMessage != null) {
                _listNeedsRefresh = true; // ← account mutation succeeded
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
              context
                  .read<StkAccountsBloc>()
                  .add(const ClearStkAccountMessagesEvent());
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
                              SizedBox(
                                height: 250,
                                child: _AccountsSection(
                                  accounts: accounts,
                                  ownerName: fullName ?? '—',
                                  isLoading:
                                  state is StakeholderByIdLoadingState,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Profile column
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProfileContent(
      BuildContext context,
      ColorScheme color,
      IndividualsModel data,
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
                child: const Icon(Icons.edit, size: 15, color: Colors.white),
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

// ═══════════════════════════════════════════════════════════════════
// AppBar action button
// ═══════════════════════════════════════════════════════════════════
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: .4),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Accounts section
// ═══════════════════════════════════════════════════════════════════
class _AccountsSection extends StatelessWidget {
  final List<StakeholderAccount> accounts;
  final String ownerName;
  final bool isLoading;
  final ValueChanged<StakeholderAccount> onEdit;
  final ValueChanged<StakeholderAccount> onDelete;
  final ValueChanged<StakeholderAccount> onStatement;

  const _AccountsSection({
    required this.accounts,
    required this.ownerName,
    required this.isLoading,
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
                tr.accounts,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              ? const Center(child: CircularProgressIndicator())
              : accounts.isEmpty
              ? const _EmptyAccounts()
              : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: accounts
                  .map((a) => SizedBox(
                width: 320,
                child: _BankCard(
                  account: a,
                  ownerName: ownerName,
                  onEdit: () => onEdit(a),
                  onDelete: () => onDelete(a),
                  onStatement: () => onStatement(a),
                ),
              ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Recent transactions panel
// ═══════════════════════════════════════════════════════════════════
class _RecentTransactionsPanel extends StatelessWidget {
  final List<RecentTransaction> transactions;
  const _RecentTransactionsPanel({required this.transactions});

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
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
                  child:
                  Text(tr.date.toUpperCase(), style: _headerStyle(color)),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: Text(tr.narration.toUpperCase(),
                      style: _headerStyle(color)),
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
                    tr.status,
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
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: color.onSurfaceVariant.withValues(alpha: .7),
  );
}

// ═══════════════════════════════════════════════════════════════════
// One recent-transaction row
// ═══════════════════════════════════════════════════════════════════
class _RecentTxnRow extends StatelessWidget {
  final RecentTransaction tx;
  final ColorScheme color;
  final TextTheme textTheme;
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
    required this.wDate,
    required this.wRef,
    required this.wAccount,
    required this.wAmount,
    required this.wBalance,
    required this.wStatus,
    required this.gap,
  });

  bool get _isDebitIn => tx.drCr == 'Dr';
  Color get _amountColor =>
      _isDebitIn ? const Color(0xFF16A34A) : color.error;
  IconData get _arrowIcon => _isDebitIn
      ? Icons.arrow_upward_rounded
      : Icons.arrow_downward_rounded;

  String get _signedAmount {
    final sign = _isDebitIn ? '+' : '−';
    final raw = tx.amount.toAmount();
    final body = raw.toAmount();
    final ccy = tx.currency ?? '';
    return ccy.isEmpty ? '$sign$body' : '$sign$body $ccy';
  }

  @override
  Widget build(BuildContext context) {
    final balanceNegative = tx.runningBalance < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: wDate, child: _DateCell(tx: tx)),
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
              tx.formattedRunningBalance,
              textAlign: TextAlign.end,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: balanceNegative ? color.error : color.onSurface,
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
// Date cell
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
// Status pill
// ═══════════════════════════════════════════════════════════════════
class _TxnStatusPill extends StatelessWidget {
  final RecentTransaction tx;
  const _TxnStatusPill({required this.tx});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isAuth = tx.isAuthorized;
    final bg = isAuth
        ? const Color(0xFF22C55E).withValues(alpha: .12)
        : const Color(0xFFF59E0B).withValues(alpha: .12);
    final fg = isAuth ? const Color(0xFF166534) : const Color(0xFF92400E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tx.statusText ?? (isAuth ? tr.authorized : tr.pending),
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
// Empty state
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
// Bank card
// ═══════════════════════════════════════════════════════════════════
class _BankCard extends StatelessWidget {
  final StakeholderAccount account;
  final String ownerName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatement;

  const _BankCard({
    required this.account,
    required this.ownerName,
    required this.onEdit,
    required this.onDelete,
    required this.onStatement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color top, Color bottom) =
    _gradientFor(account.accCurrency ?? 'UNK');

    final isActive = account.accStatus == 1;
    final name = (account.accName?.isNotEmpty ?? false)
        ? account.accName!
        : AppLocalizations.of(context)!.account;
    final currency = account.accCurrency ?? '—';
    final accountNumber = account.accNumber?.toString() ?? '—';

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, bottom],
          ),
          boxShadow: [
            BoxShadow(
              color: bottom.withValues(alpha: isDark ? .45 : .3),
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
                      'BALANCE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .55),
                        fontSize: 9,
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
                            _formatAmount(account.accBalance),
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
                        const SizedBox(width: 8),
                        _BalancePositionBadge(
                          balance: account.accBalance,
                        ),
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
                        _limitLabel(account),
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

  Widget _limitLabel(StakeholderAccount a) {
    final text = a.isUnlimited
        ? '∞ LIMIT'
        : (a.limitValue != null
        ? 'LIMIT ${_formatAmount(a.limitValue!)}'
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

  String _formatAmount(num value) {
    final parts = value.toDouble().toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// Debtor / Creditor badge
// ═══════════════════════════════════════════════════════════════════
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
              Icon(Icons.receipt_long_outlined, size: 16),
              SizedBox(width: 10),
              Text(tr.statement, style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 10),
              Text(tr.edit, style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 40,
          child: _DeleteItem(),
        ),
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
        Text(AppLocalizations.of(context)!.delete,
            style: TextStyle(fontSize: 13, color: error)),
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
          Icon(Icons.credit_card_off_outlined,
              size: 44,
              color: color.onSurfaceVariant.withValues(alpha: .4)),
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