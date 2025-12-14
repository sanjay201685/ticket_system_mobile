import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ticket_system/services/auth_service.dart';
import 'package:ticket_system/screens/purchase/purchase_request_create.dart';
import 'package:ticket_system/screens/team_leader/purchase_request_list_screen.dart';
import 'package:ticket_system/screens/stock/stock_order_create_screen.dart';
import 'package:ticket_system/screens/stock/stock_order_list_screen.dart';
import 'package:ticket_system/screens/profile_screen.dart';
import 'package:ticket_system/screens/change_password_screen.dart';
import 'package:ticket_system/screens/wallet/wallet_transaction_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final userRole = user?.role?.toLowerCase().trim() ?? '';

    // Determine role-based menu items
    List<DrawerMenuItem> menuItems = _getMenuItemsForRole(userRole);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user?.name != null && user!.name.isNotEmpty)
                        ? user.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (userRole.isNotEmpty ? userRole : 'user').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          ...menuItems.map((item) {
            if (item.isDivider) {
              return const Divider();
            }
            return ListTile(
              leading: Icon(item.icon, color: Theme.of(context).primaryColor),
              title: Text(item.title ?? ''),
              onTap: () {
                Navigator.pop(context); // Close drawer
                if (item.onTap != null) {
                  item.onTap!(context);
                } else if (item.route != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => item.route!),
                  );
                }
              },
            );
          }),

          // Logout
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
            },
          ),
        ],
      ),
    );
  }

  List<DrawerMenuItem> _getMenuItemsForRole(String role) {
    List<DrawerMenuItem> items = [];

    if (role.contains('technician')) {
      // Technician Menu
      items.addAll([
        DrawerMenuItem(
          title: 'Create Purchase Request',
          icon: Icons.shopping_cart,
          route: const PurchaseRequestCreateScreen(),
        ),
        DrawerMenuItem(
          title: 'List of Purchase Request',
          icon: Icons.list_alt,
          route: const PurchaseRequestListScreen(),
        ),
        DrawerMenuItem(
          title: 'Create Stock Request',
          icon: Icons.add_shopping_cart,
          route: const StockOrderCreateScreen(),
        ),
        DrawerMenuItem(
          title: 'List of Stock Request',
          icon: Icons.inventory_2,
          route: const StockOrderListScreen(),
        ),
        DrawerMenuItem(
          title: 'Start Service Task',
          icon: Icons.build,
          onTap: (context) {
            // TODO: Navigate to Start Service Task screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Start Service Task - Coming Soon')),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Stock Consume Entry',
          icon: Icons.remove_circle_outline,
          onTap: (context) {
            // TODO: Navigate to Stock Consume Entry screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stock Consume Entry - Coming Soon')),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Add Petrol Entry',
          icon: Icons.local_gas_station,
          onTap: (context) {
            // TODO: Navigate to Add Petrol Entry screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add Petrol Entry - Coming Soon')),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Wallet Transactions',
          icon: Icons.account_balance_wallet,
          route: const WalletTransactionScreen(),
        ),
      ]);
    } else if (role.contains('manager')) {
      // Manager Menu
      items.addAll([
        DrawerMenuItem(
          title: 'Approve Stock Requests',
          icon: Icons.check_circle,
          onTap: (context) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StockOrderListScreen(),
              ),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Approve Purchase Requests',
          icon: Icons.approval,
          route: const PurchaseRequestListScreen(),
        ),
        DrawerMenuItem(
          title: 'Wallet Transactions',
          icon: Icons.account_balance_wallet,
          route: const WalletTransactionScreen(),
        ),
        DrawerMenuItem(
          title: 'Approve Transfers',
          icon: Icons.swap_horiz,
          onTap: (context) {
            // TODO: Navigate to Approve Transfers screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Approve Transfers - Coming Soon')),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Daily Summary Report',
          icon: Icons.summarize,
          onTap: (context) {
            // TODO: Navigate to Daily Summary Report screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daily Summary Report - Coming Soon')),
            );
          },
        ),
      ]);
    } else if (role.contains('team_leader') || role.contains('team leader') || role.contains('teamleader')) {
      // Team Leader Menu
      items.addAll([
        DrawerMenuItem(
          title: 'Create Purchase Request',
          icon: Icons.shopping_cart,
          route: const PurchaseRequestCreateScreen(),
        ),
        DrawerMenuItem(
          title: 'Create Stock Issue Request',
          icon: Icons.add_shopping_cart,
          route: const StockOrderCreateScreen(),
        ),
        DrawerMenuItem(
          title: 'Technician Stock Transfer',
          icon: Icons.swap_horiz,
          onTap: (context) {
            // TODO: Navigate to Technician Stock Transfer screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Technician Stock Transfer - Coming Soon')),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Approve Technician Requests',
          icon: Icons.check_circle,
          onTap: (context) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StockOrderListScreen(),
              ),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Today Tasks',
          icon: Icons.today,
          onTap: (context) {
            // TODO: Navigate to Today Tasks screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Today Tasks - Coming Soon')),
            );
          },
        ),
      ]);
    } else if (role.contains('cashier')) {
      // Cashier Menu
      items.addAll([
        DrawerMenuItem(
          title: 'Approve Payment',
          icon: Icons.payment,
          onTap: (context) {
            // TODO: Navigate to Approve Payment screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Approve Payment - Coming Soon')),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Wallet Transactions',
          icon: Icons.account_balance_wallet,
          route: const WalletTransactionScreen(),
        ),
        DrawerMenuItem(
          title: 'Payment History',
          icon: Icons.history,
          onTap: (context) {
            // TODO: Navigate to Payment History screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment History - Coming Soon')),
            );
          },
        ),
        DrawerMenuItem(
          title: 'Daily Expense Report',
          icon: Icons.summarize,
          onTap: (context) {
            // TODO: Navigate to Daily Expense Report screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daily Expense Report - Coming Soon')),
            );
          },
        ),
      ]);
    }

    // Common Menu Items (for all roles)
    items.add(DrawerMenuItem(isDivider: true));
    items.add(
      DrawerMenuItem(
        title: 'Wallet Transactions',
        icon: Icons.account_balance_wallet,
        route: const WalletTransactionScreen(),
      ),
    );
    items.add(
      DrawerMenuItem(
        title: 'Profile',
        icon: Icons.person,
        route: const ProfileScreen(),
      ),
    );
    items.add(
      DrawerMenuItem(
        title: 'Change Password',
        icon: Icons.lock,
        route: const ChangePasswordScreen(),
      ),
    );

    return items;
  }
}

class DrawerMenuItem {
  final String? title;
  final IconData? icon;
  final Widget? route;
  final void Function(BuildContext)? onTap;
  final bool isDivider;

  DrawerMenuItem({
    this.title,
    this.icon,
    this.route,
    this.onTap,
    this.isDivider = false,
  });
}

