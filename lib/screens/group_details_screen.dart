import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/models/expense_model.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fund_management_app/screens/add_members_to_group_screen.dart';
import 'package:fund_management_app/screens/add_expense_screen.dart';
import 'package:fund_management_app/services/auth_service.dart';
import 'package:fund_management_app/services/group_service.dart';
import 'package:intl/intl.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  bool _showFabOptions = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  String? _creatorUsername;
  late TabController _tabController;

  Map<String, String> _memberUsernames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCreatorUsername();
    _fetchMemberUsernames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCreatorUsername() async {
    final userModel = await _authService.getUserData(widget.group.creatorUid);
    if (mounted) {
      setState(() {
        _creatorUsername = userModel?.username ?? 'Unknown User';
      });
    }
  }

  Future<void> _fetchMemberUsernames() async {
    Map<String, String> fetchedUsernames = {};
    for (String memberEmail in widget.group.members) {
      String? username = await _authService.getUsernameByEmail(memberEmail);
      fetchedUsernames[memberEmail] = username ?? memberEmail.split('@')[0];
    }
    if (mounted) {
      setState(() {
        _memberUsernames = fetchedUsernames;
      });
    }
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

  void _toggleFabOptions() {
    setState(() {
      _showFabOptions = !_showFabOptions;
    });
  }

  Map<String, dynamic> _getCategoryIconAndColor(String categoryName) {
    return AppConstants.groupCategories
        .firstWhere(
          (cat) => cat['name'] == categoryName,
          orElse: () => {'name': 'Other', 'icon': Icons.category, 'color': AppColors.hintGrey},
        );
  }

  Map<String, dynamic> _getExpenseCategoryIconAndColor(String categoryName) {
    return AppConstants.expenseCategories
        .firstWhere(
          (cat) => cat['name'] == categoryName,
          orElse: () => {'name': 'Other', 'icon': Icons.category, 'color': AppColors.hintGrey},
        );
  }

  // NEW METHOD: _buildLoadingOrErrorGroupDetails
  Widget _buildLoadingOrErrorGroupDetails(GroupModel group, String? currentUserUid, bool isAdmin, Map<String, dynamic> categoryData, {dynamic error}) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Bar Section (simplified for error state)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              color: AppColors.primaryBackground,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
                    onPressed: () { Navigator.pop(context); },
                  ),
                  const SizedBox(width: 10),
                  Icon(categoryData['icon'], color: categoryData['color'], size: 38),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.groupName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Created by ${_creatorUsername ?? 'Loading...'}',
                          style: TextStyle(fontSize: 14, color: AppColors.hintGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_forever, color: isAdmin ? AppColors.errorRed : AppColors.hintGrey.withOpacity(0.5)),
                    onPressed: () { _showToast("Delete functionality (from error state)", AppColors.hintGrey); },
                    tooltip: isAdmin ? 'Delete group' : 'Only group admin can delete',
                  ),
                ],
              ),
            ),
            // Error/Loading Indicator
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      error != null ? Icons.error_outline : Icons.cloud_download,
                      size: 80,
                      color: error != null ? AppColors.errorRed : AppColors.hintGrey,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      error != null ? 'Error loading group: $error' : 'Loading group data...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: error != null ? AppColors.errorRed : AppColors.hintGrey,
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Please check your internet connection or Firebase rules.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: AppColors.hintGrey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Keep FAB for consistency, but might make it non-functional
      floatingActionButton: FloatingActionButton(
        onPressed: () { _showToast("Loading, please wait...", AppColors.hintGrey); },
        backgroundColor: AppColors.hintGrey,
        foregroundColor: AppColors.textLight,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = _auth.currentUser?.uid;
    final String? currentUserEmail = _auth.currentUser?.email;
    final bool isAdmin = currentUserUid == widget.group.creatorUid;
    final categoryData = _getCategoryIconAndColor(widget.group.groupCategory);

    // Calculate Group Total Balance - using a StreamBuilder for real-time updates
    return StreamBuilder<GroupModel>(
      stream: _groupService.getUsersGroups().map((groups) => groups.firstWhere(
            (g) => g.groupId == widget.group.groupId,
            orElse: () => widget.group, // Fallback to current group if not found (e.g., deleted)
          )),
      builder: (context, groupSnapshot) {
        // If the group data is still loading or has an error, show a fallback
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          // Changed to return the new method
          return _buildLoadingOrErrorGroupDetails(widget.group, currentUserUid, isAdmin, categoryData);
        }
        if (groupSnapshot.hasError || !groupSnapshot.hasData) {
          // Changed to return the new method with error details
          return _buildLoadingOrErrorGroupDetails(widget.group, currentUserUid, isAdmin, categoryData, error: groupSnapshot.error);
        }

        final GroupModel currentGroupState = groupSnapshot.data!;
        double groupTotalBalance = currentGroupState.memberBalances.values.fold(0.0, (sum, balance) => sum + balance);

        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Custom Top Bar Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                  color: AppColors.primaryBackground,
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 10),
                      // Category Icon
                      Icon(
                        categoryData['icon'],
                        color: categoryData['color'],
                        size: 38,
                      ),
                      const SizedBox(width: 15),
                      // Group Name and Creator
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentGroupState.groupName, // Use updated group state
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Created by ${_creatorUsername ?? 'Loading...'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.hintGrey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Delete Icon (remain on the right)
                      IconButton(
                        icon: Icon(
                          Icons.delete_forever,
                          color: isAdmin ? AppColors.errorRed : AppColors.hintGrey.withOpacity(0.5),
                          size: 28,
                        ),
                        onPressed: () {
                          if (isAdmin) {
                            _showToast("Delete group functionality not implemented yet.", AppColors.hintGrey);
                          } else {
                            _showToast('You are not the admin of this group and cannot delete it.', AppColors.errorRed);
                          }
                        },
                        tooltip: isAdmin ? 'Delete group' : 'Only group admin can delete',
                      ),
                    ],
                  ),
                ),
                // Group Total Balance Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  color: AppColors.cardBackground, // A distinct background for balance
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Total Balance:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.hintGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${groupTotalBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: groupTotalBalance >= 0 ? AppColors.successGreen : AppColors.errorRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10), // Space after balance box
                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.buttonShadow.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: AppColors.accentGreen,
                    ),
                    labelColor: AppColors.textDark,
                    unselectedLabelColor: AppColors.hintGrey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                    tabs: const [
                      Tab(text: 'Expense'),
                      Tab(text: 'Summary'),
                    ],
                  ),
                ),
                // Tab Bar View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Expense Tab Content
                      _buildExpenseTabContent(currentUserEmail),
                      // Summary Tab Content
                      _buildSummaryTabContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Add Expense Button
              AnimatedOpacity(
                opacity: _showFabOptions ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showFabOptions,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        if (_showFabOptions) {
                          _toggleFabOptions();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddExpenseScreen(group: currentGroupState), // Pass updated group state
                            ),
                          );
                        }
                      },
                      label: const Text('Add Expense', style: TextStyle(color: AppColors.textDark)),
                      icon: const Icon(Icons.add_shopping_cart, color: AppColors.textDark),
                      backgroundColor: AppColors.accentGreen,
                      heroTag: 'addExpenseFab',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ),
              // Add Members Button (only visible/tappable if current user is admin)
              if (isAdmin)
                AnimatedOpacity(
                  opacity: _showFabOptions ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showFabOptions,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          if (_showFabOptions) {
                            _toggleFabOptions();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddMembersToGroupScreen(group: currentGroupState), // Pass updated group state
                              ),
                            );
                          }
                        },
                        label: const Text('Add Members', style: TextStyle(color: AppColors.textDark)),
                        icon: const Icon(Icons.person_add, color: AppColors.textDark),
                        backgroundColor: AppColors.accentGreen,
                        heroTag: 'addMembersFab',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                ),
              // Main Plus FAB
              FloatingActionButton(
                onPressed: _toggleFabOptions,
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.textDark,
                heroTag: 'mainFab',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Icon(
                  _showFabOptions ? Icons.close : Icons.add,
                  size: 30,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseTabContent(String? currentUserEmail) {
    // ... (rest of this method remains unchanged, it already uses widget.group.groupId from the initially passed GroupModel)
    return StreamBuilder<List<ExpenseModel>>(
      stream: _groupService.getExpensesForGroup(widget.group.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentGreen));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading expenses: ${snapshot.error}', style: const TextStyle(color: AppColors.errorRed)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: AppColors.hintGrey.withOpacity(0.5)),
                const SizedBox(height: 20),
                const Text(
                  'No expenses yet. Click the + button to add one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.hintGrey),
                ),
              ],
            ),
          );
        }

        List<ExpenseModel> expenses = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final expenseCategoryData = _getExpenseCategoryIconAndColor(expense.category);

            String paidByName = _memberUsernames[expense.paidBy] ?? expense.paidBy.split('@')[0];

            String currentUserOwedStatus = '';
            Color currentUserOwedColor = AppColors.textDark;

            if (currentUserEmail == null) {
              currentUserOwedStatus = '';
              currentUserOwedColor = AppColors.textDark;
            } else if (expense.shares.containsKey(currentUserEmail)) {
              double share = expense.shares[currentUserEmail]!;
              if (share > 0) { // If the current user has a share (owes)
                 if (expense.paidBy == currentUserEmail) {
                   // If current user is also the payer, their net effect from this transaction.
                   // Balance decreased by full amount paid, then increased by their share.
                   // Net change: share - amount. If amount is greater than share, they are effectively owed.
                   // If share is greater than amount (e.g. they paid less than their share, or didn't pay but took part in split), they owe.
                   double netEffectForPayer = share - expense.amount;
                   if (netEffectForPayer < 0) {
                     currentUserOwedStatus = 'You are owed ₹${netEffectForPayer.abs().toStringAsFixed(2)}';
                     currentUserOwedColor = AppColors.successGreen;
                   } else if (netEffectForPayer > 0) {
                     currentUserOwedStatus = 'You paid but owe ₹${netEffectForPayer.abs().toStringAsFixed(2)}';
                     currentUserOwedColor = AppColors.errorRed;
                   } else {
                     currentUserOwedStatus = 'You paid exactly your share (settled)';
                     currentUserOwedColor = AppColors.hintGrey;
                   }
                 } else {
                   // Current user is not payer and owes a share
                   currentUserOwedStatus = 'You owe ₹${share.toStringAsFixed(2)}';
                   currentUserOwedColor = AppColors.errorRed;
                 }
              } else {
                currentUserOwedStatus = 'You are covered (owes ₹0.00)';
                currentUserOwedColor = AppColors.hintGrey;
              }
            } else {
              currentUserOwedStatus = 'Not involved';
              currentUserOwedColor = AppColors.hintGrey;
            }


            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          expenseCategoryData['icon'],
                          color: expenseCategoryData['color'],
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.description,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Category: ${expense.category}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.hintGrey.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yy').format(expense.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.hintGrey.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Paid by: $paidByName',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark.withOpacity(0.8),
                      ),
                    ),
                    // Display split details for each member
                    const SizedBox(height: 10),
                    const Text(
                      'Split Details:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expense.shares.length,
                      itemBuilder: (context, idx) {
                        String memberEmail = expense.shares.keys.elementAt(idx);
                        double shareAmount = expense.shares.values.elementAt(idx);
                        String memberDisplayName = _memberUsernames[memberEmail] ?? memberEmail.split('@')[0];

                        String splitText;
                        Color splitColor;

                        if (memberEmail == expense.paidBy) {
                            // Payer's perspective in pooled fund:
                            // They paid X amount from the pool, but their share is Y.
                            // Their balance directly reduces by Y.
                            // So, this just says they paid and their share was covered.
                            splitText = '$memberDisplayName paid ₹${expense.amount.toStringAsFixed(2)} (covered share: ₹${shareAmount.toStringAsFixed(2)})';
                            splitColor = AppColors.successGreen; // Or AppColors.textDark if neutral.
                        } else {
                            // Non-payer's perspective: their balance decreases by their share.
                            if (shareAmount > 0) {
                                splitText = '$memberDisplayName\'s pool share decreases by ₹${shareAmount.toStringAsFixed(2)}';
                                splitColor = AppColors.errorRed;
                            } else {
                                splitText = '$memberDisplayName\'s pool share is unchanged (owes ₹0.00)';
                                splitColor = AppColors.hintGrey;
                            }
                        }


                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Text(
                                '• $splitText',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: splitColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 20, color: AppColors.borderColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Status:',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentUserOwedStatus,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: currentUserOwedColor,
                          ),
                        ),
                      ],
                    ),
                    if (expense.billImageUrl != null && expense.billImageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              _showToast("Viewing bill image (not implemented)", AppColors.hintGrey);
                            },
                            child: Text(
                              'View Bill Image',
                              style: TextStyle(
                                color: AppColors.accentGreen,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart, size: 80, color: AppColors.hintGrey.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            'Summary Pie Chart (Category-wise) will be displayed here!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.hintGrey),
          ),
        ],
      ),
    );
  }
}