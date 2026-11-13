import 'package:flutter/material.dart';

import 'area_calculator.dart';
import 'measurement_store.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.store, required this.mapAllowed});
  final MeasurementStore store;
  final bool mapAllowed;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<MeasurementRecord>> _records;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _records = widget.store.loadRecords();
  }

  Future<void> _delete(MeasurementRecord record) async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除测量记录'),
        content: Text('确定删除“${record.name}”吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _deleting = true);
    try {
      final removed = await widget.store.deleteRecord(record);
      if (!mounted) return;
      setState(() => _records = widget.store.loadRecords());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(removed ? '记录已删除' : '记录不存在，请刷新后查看')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('测量记录')),
    body: FutureBuilder<List<MeasurementRecord>>(
      future: _records,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('读取记录失败，请重试。'));
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        if (records.isEmpty) {
          return const Center(child: Text('暂无记录。完成测量后可以保存到本机。'));
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final record = records[index];
            final date = record.createdAt.toLocal();
            final area = AreaCalculator.squareMeters(record.points);
            final time =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            return ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HistoryDetailPage(
                    record: record,
                    mapAllowed: widget.mapAllowed,
                  ),
                ),
              ),
              leading: const Icon(Icons.landscape_outlined),
              title: Text(record.name),
              subtitle: Text(
                '$time · ${record.points.length} 个边界点\n${area.toStringAsFixed(0)} 平方米 · 周长 ${AreaCalculator.perimeterMeters(record.points).toStringAsFixed(0)} 米',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(area / AreaCalculator.squareMetersPerMu).toStringAsFixed(2)} 亩',
                  ),
                  IconButton(
                    onPressed: _deleting ? null : () => _delete(record),
                    tooltip: '删除记录',
                    icon: const Icon(Icons.delete_outline),
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
