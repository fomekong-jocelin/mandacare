import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/user_gateway.dart';
import '../domain/team_user.dart';
import '../domain/user_role.dart';
import 'user_form_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({
    required this.session,
    required this.userGateway,
    super.key,
  });

  final AuthSession session;
  final UserGateway userGateway;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<TeamUser> _users = const [];
  List<UserRole> _roles = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = _users.where((user) => user.active).length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Équipe',
              subtitle: 'Utilisateurs, profils et accès',
              trailing: IconButton.filled(
                key: const ValueKey('add-user-button'),
                onPressed: _roles.isEmpty ? null : () => _openForm(),
                tooltip: 'Créer un utilisateur',
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                  children: [
                    _TeamSummary(
                      totalUsers: _users.length,
                      activeUsers: activeUsers,
                      roleCount: _roles.length,
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _LoadError(message: _error!, onRetry: _load)
                    else if (_users.isEmpty)
                      const _EmptyTeam()
                    else
                      for (final user in _users) ...[
                        _UserCard(user: user, onTap: () => _openForm(user)),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        widget.userGateway.listRoles(session: widget.session),
        widget.userGateway.listUsers(session: widget.session),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _roles = result[0] as List<UserRole>;
        _users = result[1] as List<TeamUser>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _openForm([TeamUser? user]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserFormScreen(
          session: widget.session,
          userGateway: widget.userGateway,
          roles: _roles,
          user: user,
        ),
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  String _message(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return "Impossible de charger l'équipe.";
  }
}

class _TeamSummary extends StatelessWidget {
  const _TeamSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.roleCount,
  });

  final int totalUsers;
  final int activeUsers;
  final int roleCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Utilisateurs',
            value: totalUsers.toString(),
            icon: Icons.groups_rounded,
            color: AppColors.deepHealthBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'Actifs',
            value: activeUsers.toString(),
            icon: Icons.verified_user_rounded,
            color: AppColors.medicalGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'Profils',
            value: roleCount.toString(),
            icon: Icons.badge_rounded,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 9),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});

  final TeamUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepHealthBlue.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _RoleAvatar(role: user.role),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.role.label} · @${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.15,
                      ),
                    ),
                    if (user.phone != null || user.email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.phone ?? user.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(active: user.active),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleAvatar extends StatelessWidget {
  const _RoleAvatar({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.medicalGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_roleIcon(role.code), color: AppColors.medicalGreen),
    );
  }

  IconData _roleIcon(String code) {
    return switch (code.toUpperCase()) {
      'ADMIN' => Icons.admin_panel_settings_rounded,
      'MEDECIN' => Icons.medical_services_rounded,
      'INFIRMIER' => Icons.health_and_safety_rounded,
      'CAISSIER' => Icons.point_of_sale_rounded,
      'LABORATOIRE' => Icons.science_rounded,
      'ACCUEIL' => Icons.support_agent_rounded,
      _ => Icons.badge_rounded,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Actif' : 'Inactif',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _EmptyTeam extends StatelessWidget {
  const _EmptyTeam();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: const Text('Aucun utilisateur enregistré.'),
    );
  }
}
