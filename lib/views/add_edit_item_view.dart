import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../viewmodels/inventory_viewmodel.dart';

const Color primaryColor = Color(0xFFFF8A00); // pleasant warm orange

class AddEditItemView extends StatefulWidget {
  final ItemModel? item;

  const AddEditItemView({Key? key, this.item}) : super(key: key);

  @override
  State<AddEditItemView> createState() => _AddEditItemViewState();
}

class _AddEditItemViewState extends State<AddEditItemView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _lowStockController;
  DateTime? _selectedDate;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(
      text: widget.item?.price.toStringAsFixed(2) ?? '0.00',
    );
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '1',
    );
    _lowStockController = TextEditingController(
      text: widget.item?.lowStock.toString() ?? '5',
    );
    _selectedDate = widget.item?.expiry ?? DateTime.now().add(Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Milk, Bread, etc.',
                  prefixIcon: Icon(Icons.label, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Enter item name';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price *',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Enter price';
                  final price = double.tryParse(value!);
                  if (price == null) return 'Enter valid number';
                  if (price < 0) return 'Price must be >= 0';
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        prefixIcon: Icon(Icons.inventory, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor.withOpacity(0.25)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Enter quantity';
                        final qty = int.tryParse(value!);
                        if (qty == null) return 'Enter valid number';
                        if (qty < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lowStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Low Stock Alert *',
                        prefixIcon: Icon(Icons.warning, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor.withOpacity(0.25)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Enter threshold';
                        final val = int.tryParse(value!);
                        if (val == null) return 'Enter valid number';
                        if (val < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date *',
                    prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? dateFormat.format(_selectedDate!)
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '* Required fields',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 32),
              Consumer<InventoryViewModel>(
                builder: (context, inventoryVM, _) {
                  if (inventoryVM.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          inventoryVM.error!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
              Consumer<InventoryViewModel>(
                builder: (context, inventoryVM, _) {
                  return ElevatedButton(
                    onPressed: inventoryVM.isLoading ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: inventoryVM.isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isEditing ? Icons.save : Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          isEditing ? 'Update Item' : 'Add Item',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an expiry date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final item = ItemModel(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text),
      expiry: _selectedDate!,
      quantity: int.parse(_quantityController.text),
      lowStock: int.parse(_lowStockController.text),
    );

    final inventoryVM = context.read<InventoryViewModel>();
    bool success;

    if (isEditing && item.id != null) {
      success = await inventoryVM.updateItem(item.id!, item);
    } else {
      success = await inventoryVM.addItem(item);
    }

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(isEditing ? 'Item updated successfully' : 'Item added successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }
}