class ItemModel {
  final int? id;
  final String name;
  final double price;
  final DateTime? added;
  final DateTime expiry;
  final int quantity;
  final int lowStock;
  final bool? inStock;
  final int? daysRemaining;
  final bool? isExpired;

  ItemModel({
    this.id,
    required this.name,
    required this.price,
    this.added,
    required this.expiry,
    required this.quantity,
    required this.lowStock,
    this.inStock,
    this.daysRemaining,
    this.isExpired,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'] ?? '',
      price: double.parse(json['price']?.toString() ?? '0'),
      added: json['added'] != null ? DateTime.parse(json['added']) : null,
      expiry: DateTime.parse(json['expiry']),
      quantity: json['quantity'] ?? 0,
      lowStock: json['low_stock'] ?? 5,
      inStock: json['in_stock'],
      daysRemaining: json['days_remaining'],
      isExpired: json['is_expired'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price.toString(),
      'expiry': '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}',
      'quantity': quantity,
      'low_stock': lowStock,
    };
  }

  bool get isExpiringSoon {
    final days = daysRemaining ?? expiry.difference(DateTime.now()).inDays;
    return days <= 7 && days >= 0;
  }

  bool get hasExpired {
    return isExpired ?? expiry.isBefore(DateTime.now());
  }

  bool get isLowOnStock {
    return quantity <= lowStock;
  }
}
