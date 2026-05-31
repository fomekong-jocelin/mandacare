import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
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
            return AlertDialog(
              title: const Text('Soumettre un ticket de support'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: subjectController,
                        decoration: const InputDecoration(labelText: 'Sujet / Titre de la demande'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: 'Catégorie'),
                        items: const [
                          DropdownMenuItem(value: 'BUG', child: Text('Signaler un Bug')),
                          DropdownMenuItem(value: 'QUESTION', child: Text('Poser une Question')),
                          DropdownMenuItem(value: 'REQUEST', child: Text('Demander une fonctionnalité')),
                        ],
                        onChanged: (val) => setDialogState(() => category = val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(labelText: 'Priorité'),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                          DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                          DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
                          DropdownMenuItem(value: 'URGENT', child: Text('Urgente')),
                        ],
                        onChanged: (val) => setDialogState(() => priority = val!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description détaillée',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await widget.patientGateway.createSupportTicket(
                              session: widget.session,
                              subject: subjectController.text,
                              description: descriptionController.text,
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
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Soumettre'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getPriorityColor(String pr) {
    switch (pr) {
      case 'LOW':
        return Colors.blue;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.red[400]!;
      case 'URGENT':
        return Colors.red[900]!;
      default:
        return Colors.grey;
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
      appBar: AppBar(
        title: const Text('Support & Assistance'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.medicalGreen)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.support_agent_outlined, size: 54, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadTickets, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.support_agent_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Aucune demande d\'assistance créée.'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateTicketDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Créer une demande'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.medicalGreen, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        final priorityColor = _getPriorityColor(ticket.priority);
                        final isResolved = ticket.status == 'RESOLVED';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 16),
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
                                        color: isResolved ? Colors.green[100] : Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isResolved ? 'RÉSOLU' : 'EN COURS',
                                        style: TextStyle(
                                          color: isResolved ? Colors.green[800] : Colors.orange[800],
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
                                            color: priorityColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            ticket.priority,
                                            style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getCategoryLabel(ticket.category),
                                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ticket.subject,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ticket.description,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Créé le ${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')} à ${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: _tickets.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _showCreateTicketDialog,
              backgroundColor: AppColors.medicalGreen,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
    );
  }
}
