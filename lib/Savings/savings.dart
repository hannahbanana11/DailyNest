import 'package:flutter/material.dart';
import 'package:dailynest/Savings/addsavings.dart';
import 'package:dailynest/Savings/editsavings.dart';
import 'package:dailynest/database/DiaryFirebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Global data class for savings entries (in-memory storage)
class SavingsData {
  static List<Map<String, dynamic>> entries = [];

  static void addEntry(String date, List<Map<String, dynamic>> transactions, double totalBalance) {
    entries.add({
      'date': date,
      'transactions': transactions.map((t) => {
        'time': t['time'],
        'deposit': t['deposit'].text,
        'withdraw': t['withdraw'].text,
        'balance': t['balance'],
      }).toList(),
      'totalBalance': totalBalance,
    });
  }

  static void updateEntry(int index, String date, List<Map<String, dynamic>> transactions, double totalBalance) {
    if (index >= 0 && index < entries.length) {
      entries[index] = {
        'date': date,
        'transactions': transactions.map((t) => {
          'time': t['time'],
          'deposit': t['deposit'].text,
          'withdraw': t['withdraw'].text,
          'balance': t['balance'],
        }).toList(),
        'totalBalance': totalBalance,
      };
    }
  }

  static void removeEntry(int index) {
    if (index >= 0 && index < entries.length) {
      entries.removeAt(index);
    }
  }
}

class Savings extends StatefulWidget {
  static const String id = "Savings";

  const Savings({super.key});

  @override
  State<Savings> createState() => _SavingsState();
}

class _SavingsState extends State<Savings> {
  final FirestoreService _firestoreService = FirestoreService();

  // Method to delete savings entry
  void deleteSavingsEntry(String docID) async {
    try {
      await _firestoreService.deleteSavings(docID);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passbook entry deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ModalRoute.of(context)?.canPop == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                
                // Savings subtitle
                const Text(
                  "Savings",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Savings entries list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getSavingsStream(),
                    builder: (context, snapshot) {
                      // Loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF9E4D),
                          ),
                        );
                      }

                      // Error state
                      if (snapshot.hasError) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.withOpacity(0.5),
                                  size: 80,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Error loading savings",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Empty state
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.savings,
                                  color: Color(0xFFFF9E4D),
                                  size: 80,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No savings records yet",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Tap the + button to add your first passbook entry",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // List of savings entries
                      final savingsDocs = snapshot.data!.docs;
                      return ListView.builder(
                          itemCount: savingsDocs.length,
                          itemBuilder: (context, index) {
                            final doc = savingsDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final docID = doc.id;
                            final date = data['date'] ?? '';
                            final transactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
                            final totalBalance = (data['totalBalance'] ?? 0.0).toDouble();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
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
                                  // Header with date and actions
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF9E4D),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Passbook - $date",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            // Edit button
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.white),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => EditSavings(
                                                      docID: docID,
                                                      existingEntry: {
                                                        'date': date,
                                                        'transactions': transactions,
                                                        'totalBalance': totalBalance,
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            // Delete button
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.white),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text("Delete Passbook"),
                                                    content: const Text("Are you sure you want to delete this passbook entry?"),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text("Cancel"),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          deleteSavingsEntry(docID);
                                                          Navigator.pop(context);
                                                        },
                                                        child: const Text("Delete"),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Transactions table
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        // Table header
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            children: [
                                              Expanded(flex: 2, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Deposit', style: TextStyle(fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // Transaction rows
                                        ...transactions.map<Widget>((transaction) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 2, child: Text(transaction['time'] ?? '')),
                                                Expanded(flex: 2, child: Text(transaction['deposit'] ?? '')),
                                                Expanded(flex: 2, child: Text(transaction['withdraw'] ?? '')),
                                                Expanded(flex: 2, child: Text((transaction['balance'] ?? 0.0).toStringAsFixed(2))),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        
                                        const Divider(),
                                        
                                        // Total balance
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Balance:',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              totalBalance.toStringAsFixed(2),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFF9E4D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'savings_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSavings()),
          ).then((_) {
            setState(() {});
          });
        },
        backgroundColor: const Color(0xFFFF9E4D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}