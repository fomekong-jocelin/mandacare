import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/widgets/compact_form_field.dart';
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
      final data = await widget.patientGateway.getMySupportTickets(session: widget.session);
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
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.contact_support_rounded, color: AppColors.medicalGreen, size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Soumettre un ticket de support',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.deepHealthBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          TextFormField(
                            controller: subjectController,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: compactInputDecoration(
                              context,
                              prefixIcon: const Icon(Icons.title_rounded, size: 19),
                            ).copyWith(
                              labelText: 'Sujet / Titre de la demande',
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CompactFieldLabel(label: 'Catégorie'),
                              const SizedBox(height: 5),
                              DropdownButtonFormField<String>(
                                value: category,
                                isExpanded: true,
                                decoration: compactInputDecoration(
                                  context,
                                  prefixIcon: const Icon(Icons.category_rounded, size: 19),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'BUG', child: Text('Signaler un Bug')),
                                  DropdownMenuItem(value: 'QUESTION', child: Text('Poser une Question')),
                                  DropdownMenuItem(value: 'REQUEST', child: Text('Demander une fonctionnalité')),
                                ],
                                onChanged: (val) => setDialogState(() => category = val!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CompactFieldLabel(label: 'Priorité'),
                              const SizedBox(height: 5),
                              DropdownButtonFormField<String>(
                                value: priority,
                                isExpanded: true,
                                decoration: compactInputDecoration(
                                  context,
                                  prefixIcon: const Icon(Icons.priority_high_rounded, size: 19),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                                  DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                                  DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
                                  DropdownMenuItem(value: 'URGENT', child: Text('Urgente')),
                                ],
                                onChanged: (val) => setDialogState(() => priority = val!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: compactInputDecoration(
                              context,
                              prefixIcon: const Icon(Icons.description_rounded, size: 19),
                              multiline: true,
                            ).copyWith(
                              labelText: 'Description détaillée',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                                child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
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
                                          Navigator.of(dialogContext).pop();
                                          _loadTickets();
                                        } catch (_) {
                                          setDialogState(() => saving = false);
                                        }
                                      },
                                style: FilledButton.styleFrom(backgroundColor: AppColors.medicalGreen),
                                icon: saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Soumettre'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadTickets,
                tooltip: 'Rafraîchir',
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.medicalGreen)))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.support_agent_rounded, size: 54, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadTickets,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Réessayer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.medicalGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _tickets.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.support_agent_rounded, size: 64, color: AppColors.textSecondary),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Aucune demande d\'assistance créée.',
                                    style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _showCreateTicketDialog,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Créer une demande'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.medicalGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _tickets.length,
                              itemBuilder: (context, index) {
                                final ticket = _tickets[index];
                                final priorityColor = _getPriorityColor(ticket.priority);
                                final isResolved = ticket.status == 'RESOLVED';
                                const radius = BorderRadius.all(Radius.circular(12));

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: radius,
                                    border: Border.all(color: AppColors.border.withValues(alpha: 0.40)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.deepHealthBlue.withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isResolved
                                                    ? AppColors.success.withValues(alpha: 0.08)
                                                    : AppColors.warning.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isResolved ? 'RÉSOLU' : 'EN COURS',
                                                style: TextStyle(
                                                  color: isResolved ? AppColors.success : AppColors.warning,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: priorityColor.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    ticket.priority,
                                                    style: TextStyle(
                                                      color: priorityColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _getCategoryLabel(ticket.category),
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          ticket.subject,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.deepHealthBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          ticket.description,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Créé le ${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')} à ${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          textAlign: TextAlign.end,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tickets.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _showCreateTicketDialog,
              backgroundColor: AppColors.medicalGreen,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            ),
    );
  }
}
