import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/master_provider.dart';
import '../../providers/purchase_request_provider.dart';
import '../../providers/team_leader_provider.dart';
import '../../models/purchase_item_model.dart';
import '../../models/dropdown_model.dart';
import '../../models/supplier_model.dart';
import '../../widgets/dropdown_field.dart';
import '../../widgets/item_row_widget.dart';
import '../../widgets/shimmer_loader.dart';
import '../../services/auth_service.dart';

class PurchaseRequestCreateScreen extends StatefulWidget {
  const PurchaseRequestCreateScreen({super.key});

  @override
  State<PurchaseRequestCreateScreen> createState() => _PurchaseRequestCreateScreenState();
}

class _PurchaseRequestCreateScreenState extends State<PurchaseRequestCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset form when screen is opened
      final purchaseProvider = Provider.of<PurchaseRequestProvider>(context, listen: false);
      purchaseProvider.reset();
      _loadMasterData();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterData() async {
    final masterProvider = Provider.of<MasterProvider>(context, listen: false);
    print('=== _loadMasterData called ===');
    print('PRC 44 masterProvider.roles.isEmpty: ${masterProvider.roles.isEmpty}');
    print('masterProvider.vendorTypes.length: ${masterProvider.vendorTypes.length}');
    print('masterProvider.suppliers.length: ${masterProvider.suppliers.length}');
    
    if (masterProvider.roles.isEmpty) {
      print('Loading master data from API...');
      await masterProvider.loadAllMasterData();
      print('Master data loaded!');
      print('PRC 52 vendorTypes after load: ${masterProvider.vendorTypes.length}');
      print('suppliers after load: ${masterProvider.suppliers.length}');
      print('purchaseModes after load: ${masterProvider.purchaseModes.length}');
      print('priorities after load: ${masterProvider.priorities.length}');
    } else {
      print('Master data already loaded, skipping API call');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final purchaseProvider = Provider.of<PurchaseRequestProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: purchaseProvider.requiredByDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      purchaseProvider.setRequiredByDate(picked);
    }
  }

  void _showAddItemBottomSheet() {
    final purchaseProvider = Provider.of<PurchaseRequestProvider>(context, listen: false);
    purchaseProvider.addItem();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<PurchaseRequestProvider>(
                  builder: (context, provider, child) {
                    final lastIndex = provider.items.length - 1;
                    if (lastIndex < 0) return const SizedBox();
                    
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: ItemRowWidget(
                        index: lastIndex,
                        item: provider.items[lastIndex],
                        onUpdate: (item) {
                          provider.updateItem(lastIndex, item);
                        },
                        onRemove: () {
                          provider.removeItem(lastIndex);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    print('=== Form Submission Started ===');
    
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed (UI level)');
      return;
    }
    print('✅ Form validation passed (UI level)');

    final purchaseProvider = Provider.of<PurchaseRequestProvider>(context, listen: false);
    purchaseProvider.setDescription(_notesController.text);
    
    // Get client_id from user
    final authService = Provider.of<AuthService>(context, listen: false);
    final clientId = authService.user?.id;
    
    if (clientId == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('User not authenticated. Please login again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Print form data before submission
    print('=== Form Data Before Submission ===');
    print('Client ID: $clientId');
    print('Vendor Type: ${purchaseProvider.vendorType}');
    print('Vendor ID: ${purchaseProvider.vendorId}');
    print('Vendor Name: ${purchaseProvider.vendorName}');
    print('Purchase Mode ID: ${purchaseProvider.purchaseModeId}, Key: ${purchaseProvider.purchaseMode}');
    print('Priority ID: ${purchaseProvider.priorityId}, Key: ${purchaseProvider.priority}');
    print('Payment Option ID: ${purchaseProvider.paymentOptionId}, Key: ${purchaseProvider.paymentOption}');
    print('Site ID: ${purchaseProvider.siteId}');
    print('Description: ${purchaseProvider.description}');
    print('Items count: ${purchaseProvider.items.length}');
    for (int i = 0; i < purchaseProvider.items.length; i++) {
      final item = purchaseProvider.items[i];
      print('  Item ${i + 1}: itemId=${item.itemId}, qty=${item.qtyRequired}, price=${item.unitPrice}, gst=${item.gstPercent}');
    }

    final result = await purchaseProvider.submit(clientId: clientId);
    
    print('=== Submission Result ===');
    print('Success: ${result['success']}');
    print('Message: ${result['message']}');
    if (result.containsKey('errors')) {
      print('Errors: ${result['errors']}');
    }

    if (!mounted) return;

    if (result['success'] == true) {
      // Reset form after successful submission
      final purchaseProvider = Provider.of<PurchaseRequestProvider>(context, listen: false);
      purchaseProvider.reset();
      _notesController.clear();
      
      // Refresh the purchase request list so new request appears
      try {
        final teamLeaderProvider = Provider.of<TeamLeaderProvider>(context, listen: false);
        // Force reload to get the new request
        teamLeaderProvider.loadPurchaseRequests(forceReload: true);
        print('✅ Refreshed purchase request list after creation');
      } catch (e) {
        print('⚠️ Could not refresh purchase request list: $e');
      }
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Success'),
            ],
          ),
          content: const Text('Purchase request created successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Navigate back
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show error dialog with detailed error information
      String errorMessage = result['message'] ?? 'Failed to create purchase request';
      
      // Check if there are validation errors from the API
      if (result.containsKey('errors') && result['errors'] != null) {
        final errors = result['errors'];
        if (errors is Map) {
          // Format Laravel validation errors
          final errorList = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorList.addAll(value.map((e) => '$key: $e'));
            } else {
              errorList.add('$key: $value');
            }
          });
          if (errorList.isNotEmpty) {
            errorMessage = 'Validation Failed:\n${errorList.join('\n')}';
          }
        } else if (errors is List) {
          errorMessage = 'Validation Failed:\n${errors.join('\n')}';
        }
      }
      
      print('Showing error dialog: $errorMessage');
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Error'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(errorMessage),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Purchase Request'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MasterProvider>(
        builder: (context, masterProvider, child) {
          if (masterProvider.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerLoader(),
            );
          }

          if (masterProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    masterProvider.error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => masterProvider.loadAllMasterData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General Fields Section
                  const Text(
                    'General Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Vendor Type
                  Consumer<PurchaseRequestProvider>(
                    builder: (context, purchaseProvider, child) {
                      print('=== Building Vendor Type Dropdown ===');
                      print('masterProvider json: ${masterProvider}');
                      print('masterProvider.vendorTypes.length: ${masterProvider.vendorTypes.length}');
                      print('purchaseProvider.vendorType: ${purchaseProvider.vendorType}');
                      
                      if (masterProvider.vendorTypes.isNotEmpty) {
                        print('Available vendor types:');
                        for (var vt in masterProvider.vendorTypes) {
                          print('  - id: ${vt.id}, name: ${vt.name}, value: ${vt.value}');
                        }
                      } else {
                        print('⚠️ WARNING: vendorTypes list is EMPTY!');
                      }
                      
                      DropdownModel? selectedVendorType;
                      if (purchaseProvider.vendorType != null && purchaseProvider.vendorType!.isNotEmpty && masterProvider.vendorTypes.isNotEmpty) {
                        try {
                          // Match by value (key) first, then by name
                          selectedVendorType = masterProvider.vendorTypes.firstWhere(
                            (vt) => (vt.value != null && vt.value == purchaseProvider.vendorType) ||
                                    vt.name == purchaseProvider.vendorType,
                          );
                          print('✅ Selected vendor type found: ${selectedVendorType.name} (value: ${selectedVendorType.value})');
                        } catch (e) {
                          print('⚠️ Could not find selected vendor type: $e');
                          selectedVendorType = null;
                        }
                      }
                      
                      return Column(
                        children: [
                          DropdownField<DropdownModel>(
                            key: ValueKey('vendor_type_${purchaseProvider.vendorType}_${selectedVendorType?.id}'),
                            label: 'Vendor Type',
                            value: selectedVendorType,
                            items: masterProvider.vendorTypes,
                            onChanged: (value) {
                              print('Vendor type changed to: ${value?.name} (value: ${value?.value}, id: ${value?.id})');
                              // Store the value/key, not the ID
                              final vendorTypeKey = value?.value ?? value?.name ?? '';
                              purchaseProvider.setVendorType(vendorTypeKey);
                              // Clear vendor_id and vendor_name when type changes
                              // Don't clear vendor_id if switching between Registered (ID: 1) and Other (ID: 2)
                              if (value?.id != 1 && value?.id != 2) {
                                purchaseProvider.setVendorId(null);
                              }
                              if (value?.id != 2) {
                                purchaseProvider.setVendorName(null);
                              }
                              print('✅ Provider vendorType after set: ${purchaseProvider.vendorType}');
                            },
                            validator: (value) {
                              if (purchaseProvider.vendorType == null || purchaseProvider.vendorType!.isEmpty) {
                                if (value == null) {
                                  return 'Please select vendor type';
                                }
                              }
                              return null;
                            },
                            isRequired: true,
                          ),
                          // Show vendor name field if vendor_type is 'other' (ID: 2)
                          // Find selected vendor type to check ID
                          if (selectedVendorType != null && selectedVendorType.id == 2) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Vendor Name *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                purchaseProvider.setVendorName(value);
                              },
                              validator: (value) {
                                if (selectedVendorType?.id == 2 && (value == null || value.isEmpty)) {
                                  return 'Please enter vendor name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Vendor (Supplier) - Show if vendor_type is 'registered' (ID: 1) or 'other' (ID: 2)
                  Consumer<PurchaseRequestProvider>(
                    builder: (context, purchaseProvider, child) {
                      // Find the selected vendor type to get its ID
                      DropdownModel? selectedVendorType;
                      if (purchaseProvider.vendorType != null && purchaseProvider.vendorType!.isNotEmpty && masterProvider.vendorTypes.isNotEmpty) {
                        try {
                          selectedVendorType = masterProvider.vendorTypes.firstWhere(
                            (vt) => (vt.value != null && vt.value == purchaseProvider.vendorType) ||
                                    vt.name == purchaseProvider.vendorType,
                          );
                        } catch (e) {
                          selectedVendorType = null;
                        }
                      }
                      
                      // Show Supplier dropdown if vendor type ID is 1 (Registered) or 2 (Other)
                      if (selectedVendorType == null || (selectedVendorType.id != 1 && selectedVendorType.id != 2)) {
                        return const SizedBox.shrink();
                      }
                      
                      SupplierModel? selectedSupplier;
                      if (purchaseProvider.vendorId != null && masterProvider.suppliers.isNotEmpty) {
                        try {
                          selectedSupplier = masterProvider.suppliers.firstWhere(
                            (s) => s.id == purchaseProvider.vendorId,
                          );
                        } catch (e) {
                          selectedSupplier = null;
                        }
                      }
                      
                      return DropdownField<SupplierModel>(
                        key: ValueKey('vendor_${purchaseProvider.vendorId}_${selectedSupplier?.id}'),
                        label: 'Vendor *',
                        value: selectedSupplier,
                        items: masterProvider.suppliers,
                        onChanged: (value) {
                          purchaseProvider.setVendorId(value?.id);
                        },
                        validator: (value) {
                          // Check if vendor type ID is 1 (Registered) or 2 (Other) and vendor_id is required
                          if ((selectedVendorType?.id == 1 || selectedVendorType?.id == 2) && purchaseProvider.vendorId == null) {
                            if (value == null) {
                              return 'Please select vendor';
                            }
                          }
                          return null;
                        },
                        isRequired: true,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Purchase Mode
                      Expanded(
                        child: Consumer<PurchaseRequestProvider>(
                          builder: (context, purchaseProvider, child) {
                            DropdownModel? selectedPurchaseMode;
                            if (purchaseProvider.purchaseModeId != null && masterProvider.purchaseModes.isNotEmpty) {
                              try {
                                selectedPurchaseMode = masterProvider.purchaseModes.firstWhere(
                                  (pm) => pm.id == purchaseProvider.purchaseModeId,
                                );
                              } catch (e) {
                                selectedPurchaseMode = null;
                              }
                            }
                            
                            return DropdownField<DropdownModel>(
                              key: ValueKey('purchase_mode_${purchaseProvider.purchaseModeId}_${purchaseProvider.purchaseMode}_${selectedPurchaseMode?.id}'),
                              label: 'Purchase Mode',
                              value: selectedPurchaseMode,
                              items: masterProvider.purchaseModes,
                              onChanged: (value) {
                                // Only set the ID - the key is not needed if we have the ID
                                purchaseProvider.setPurchaseModeId(value?.id);
                                print('✅ Purchase mode set: ID=${value?.id}, Key=${value?.value ?? value?.name}');
                              },
                              validator: (value) {
                                if (purchaseProvider.purchaseModeId == null && (purchaseProvider.purchaseMode == null || purchaseProvider.purchaseMode!.isEmpty)) {
                                  if (value == null) {
                                    return 'Required';
                                  }
                                }
                                return null;
                              },
                              isRequired: true,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Priority
                      Expanded(
                        child: Consumer<PurchaseRequestProvider>(
                          builder: (context, purchaseProvider, child) {
                            DropdownModel? selectedPriority;
                            // Try to find by ID first, then by key
                            if (purchaseProvider.priorityId != null && masterProvider.priorities.isNotEmpty) {
                              try {
                                selectedPriority = masterProvider.priorities.firstWhere(
                                  (p) => p.id == purchaseProvider.priorityId,
                                );
                              } catch (e) {
                                selectedPriority = null;
                              }
                            } else if (purchaseProvider.priority != null && purchaseProvider.priority!.isNotEmpty && masterProvider.priorities.isNotEmpty) {
                              try {
                                selectedPriority = masterProvider.priorities.firstWhere(
                                  (p) => (p.value != null && p.value == purchaseProvider.priority) ||
                                         p.name == purchaseProvider.priority,
                                );
                              } catch (e) {
                                selectedPriority = null;
                              }
                            }
                            
                            return DropdownField<DropdownModel>(
                              key: ValueKey('priority_${purchaseProvider.priorityId}_${purchaseProvider.priority}_${selectedPriority?.id}'),
                              label: 'Priority',
                              value: selectedPriority,
                              items: masterProvider.priorities,
                              onChanged: (value) {
                                // Only set the ID - the key is not needed if we have the ID
                                purchaseProvider.setPriorityId(value?.id);
                                print('✅ Priority set: ID=${value?.id}, Key=${value?.value ?? value?.name}');
                              },
                              validator: (value) {
                                if (purchaseProvider.priorityId == null && (purchaseProvider.priority == null || purchaseProvider.priority!.isEmpty)) {
                                  if (value == null) {
                                    return 'Required';
                                  }
                                }
                                return null;
                              },
                              isRequired: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment Option
                  Consumer<PurchaseRequestProvider>(
                    builder: (context, purchaseProvider, child) {
                      DropdownModel? selectedPaymentOption;
                      // Try to find by ID first, then by key
                      if (purchaseProvider.paymentOptionId != null && masterProvider.paymentOptions.isNotEmpty) {
                        try {
                          selectedPaymentOption = masterProvider.paymentOptions.firstWhere(
                            (po) => po.id == purchaseProvider.paymentOptionId,
                          );
                        } catch (e) {
                          selectedPaymentOption = null;
                        }
                      } else if (purchaseProvider.paymentOption != null && purchaseProvider.paymentOption!.isNotEmpty && masterProvider.paymentOptions.isNotEmpty) {
                        try {
                          selectedPaymentOption = masterProvider.paymentOptions.firstWhere(
                            (po) => (po.value != null && po.value == purchaseProvider.paymentOption) ||
                                    po.name == purchaseProvider.paymentOption,
                          );
                        } catch (e) {
                          selectedPaymentOption = null;
                        }
                      }
                      
                      return DropdownField<DropdownModel>(
                        key: ValueKey('payment_option_${purchaseProvider.paymentOptionId}_${purchaseProvider.paymentOption}_${selectedPaymentOption?.id}'),
                        label: 'Payment Option',
                        value: selectedPaymentOption,
                        items: masterProvider.paymentOptions,
                        onChanged: (value) {
                          // Only set the ID - the key is not needed if we have the ID
                          purchaseProvider.setPaymentOptionId(value?.id);
                          print('✅ Payment option set: ID=${value?.id}, Key=${value?.value ?? value?.name}');
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Select Site
                  Consumer<PurchaseRequestProvider>(
                    builder: (context, purchaseProvider, child) {
                      DropdownModel? selectedSite;
                      if (purchaseProvider.siteId != null && masterProvider.plants.isNotEmpty) {
                        try {
                          selectedSite = masterProvider.plants.firstWhere(
                            (p) => p.id == purchaseProvider.siteId,
                          );
                        } catch (e) {
                          selectedSite = null;
                        }
                      }
                      
                      return DropdownField<DropdownModel>(
                        key: ValueKey('site_${purchaseProvider.siteId}_${selectedSite?.id}'),
                        label: 'Select Site',
                        value: selectedSite,
                        items: masterProvider.plants,
                        onChanged: (value) {
                          purchaseProvider.setSiteId(value?.id);
                          print('✅ Site set: ${value?.id}');
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Required By Date
                  Consumer<PurchaseRequestProvider>(
                    builder: (context, provider, child) {
                      return InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Required By Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            provider.requiredByDate != null
                                ? DateFormat('yyyy-MM-dd').format(provider.requiredByDate!)
                                : 'Select date',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    onChanged: (value) {
                      Provider.of<PurchaseRequestProvider>(context, listen: false)
                          .setDescription(value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Items Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddItemBottomSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Items List
                  Consumer<PurchaseRequestProvider>(
                    builder: (context, provider, child) {
                      if (provider.items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No items added. Click "Add Item" to add items.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: List.generate(provider.items.length, (index) {
                          return ItemRowWidget(
                            index: index,
                            item: provider.items[index],
                            onUpdate: (item) {
                              provider.updateItem(index, item);
                            },
                            onRemove: () {
                              provider.removeItem(index);
                            },
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  Consumer<PurchaseRequestProvider>(
                    builder: (context, provider, child) {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: provider.isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: provider.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Submit Purchase Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

