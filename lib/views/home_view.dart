import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/inventory_viewmodel.dart';
import '../models/item_model.dart';
import 'add_edit_item_view.dart';

const Color primaryColor = Color(0xFFFF8A00); // consistent orange theme

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryViewModel>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<InventoryViewModel>().loadItems(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthViewModel>().logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<InventoryViewModel>(
        builder: (context, inventoryVM, _) {
          if (inventoryVM.isLoading && inventoryVM.items.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (inventoryVM.error != null && inventoryVM.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading items',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      inventoryVM.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => inventoryVM.loadItems(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (inventoryVM.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No items yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first item',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () => inventoryVM.loadItems(),
            child: Column(
              children: [
                // Alert Summary Cards
                if (inventoryVM.expiredItems.isNotEmpty ||
                    inventoryVM.expiringItems.isNotEmpty ||
                    inventoryVM.lowStockItems.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (inventoryVM.expiredItems.isNotEmpty)
                          _buildAlertCard(
                            'Expired Items',
                            inventoryVM.expiredItems.length.toString(),
                            Colors.red,
                            Icons.error,
                          ),
                        if (inventoryVM.expiringItems.isNotEmpty)
                          _buildAlertCard(
                            'Expiring Soon',
                            inventoryVM.expiringItems.length.toString(),
                            Colors.orange,
                            Icons.warning,
                          ),
                        if (inventoryVM.lowStockItems.isNotEmpty)
                          _buildAlertCard(
                            'Low Stock',
                            inventoryVM.lowStockItems.length.toString(),
                            Colors.blue,
                            Icons.inventory_2,
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: inventoryVM.items.length,
                    itemBuilder: (context, index) {
                      final item = inventoryVM.items[index];
                      return ItemCard(
                        item: item,
                        onTap: () => _editItem(context, item),
                        onDelete: () => _deleteItem(context, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItem(context),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget _buildAlertCard(String title, String count, Color color, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _addItem(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditItemView()),
    );
    if (result == true) {
      context.read<InventoryViewModel>().loadItems();
    }
  }

  void _editItem(BuildContext context, ItemModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditItemView(item: item)),
    );
    if (result == true) {
      context.read<InventoryViewModel>().loadItems();
    }
  }

  void _deleteItem(BuildContext context, ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Item'),
          ],
        ),
        content: Text('Are you sure you want to delete "${item.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (item.id != null) {
                final success = await context.read<InventoryViewModel>().deleteItem(item.id!);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    Color statusColor = Colors.green;
    String statusText = 'Good';
    IconData statusIcon = Icons.check_circle;

    if (item.hasExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.error;
    }else if (item.isExpiringSoon && item.isLowOnStock) {
      statusColor = Colors.deepPurple;
      statusText = 'Critical : Expiring Soon and Is low on Stock';
      statusIcon = Icons.warning;
    }else if (item.isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = 'Expiring Soon';
      statusIcon = Icons.warning;
    } else if (item.isLowOnStock) {
      statusColor = Colors.redAccent;
      statusText = 'Low Stock';
      statusIcon = Icons.inventory_2;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  // Use a safe formatter that accepts numeric or string prices
                  Text(
                    'Price: ${_formatPrice(item.price)}',
                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Expires: ${dateFormat.format(item.expiry)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  if (item.daysRemaining != null)
                    Text(
                      ' (${item.daysRemaining} days)',
                      style: TextStyle(
                        color: item.isExpiringSoon ? Colors.orange : Colors.grey,
                        fontWeight: item.isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Quantity: ${item.quantity}',
                    style: TextStyle(
                      color: item.isLowOnStock ? Colors.orange : Colors.grey[700],
                      fontWeight: item.isLowOnStock ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (item.isLowOnStock)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Text(
                          'LOW STOCK (≤${item.lowStock})',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (item.inStock != null)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.inStock! ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: item.inStock! ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 4),
                      Text(
                        item.inStock! ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color: item.inStock! ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Safe price formatting: accepts num or numeric String and returns a currency string
  String _formatPrice(dynamic price) {
    try {
      double value;
      if (price == null) {
        value = 0.0;
      } else if (price is num) {
        value = price.toDouble();
      } else if (price is String) {
        value = double.tryParse(price) ?? 0.0;
      } else {
        // fallback for unexpected types
        value = 0.0;
      }
      // Use intl for consistent currency formatting with two decimals
      return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
    } catch (_) {
      return '\$0.00';
    }
  }
}