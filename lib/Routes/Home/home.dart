import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/HR/hr.dart';
import 'package:shipping/Routes/Home/View/Products/products.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/bloc/company_settings_menu_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/bloc/settings_tab_bloc.dart';
import 'package:shipping/Routes/Home/View/Shipments/shipments.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/all_stakeholder.dart';
import 'package:shipping/Routes/Home/View/Transactions/transactions.dart';
import 'package:shipping/Routes/Home/View/Transfer/transfer.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../../Features/Widgets/generic_menu.dart';
import '../../l10n/app_localizations.dart';
import '../Auth/bloc/auth_bloc.dart';
import 'View/Dashboard/dashboard.dart';
import 'View/Finance/finance.dart';
import 'View/Report/report.dart';
import 'View/Settings/Visibility/bloc/settings_visible_bloc.dart';
import 'View/Settings/settings.dart';
import 'View/Stock/Orders/Ui/orders.dart';
import 'bloc/menu_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileView(),
      tablet: _TabletView(),
      desktop: _DesktopView(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _MobileView extends StatelessWidget {
  const _MobileView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Mobile'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET
// ═══════════════════════════════════════════════════════════════════
class _TabletView extends StatelessWidget {
  const _TabletView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Tablet'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _DesktopView extends StatelessWidget {
  const _DesktopView();

  @override
  Widget build(BuildContext context) {

    final currentTab = context.select((MenuBloc bloc) => bloc.state.tabs);
    final visibility = context.watch<SettingsVisibleBloc>().state;
    final menuItems = [
      MenuDefinition(
        value: MenuName.dashboard,
        label: AppLocalizations.of(context)!.dashboard,
        screen: const DashboardView(),
        icon: Icons.add_home_outlined,
      ),
      MenuDefinition(
        value: MenuName.finance,
        label: AppLocalizations.of(context)!.finance,
        screen: const FinanceView(),
        icon: Icons.monetization_on_rounded,
      ),
      MenuDefinition(
        value: MenuName.hr,
        label: AppLocalizations.of(context)!.hr,
        screen: const HrTabView(),
        icon: Icons.person,
      ),
      MenuDefinition(
        value: MenuName.transactions,
        label: AppLocalizations.of(context)!.transactions,
        screen: const TransactionsView(),
        icon: Icons.line_axis_rounded,
      ),
      MenuDefinition(
        value: MenuName.stakeholders,
        label: AppLocalizations.of(context)!.stakeholders,
        screen: const StakeholderView(),
        icon: Icons.people,
      ),
      if(visibility.orders)...[
        MenuDefinition(
          value: MenuName.stock,
          label: AppLocalizations.of(context)!.stock,
          screen: const OrdersView(),
          icon: Icons.shopify_rounded,
        ),
        MenuDefinition(
          value: MenuName.products,
          label: AppLocalizations.of(context)!.products,
          screen: const ProductsView(),
          icon: Icons.production_quantity_limits_rounded,
        ),
      ],

    if(visibility.shipping)
      MenuDefinition(
        value: MenuName.shipment,
        label: AppLocalizations.of(context)!.shipment,
        screen: const ShipmentsView(),
        icon: Icons.transform_rounded,
      ),
      if(visibility.moneyTransfer)
      MenuDefinition(
        value: MenuName.transfer,
        label: AppLocalizations.of(context)!.transfer,
        screen: const TransferView(),
        icon: Icons.attach_money_rounded,
      ),
      MenuDefinition(
        value: MenuName.settings,
        label: AppLocalizations.of(context)!.settings,
        screen: const SettingsView(),
        icon: Icons.settings_outlined,
      ),
      MenuDefinition(
        value: MenuName.report,
        label: AppLocalizations.of(context)!.report,
        screen: const ReportView(),
        icon: Icons.insert_drive_file_outlined,
      ),
    ];

    if (menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_accounts_rounded,
              size: 48,
              color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: .3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.accessDenied,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please contact administrator",
              style: TextStyle(
                fontSize: 14,
                color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: GenericMenuWithScreen<MenuName>(
          key: const Key('main_menu'),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          selectedValue: currentTab,
          onChanged: (val) {
            if (currentTab != val) {
              context.read<MenuBloc>().add(MenuOnChangedEvent(val));
            }
          },
          items: menuItems,
          selectedColor: Theme.of(context).colorScheme.primary.withAlpha(23),
          selectedTextColor:
          Theme.of(context).colorScheme.primary.withAlpha(230),
          unselectedTextColor: Theme.of(context).colorScheme.secondary,

          // ── Company logo + name at the top of the sidebar ──
          menuHeaderBuilder: (isExpanded) =>
              _CompanyHeader(isExpanded: isExpanded),
        ),
      ),
    );
  }
}

/// Header shown at the top of the desktop sidebar: company logo + name.
class _CompanyHeader extends StatelessWidget {
  final bool isExpanded;

  const _CompanyHeader({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final company =
    authState is AuthenticatedState ? authState.loginData.company : null;

    final companyName = company?.comName ?? 'Company';
    final logo = company?.comLogo;

    // Wider avatar: 75px expanded, 34px collapsed.
    final double logoSize = isExpanded ? 75 : 34;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 8 : 0,
        vertical: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo on top ──
          _CompanyLogo(
            logo: logo,
            scheme: scheme,
            size: logoSize,
          ),

          // ── Name below (hidden when collapsed) ──
          if (isExpanded) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: (){
                context.read<MenuBloc>().add(MenuOnChangedEvent(MenuName.settings));
                context.read<SettingsTabBloc>().add(SettingsOnChangeEvent(SettingsTabName.company));
                context.read<CompanySettingsMenuBloc>().add(CompanySettingsOnChangedEvent(CompanySettingsMenuName.profile));
              },
              child: Text(
                companyName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Company logo widget. Handles three input shapes:
///
///   1. `data:image/...;base64,...`  → strip prefix, decode, Image.memory
///   2. `https://...` or `http://...` → Image.network (cached)
///   3. Raw base64 (legacy)           → Image.memory (decoded inline)
///   4. Anything else / empty         → fallback icon
class _CompanyLogo extends StatelessWidget {
  /// `comLogo` value from the server. Could be:
  ///   - a `data:` URL  (current server contract)
  ///   - an `http(s):` URL (future server contract)
  ///   - raw base64 (legacy, still supported for safety)
  final String? logo;
  final ColorScheme scheme;
  final double size;

  const _CompanyLogo({
    required this.logo,
    required this.scheme,
    this.size = 36,
  });

  static bool _isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 12) return false;
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WebP
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    // BMP
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    return false;
  }

  Widget _fallback() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: scheme.primaryContainer,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.business_outlined,
      size: size * 0.55,
      color: scheme.onPrimaryContainer,
    ),
  );

  Widget _buildImage(Uint8List bytes) {
    return ClipOval(
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = logo;

    // No logo → fallback.
    if (raw == null || raw.isEmpty) {
      return _fallback();
    }

    // Case 1: real HTTP(S) URL → Image.network (cached by image cache).
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          raw,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }

    // Case 2: data: URL → extract base64 payload, decode to bytes.
    // (Image.network cannot handle data: URIs on desktop/web reliably.)
    String base64Payload = raw;
    if (raw.startsWith('data:')) {
      final commaIndex = raw.indexOf(',');
      if (commaIndex == -1 || commaIndex == raw.length - 1) {
        return _fallback();
      }
      base64Payload = raw.substring(commaIndex + 1);
    }

    // Case 3: raw base64 (legacy) OR extracted payload from data: URL.
    Uint8List bytes;
    try {
      // Strip any whitespace/newlines that can break decoding.
      base64Payload = base64Payload.trim().replaceAll(RegExp(r'\s+'), '');
      bytes = base64Decode(base64Payload);
    } catch (_) {
      return _fallback();
    }

    if (!_isValidImageBytes(bytes)) {
      return _fallback();
    }

    return _buildImage(bytes);
  }
}