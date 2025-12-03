import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/stock_order_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../services/auth_service.dart';
import '../stock_order_acceptance_detail_screen.dart';

class TechnicianStockAcceptanceScreen extends StatefulWidget {
  const TechnicianStockAcceptanceScreen({super.key});

  @override
  State<TechnicianStockAcceptanceScreen> createState() => _TechnicianStockAcceptanceScreenState();
}

class _TechnicianStockAcceptanceScreenState extends State<TechnicianStockAcceptanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final technicianId = authService.user?.id;
      if (technicianId != null) {
        Provider.of<StockOrderProvider>(context, listen: false)
            .loadStockOrders(
              status: 'issued',
              forTechnicianId: technicianId,
              forceReload: true,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Acceptance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              final technicianId = authService.user?.id;
              if (technicianId != null) {
                Provider.of<StockOrderProvider>(context, listen: false)
                    .loadStockOrders(
                      status: 'issued',
                      forTechnicianId: technicianId,
                      forceReload: true,
                    );
              }
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
                    onPressed: () {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      final technicianId = authService.user?.id;
                      if (technicianId != null) {
                        provider.loadStockOrders(
                          status: 'issued',
                          forTechnicianId: technicianId,
                          forceReload: true,
                        );
                      }
                    },
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
                    'No stock orders issued',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              final technicianId = authService.user?.id;
              if (technicianId != null) {
                return provider.loadStockOrders(
                  status: 'issued',
                  forTechnicianId: technicianId,
                  forceReload: true,
                );
              }
              return Future.value();
            },
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
                          builder: (context) => StockOrderAcceptanceDetailScreen(
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Total Items: ${order.totalItems}',
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

