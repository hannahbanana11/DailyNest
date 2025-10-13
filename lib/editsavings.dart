import 'package:flutter/material.dart';
import 'package:dailynest/savings.dart';

class EditSavings extends StatefulWidget {
  static const String id = "EditSavings";
  final int entryIndex;
  final Map<String, dynamic> existingEntry;

  const EditSavings({
    super.key,
    required this.entryIndex,
    required this.existingEntry,
  });

  @override
  State<EditSavings> createState() => _EditSavingsState();
}

class _EditSavingsState extends State<EditSavings> {
  final List<Map<String, dynamic>> _entries = [];
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    // Load existing transactions
    for (var transaction in widget.existingEntry['transactions']) {
      _entries.add({
        'time': transaction['time'],
        'deposit': TextEditingController(text: transaction['deposit']),
        'withdraw': TextEditingController(text: transaction['withdraw']),
        'balance': transaction['balance'],
      });
    }
    _totalBalance = widget.existingEntry['totalBalance'];
  }

  void _addNewRow() {
    setState(() {
      _entries.add({
        'time': '',
        'deposit': TextEditingController(),
        'withdraw': TextEditingController(),
        'balance': 0.0,
      });
    });
  }

  void _calculateBalance(int index) {
    setState(() {
      // Calculate running balance
      double runningBalance = 0.0;
      for (int i = 0; i <= index; i++) {
        final entryDeposit = double.tryParse(_entries[i]['deposit'].text) ?? 0.0;
        final entryWithdraw = double.tryParse(_entries[i]['withdraw'].text) ?? 0.0;
        runningBalance += entryDeposit - entryWithdraw;
        _entries[i]['balance'] = runningBalance;
        
        // Set time when balance is calculated
        if ((entryDeposit > 0 || entryWithdraw > 0) && _entries[i]['time'].isEmpty) {
          final now = DateTime.now();
          _entries[i]['time'] = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        }
      }
      
      _totalBalance = runningBalance;
    });
  }

  void _removeRow(int index) {
    setState(() {
      _entries[index]['deposit'].dispose();
      _entries[index]['withdraw'].dispose();
      _entries.removeAt(index);
      
      // Recalculate all balances
      if (_entries.isNotEmpty) {
        for (int i = 0; i < _entries.length; i++) {
          _calculateBalance(i);
        }
      } else {
        _totalBalance = 0.0;
      }
    });
  }

  @override
  void dispose() {
    for (var entry in _entries) {
      entry['deposit'].dispose();
      entry['withdraw'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // DailyNest Title
                const Text(
                  "DailyNest",
                  style: TextStyle(
                    color: Color(0xFFFF9E4D),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Edit Savings subtitle
                const Text(
                  "Edit Savings",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Date
                Text(
                  widget.existingEntry['date'],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Table Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9E4D),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 2, child: Text('Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Deposit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Withdraw', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        
                        // Table Body
                        Expanded(
                          child: ListView.builder(
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Time Column (Not Editable)
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          _entries[index]['time'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    
                                    // Deposit Column (Editable)
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _entries[index]['deposit'],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.all(8),
                                          hintText: '0.00',
                                        ),
                                        onChanged: (value) => _calculateBalance(index),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 8),
                                    
                                    // Withdraw Column (Editable)
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _entries[index]['withdraw'],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.all(8),
                                          hintText: '0.00',
                                        ),
                                        onChanged: (value) => _calculateBalance(index),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 8),
                                    
                                    // Balance Column (Not Editable)
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          _entries[index]['balance'].toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                    
                                    // Delete Button
                                    Expanded(
                                      flex: 1,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                        onPressed: () => _removeRow(index),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Total Balance
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Balance:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _totalBalance.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF9E4D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Add Row Button
                ElevatedButton(
                  onPressed: _addNewRow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text("Add Row"),
                ),
                
                const SizedBox(height: 10),
                
                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Filter out empty entries
                      final validEntries = _entries.where((entry) {
                        final deposit = double.tryParse(entry['deposit'].text) ?? 0.0;
                        final withdraw = double.tryParse(entry['withdraw'].text) ?? 0.0;
                        return deposit > 0 || withdraw > 0;
                      }).toList();

                      if (validEntries.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please add at least one transaction'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Update the passbook entry
                      SavingsData.updateEntry(
                        widget.entryIndex,
                        widget.existingEntry['date'],
                        validEntries,
                        _totalBalance,
                      );

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9E4D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Update Passbook",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}