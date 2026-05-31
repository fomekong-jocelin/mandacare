import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_section.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../data/user_gateway.dart';
import '../domain/team_user.dart';
import '../domain/user_payload.dart';
import '../domain/user_role.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({
    required this.session,
    required this.userGateway,
    required this.roles,
    this.user,
    super.key,
  });

  final AuthSession session;
  final UserGateway userGateway;
  final List<UserRole> roles;
  final TeamUser? user;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late String _roleCode;
  late bool _active;
  bool _saving = false;
  bool _hidePassword = true;

  bool get _editing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _roleCode = user?.role.code ?? widget.roles.first.code;
    _active = user?.active ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: _editing ? 'Modifier utilisateur' : 'Nouvel utilisateur',
              subtitle: _editing
                  ? 'Profil, rôle et statut du compte'
                  : 'Créer un accès pour un membre',
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                  children: [
                    FormSection(
                      title: 'Identité',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CompactTextFormField(
                                controller: _firstNameController,
                                label: 'Prénom',
                                icon: Icons.person_rounded,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                validator: _required,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CompactTextFormField(
                                controller: _lastNameController,
                                label: 'Nom',
                                icon: Icons.badge_rounded,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                validator: _required,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CompactTextFormField(
                          controller: _phoneController,
                          label: 'Téléphone',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        CompactTextFormField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FormSection(
                      title: 'Accès',
                      children: [
                        _RoleDropdown(
                          value: _roleCode,
                          roles: widget.roles,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _roleCode = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        CompactTextFormField(
                          controller: _usernameController,
                          label: "Nom d'utilisateur",
                          icon: Icons.alternate_email_rounded,
                          textInputAction: TextInputAction.next,
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        CompactTextFormField(
                          controller: _passwordController,
                          label: _editing
                              ? 'Nouveau mot de passe'
                              : 'Mot de passe',
                          helperText: _editing
                              ? 'Laisser vide pour conserver le mot de passe.'
                              : 'Minimum 6 caractères.',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _hidePassword,
                          validator: _passwordValidator,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _hidePassword = !_hidePassword);
                            },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                        if (_editing) ...[
                          const SizedBox(height: 12),
                          _StatusSwitch(
                            active: _active,
                            onChanged: (value) {
                              setState(() => _active = value);
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const ValueKey('save-user-button'),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving ? 'Enregistrement...' : 'Enregistrer utilisateur',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (_editing) {
        await widget.userGateway.updateUser(
          session: widget.session,
          id: widget.user!.id,
          payload: UpdateTeamUserPayload(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _optional(_phoneController.text),
            email: _optional(_emailController.text),
            username: _usernameController.text.trim(),
            password: _optional(_passwordController.text),
            roleCode: _roleCode,
            status: _active ? 'ACTIVE' : 'INACTIVE',
          ),
        );
      } else {
        await widget.userGateway.createUser(
          session: widget.session,
          payload: CreateTeamUserPayload(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _optional(_phoneController.text),
            email: _optional(_emailController.text),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            roleCode: _roleCode,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing ? 'Utilisateur mis à jour' : 'Utilisateur créé',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (_editing && (value == null || value.trim().isEmpty)) {
      return null;
    }
    final requiredError = _required(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.length < 6) {
      return 'Minimum 6 caractères';
    }
    return null;
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _message(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return "Impossible d'enregistrer l'utilisateur.";
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.roles,
    required this.onChanged,
  });

  final String value;
  final List<UserRole> roles;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CompactFieldLabel(label: 'Profil utilisateur'),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          decoration: compactInputDecoration(
            context,
            prefixIcon: const Icon(Icons.badge_rounded, size: 19),
          ),
          items: [
            for (final role in roles)
              DropdownMenuItem<String>(
                value: role.code,
                child: Text(
                  role.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusSwitch extends StatelessWidget {
  const _StatusSwitch({required this.active, required this.onChanged});

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.60)),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.verified_user_rounded : Icons.block_rounded,
            color: active ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              active ? 'Compte actif' : 'Compte inactif',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(value: active, onChanged: onChanged),
        ],
      ),
    );
  }
}
