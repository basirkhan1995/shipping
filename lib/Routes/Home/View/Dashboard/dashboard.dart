import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/cover.dart';
import 'package:shipping/Features/Widgets/digital_clock.dart';
import 'package:shipping/Routes/Auth/bloc/auth_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/Reminder/reminder_widget.dart';
import 'package:shipping/Services/api_services.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../Finance/View/ExchangeRate/Ui/exchange_rate.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _MobileDashboard(),
      tablet: const _TabletDashboard(),
      desktop: const _DesktopDashboard(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE — single column, everything stacks vertically
// ═══════════════════════════════════════════════════════════════════
class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET — two-column body (main + side), stats as 3-up grid
// ═══════════════════════════════════════════════════════════════════
class _TabletDashboard extends StatelessWidget {
  const _TabletDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(children: []),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP — full sidebar + main + right rail, stats as 4-up grid
// ═══════════════════════════════════════════════════════════════════
class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard();

  @override
  Widget build(BuildContext context) {
    double rightSideWidth = 350;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:  [
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(children: []),
                        ),
                        SizedBox(width: 20),
                        Column(
                          spacing: 8,
                          children: [
                            SizedBox(
                              width: rightSideWidth,
                              child: DigitalClock(),
                            ),
                            ExchangeRateView(
                                width: rightSideWidth,
                                settingButton: true,
                                newRateButton: true,
                            ),

                            SizedBox(
                                width: rightSideWidth,
                                child: DashboardAlertReminder())
                          ],
                        )
                      ],
                    ),
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

/// Desktop-only top bar with greeting + signed-in user's details + logout.
class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Read the authenticated user from the bloc.
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthenticatedState ? authState.loginData : null;

    final fullName = user?.usrFullName ?? user?.usrName ?? 'Guest';
    final username = user?.usrName ?? '';

// Only build the URL if we actually have a filename.
    final rawPhoto = user?.usrPhoto?.trim();
    final hasPhoto = rawPhoto != null &&
        rawPhoto.isNotEmpty &&
        rawPhoto.toLowerCase() != 'null' &&
        rawPhoto.toLowerCase() != 'undefined';
    final photoUrl = hasPhoto ? "${ApiServices.imageUrl}$rawPhoto" : null;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // ── Dashboard title + greeting block ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.dashboard,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_greeting()}, $fullName 👋',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Notifications + settings icons
          ZCover(
            radius: 50,
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.notifications_outlined,
              size: 22,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          ZCover(
            radius: 50,
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.settings,
              size: 22,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),

          // ── User block: avatar + name + username + logout ──
          ZCover(
            radius: 50,
            padding: const EdgeInsets.all(5),
            child: PopupMenuButton<String>(
              tooltip: 'Account',
              offset: const Offset(0, 48),
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthBloc>().add(OnLogoutEvent());
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar (photo with fallback to initials)
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage:
                    photoUrl!=null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl!=null && photoUrl.isEmpty
                        ? Text(
                      _initials(fullName),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onPrimaryContainer,
                      ),
                    ) : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Time-of-day greeting based on the device's local clock.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  /// First letter of first + last name, for the avatar fallback.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}