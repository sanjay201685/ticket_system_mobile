import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/stock_order_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../stock_order_detail_screen.dart';

class StoreKeeperStockIssueScreen extends StatefulWidget {
  const StoreKeeperStockIssueScreen({super.key});

  @override
  State<StoreKeeperStockIssueScreen> createState() => _StoreKeeperStockIssueScreenState();
}

class _StoreKeeperStockIssueScreenState extends State<StoreKeeperStockIssueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StockOrderProvider>(context, listen: false)
          .loadStockOrders(status: 'pending_store_keeper', forceReload: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Keeper - Issue Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<StockOrderProvider>(context, listen: false)
                  .loadStockOrders(status: 'pending_store_keeper', forceReload: true);
            },
          ),
        ],
      ),
      body: Consumer<StockOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stockOrders.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerLoader(),
            );
          }

          if (provider.error != null && provider.stockOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadStockOrders(
                      status: 'pending_store_keeper',
                      forceReload: true,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.stockOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No stock orders pending issue',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadStockOrders(
              status: 'pending_store_keeper',
              forceReload: true,
            ),
            child: ListView.builder(
              itemCount: provider.stockOrders.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final order = provider.stockOrders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StockOrderDetailScreen(
                            orderId: order.id,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  order.orderNo ?? 'Order #${order.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (order.targetGodownName != null)
                            Row(
                              children: [
                                const Icon(Icons.warehouse, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Godown: ${order.targetGodownName}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          if (order.createdAt != null)
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Date: ${DateFormat('dd MMM yyyy').format(order.createdAt!)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

