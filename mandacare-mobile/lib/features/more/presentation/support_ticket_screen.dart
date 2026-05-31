import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
import '../../../shared/presentation/widgets/form_dialog.dart';
import '../../../shared/presentation/widgets/page_header.dart';
import '../../auth/domain/auth_session.dart';
import '../../patients/data/patient_gateway.dart';
import '../../patients/domain/support_ticket.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({
    required this.session,
    required this.patientGateway,
    super.key,
  });

  final AuthSession session;
  final PatientGateway patientGateway;

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  List<SupportTicket> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.patientGateway.getMySupportTickets(
        session: widget.session,
      );
      if (!mounted) return;
      setState(() {
        _tickets = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Impossible de charger l'historique du support.";
        _loading = false;
      });
    }
  }

  void _showCreateTicketDialog() {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String category = 'BUG';
    String priority = 'MEDIUM';
    bool saving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppFormDialog(
              title: 'Soumettre un ticket de support',
              subtitle: 'Décrire clairement le besoin ou le blocage rencontré',
              icon: Icons.contact_support_rounded,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CompactTextFormField(
                      fieldKey: const ValueKey('support-subject-field'),
                      controller: subjectController,
                      label: 'Sujet / Titre de la demande',
                      icon: Icons.title_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SupportDropdownField(
                            label: 'Catégorie',
                            value: category,
                            icon: Icons.category_rounded,
                            items: const {
                              'BUG': 'Signaler un Bug',
                              'QUESTION': 'Poser une Question',
                              'REQUEST': 'Demander une fonctionnalité',
                            },
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => category = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SupportDropdownField(
                            label: 'Priorité',
                            value: priority,
                            icon: Icons.priority_high_rounded,
                            items: const {
                              'LOW': 'Basse',
                              'MEDIUM': 'Moyenne',
                              'HIGH': 'Haute',
                              'URGENT': 'Urgente',
                            },
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => priority = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CompactTextFormField(
                      fieldKey: const ValueKey('support-description-field'),
                      controller: descriptionController,
                      label: 'Description détaillée',
                      icon: Icons.description_rounded,
                      minLines: 4,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _required,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await widget.patientGateway.createSupportTicket(
                              session: widget.session,
                              subject: subjectController.text.trim(),
                              description: descriptionController.text.trim(),
                              category: category,
                              priority: priority,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            await _loadTickets();
                          } catch (_) {
                            setDialogState(() => saving = false);
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(saving ? 'Soumission...' : 'Soumettre'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requis';
    }
    return null;
  }

  Color _getPriorityColor(String pr) {
    switch (pr) {
      case 'LOW':
        return AppColors.info;
      case 'MEDIUM':
        return AppColors.warning;
      case 'HIGH':
        return AppColors.error;
      case 'URGENT':
        return const Color(0xFF7A0810);
      default:
        return AppColors.textSecondary;
    }
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'BUG':
        return 'Bug';
      case 'QUESTION':
        return 'Question';
      case 'REQUEST':
        return 'Fonctionnalité';
      default:
        return cat;
    }
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _SupportStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Chargement impossible',
        message: _error!,
        color: AppColors.error,
        actionLabel: 'Réessayer',
        onActionPressed: () => _loadTickets(),
      );
    }

    if (_tickets.isEmpty) {
      return _SupportStateView(
        icon: Icons.support_agent_rounded,
        title: 'Aucune demande d\'assistance créée.',
        message: 'Créez un ticket lorsque vous rencontrez un blocage.',
        color: AppColors.medicalGreen,
        actionLabel: 'Créer une demande',
        onActionPressed: _showCreateTicketDialog,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      itemCount: _tickets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return _SupportTicketCard(
          ticket: ticket,
          categoryLabel: _getCategoryLabel(ticket.category),
          priorityColor: _getPriorityColor(ticket.priority),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Support & Assistance',
              subtitle: 'Historique et nouvelles requêtes',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadTickets,
                    tooltip: 'Rafraîchir',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.medicalGreen,
                    ),
                    onPressed: _showCreateTicketDialog,
                    tooltip: 'Nouvelle demande',
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}

class _SupportDropdownField extends StatelessWidget {
  const _SupportDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompactFieldLabel(label: label),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          decoration: compactInputDecoration(
            context,
            prefixIcon: Icon(icon, size: 19),
          ),
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          items: [
            for (final entry in items.entries)
              DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
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

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({
    required this.ticket,
    required this.categoryLabel,
    required this.priorityColor,
  });

  final SupportTicket ticket;
  final String categoryLabel;
  final Color priorityColor;

  @override
  Widget build(BuildContext context) {
    final isResolved = ticket.status == 'RESOLVED';
    final statusColor = isResolved ? AppColors.success : AppColors.warning;
    final statusLabel = isResolved ? 'RÉSOLU' : 'EN COURS';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepHealthBlue.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.medicalGreen.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.medicalGreen,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _SupportChip(label: statusLabel, color: statusColor),
                        _SupportChip(
                          label: _priorityLabel(ticket.priority),
                          color: priorityColor,
                        ),
                        _SupportChip(
                          label: categoryLabel,
                          color: AppColors.deepHealthBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ticket.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.deepHealthBlue,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _createdAtLabel(ticket.createdAt),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _priorityLabel(String value) {
    return switch (value) {
      'LOW' => 'BASSE',
      'MEDIUM' => 'MOYENNE',
      'HIGH' => 'HAUTE',
      'URGENT' => 'URGENTE',
      _ => value,
    };
  }

  String _createdAtLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Créé le $day/$month à $hour:$minute';
  }
}

class _SupportChip extends StatelessWidget {
  const _SupportChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _SupportStateView extends StatelessWidget {
  const _SupportStateView({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onActionPressed,
              icon: Icon(
                actionLabel == 'Créer une demande'
                    ? Icons.add_rounded
                    : Icons.refresh_rounded,
              ),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
