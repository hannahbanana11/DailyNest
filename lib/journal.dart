import 'package:flutter/material.dart';
import 'package:dailynest/addjournal.dart';
import 'package:dailynest/editjournal.dart';

// Global list to store journal entries
class JournalData {
  static List<Map<String, String>> journalEntries = [];

  static void addEntry(String title, String content, String date) {
    journalEntries.insert(0, {
      'title': title,
      'date': date,
      'content': content,
    });
  }

  static void removeEntry(int index) {
    if (index >= 0 && index < journalEntries.length) {
      journalEntries.removeAt(index);
    }
  }

  static void updateEntry(int index, String title, String content, String date) {
    if (index >= 0 && index < journalEntries.length) {
      journalEntries[index] = {
        'title': title,
        'date': date,
        'content': content,
      };
    }
  }
}

class Journal extends StatefulWidget {
  static const String id = "Journal";

  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  @override
  void dispose() {
    super.dispose();
  }

  // Method to delete journal entry
  void deleteJournalEntry(int index) {
    setState(() {
      JournalData.removeEntry(index);
    });
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddJournal()),
          ).then((_) {
            // Refresh the journal list when returning from AddJournal
            setState(() {});
          });
        },
        backgroundColor: const Color(0xFFFF9E4D),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
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
                
                // Journal subtitle
                const Text(
                  "Journal",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Journal Entries List
                Expanded(
                  child: JournalData.journalEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              color: Colors.grey.withOpacity(0.5),
                              size: 100,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "No journal entries yet",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Tap the + button to create your first entry",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: JournalData.journalEntries.length,
                        itemBuilder: (context, index) {
                          final entry = JournalData.journalEntries[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                entry['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    entry['date']!,
                                    style: const TextStyle(
                                      color: Color(0xFFFF9E4D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    entry['content']!,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Delete Journal Entry'),
                                            content: const Text('Are you sure you want to delete this journal entry?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  deleteJournalEntry(index);
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Journal entry deleted'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                },
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Color(0xFFFF9E4D),
                                    size: 16,
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Navigate to EditJournal with existing data
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditJournal(
                                      journalIndex: index,
                                      initialTitle: entry['title']!,
                                      initialContent: entry['content']!,
                                      date: entry['date']!,
                                    ),
                                  ),
                                ).then((_) {
                                  // Refresh the list when returning from edit
                                  setState(() {});
                                });
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
      ),
    );
  }
}