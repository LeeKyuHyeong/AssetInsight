import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/reset_button.dart';

class SaveLoadScreen extends ConsumerWidget {
  const SaveLoadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    // 샘플 세이브 데이터
    final saves = [
      {
        'slot': 1,
        'team': 'SK텔레콤 T1',
        'season': 3,
        'rank': 2,
        'date': '2026-02-03 14:30',
      },
      {
        'slot': 2,
        'team': 'KT 롤스터',
        'season': 1,
        'rank': 4,
        'date': '2026-02-01 10:15',
      },
      {'slot': 3, 'team': null},
      {'slot': 4, 'team': null},
      {'slot': 5, 'team': null},
      {'slot': 6, 'team': null},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('세이브 / 로드'),
        leading: ResetButton.leading(),
      ),
      body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: saves.length,
            itemBuilder: (context, index) {
              final save = saves[index];
              final isEmpty = save['team'] == null;

              return _SaveSlotCard(
                slot: save['slot'] as int,
                team: save['team'] as String?,
                season: save['season'] as int?,
                rank: save['rank'] as int?,
                date: save['date'] as String?,
                isEmpty: isEmpty,
                onLoad: isEmpty
                    ? null
                    : () {
                        // TODO: 로드 처리
                        context.go('/main');
                      },
                onSave: () {
                  // TODO: 세이브 처리
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('슬롯 ${save['slot']}에 저장되었습니다')),
                  );
                },
                onDelete: isEmpty
                    ? null
                    : () {
                        // TODO: 삭제 처리
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('삭제 확인'),
                            content: Text('슬롯 ${save['slot']}의 데이터를 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('삭제되었습니다')),
                                  );
                                },
                                child: const Text(
                                  '삭제',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
              );
            },
          ),
    );
  }
}

class _SaveSlotCard extends StatelessWidget {
  final int slot;
  final String? team;
  final int? season;
  final int? rank;
  final String? date;
  final bool isEmpty;
  final VoidCallback? onLoad;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _SaveSlotCard({
    required this.slot,
    required this.team,
    required this.season,
    required this.rank,
    required this.date,
    required this.isEmpty,
    required this.onLoad,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 슬롯 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isEmpty
                        ? AppTheme.textSecondary.withOpacity(0.3)
                        : AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '슬롯 $slot',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isEmpty && date != null)
                  Text(
                    date!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 세이브 정보
            if (isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '빈 슬롯',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else ...[
              Text(
                team!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _InfoChip(label: '시즌', value: '$season'),
                  const SizedBox(width: 8),
                  _InfoChip(label: '순위', value: '$rank위'),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isEmpty) ...[
                  OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('삭제'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onLoad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('불러오기'),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: onSave,
                    child: const Text('저장'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
