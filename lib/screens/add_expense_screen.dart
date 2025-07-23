import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:fund_management_app/widgets/custom_text_field.dart';

enum SplitType { equally, unequally }

class AddExpenseScreen extends StatefulWidget {
  final GroupModel group;

  const AddExpenseScreen({super.key, required this.group});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = AppConstants.expenseCategories[0]['name'];
  DateTime _selectedDate = DateTime.now();
  SplitType _splitType = SplitType.equally;
  List<String> _selectedMembersForUnequalSplit = [];
  File? _billImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _selectedMembersForUnequalSplit.addAll(widget.group.members);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _showToast(String message, Color backgroundColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: AppColors.textLight,
      fontSize: 16.0,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.accentGreen,
              onPrimary: AppColors.textDark,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textDark,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _billImage = File(image.path);
        });
        _showToast("Bill image selected!", AppColors.successGreen);
      }
    } catch (e) {
      _showToast("Failed to pick image: $e", AppColors.errorRed);
    }
  }

  Map<String, dynamic> _getCategoryIconAndColor(String categoryName, List<Map<String, dynamic>> categoriesList) {
    return categoriesList.firstWhere(
          (cat) => cat['name'] == categoryName,
          orElse: () => {'name': 'Other', 'icon': Icons.category, 'color': AppColors.hintGrey},
        );
  }

  void _addExpense() {
    if (_formKey.currentState!.validate()) {
      if (double.tryParse(_amountController.text) == null || double.parse(_amountController.text) <= 0) {
        _showToast("Please enter a valid amount.", AppColors.errorRed);
        return;
      }

      if (_splitType == SplitType.unequally && _selectedMembersForUnequalSplit.isEmpty) {
        _showToast("Please select at least one member for unequal split.", AppColors.errorRed);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      String splitDetails = '';
      if (_splitType == SplitType.equally) {
        splitDetails = 'Equally among all members.';
      } else {
        splitDetails = 'Unequally among: ${_selectedMembersForUnequalSplit.join(', ')}. ';
        double amount = double.parse(_amountController.text);
        if (_selectedMembersForUnequalSplit.isNotEmpty) {
          double splitAmount = amount / _selectedMembersForUnequalSplit.length;
          splitDetails += 'Each gets: ₹${splitAmount.toStringAsFixed(2)}.';
        }
      }

      _showToast(
        'Expense Added!\n'
            'Description: ${_descriptionController.text}\n'
            'Amount: ₹${_amountController.text}\n'
            'Date: ${_dateController.text}\n'
            'Category: $_selectedCategory\n'
            'Split: $splitDetails\n'
            'Bill Image: ${_billImage != null ? "Yes" : "No"}',
        AppColors.successGreen,
      );

      setState(() {
        _isLoading = false;
        // Optionally clear fields after adding
      });
      // TODO: Implement actual expense storage to Firestore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Description
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Description',
                    style: TextStyle(color: AppColors.textDark.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Enter a description',
                  hintText: 'e.g., Dinner with friends',
                  enabled: true,
                  readOnly: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description cannot be empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Amount
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Amount',
                    style: TextStyle(color: AppColors.textDark.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _amountController,
                  labelText: 'Enter amount',
                  hintText: 'e.g., 500',
                  keyboardType: TextInputType.number,
                  enabled: true,
                  readOnly: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount cannot be empty.';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number.';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Date',
                    style: TextStyle(color: AppColors.textDark.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _dateController,
                  labelText: 'Select Date',
                  hintText: 'DD/MM/YYYY',
                  enabled: true,
                  readOnly: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, color: AppColors.hintGrey),
                    onPressed: () => _selectDate(context),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Date cannot be empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Category',
                    style: TextStyle(color: AppColors.textDark.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.expenseCategories.length,
                    itemBuilder: (context, index) {
                      final category = AppConstants.expenseCategories[index];
                      final categoryIconColor = _getCategoryIconAndColor(category['name'], AppConstants.expenseCategories);

                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ChoiceChip(
                          label: Text(category['name']),
                          selected: _selectedCategory == category['name'],
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategory = category['name'];
                              }
                            });
                          },
                          selectedColor: (categoryIconColor['color'] as Color).withOpacity(0.3),
                          backgroundColor: AppColors.textLight,
                          labelStyle: TextStyle(
                            color: _selectedCategory == category['name']
                                ? AppColors.textDark
                                : AppColors.hintGrey,
                            fontWeight: _selectedCategory == category['name']
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          avatar: Icon(
                            category['icon'],
                            color: _selectedCategory == category['name']
                                ? AppColors.textDark
                                : (categoryIconColor['color'] as Color),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: BorderSide(
                              color: _selectedCategory == category['name']
                                  ? (categoryIconColor['color'] as Color)
                                  : AppColors.borderColor,
                              width: 1.5,
                            ),
                          ),
                          elevation: 2,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Split Options (Changed from RadioListTile to segmented control)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Split Type',
                    style: TextStyle(color: AppColors.textDark.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.buttonShadow.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _splitType = SplitType.equally;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _splitType == SplitType.equally
                                  ? AppColors.accentGreen.withOpacity(0.7)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Equally',
                              style: TextStyle(
                                color: _splitType == SplitType.equally ? AppColors.textDark : AppColors.hintGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _splitType = SplitType.unequally;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _splitType == SplitType.unequally
                                  ? AppColors.accentGreen.withOpacity(0.7)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Unequally',
                              style: TextStyle(
                                color: _splitType == SplitType.unequally ? AppColors.textDark : AppColors.hintGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Member List for Unequal Split
                if (_splitType == SplitType.unequally) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Members for Unequal Split',
                      style: TextStyle(color: AppColors.textDark.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.textLight,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.buttonShadow.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.group.members.length,
                      itemBuilder: (context, index) {
                        final memberEmail = widget.group.members[index];
                        return CheckboxListTile(
                          title: Text(memberEmail, style: const TextStyle(color: AppColors.textDark)),
                          value: _selectedMembersForUnequalSplit.contains(memberEmail),
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedMembersForUnequalSplit.add(memberEmail);
                              } else {
                                _selectedMembersForUnequalSplit.remove(memberEmail);
                              }
                            });
                          },
                          activeColor: AppColors.accentGreen,
                          checkColor: AppColors.textDark,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Upload Bill Image
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Upload Bill Image (Optional)',
                    style: TextStyle(color: AppColors.textDark.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: 'Pick Image',
                  onPressed: _pickImage,
                  backgroundColor: AppColors.textLight,
                  textColor: AppColors.textDark,
                ),
                if (_billImage != null) ...[
                  const SizedBox(height: 15),
                  Center(
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _billImage!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _billImage = null;
                            });
                            _showToast("Image removed.", AppColors.hintGrey);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.errorRed,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: AppColors.textLight, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),

                // Add Expense Button
                CustomButton(
                  text: 'Add Expense',
                  onPressed: _addExpense,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}