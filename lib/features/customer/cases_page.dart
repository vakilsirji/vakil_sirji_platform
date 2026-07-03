import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/legal_case.dart';
import 'package:url_launcher/url_launcher.dart';
import 'case_timeline_sheet.dart';

class CasesPage extends StatelessWidget {
  final List<LegalCase> cases;
  final VoidCallback? onAddCase;

  const CasesPage({super.key, required this.cases, this.onAddCase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: onAddCase != null 
          ? FloatingActionButton.extended(
              onPressed: onAddCase,
              backgroundColor: Colors.amber,
              icon: const Icon(Icons.add, color: Color(0xFF0F172A)),
              label: const Text('New Agreement', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            )
          : null,
      body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final c = cases[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate300.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => CaseTimelineSheet(legalCase: c),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              border: Border.all(color: Colors.amber.shade200),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.serviceType,
                              style: TextStyle(color: Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(c.createdAt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Text('Client Mobile: ${c.clientMobile}', style: const TextStyle(color: AppColors.slate600, fontSize: 11)),
                      if (c.notes != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(8)),
                          child: Text(c.notes!, style: const TextStyle(color: AppColors.slate500, fontSize: 11, height: 1.4)),
                        ),
                      ],
                      const Divider(height: 24, thickness: 0.5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.track_changes, size: 14, color: Colors.indigo),
                              const SizedBox(width: 4),
                              Text(
                                'STATUS: ${c.status.name.toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.indigo),
                              ),
                            ],
                          ),
                          if (c.documentUrl != null)
                            ElevatedButton.icon(
                              onPressed: () => launchUrl(Uri.parse(c.documentUrl!), mode: LaunchMode.externalApplication),
                              icon: const Icon(Icons.picture_as_pdf, size: 12, color: Colors.white),
                              label: const Text('View PDF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            )
                          else if (c.status == AgreementStatus.draftReady)
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Agreement draft approved! Initiating biometric scheduling.'),
                                    backgroundColor: AppColors.emerald600,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Approve Draft', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    ),
  );
}
}
