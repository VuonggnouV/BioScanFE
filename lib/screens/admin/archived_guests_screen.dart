import 'package:bioscan/screens/manager/history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;
import 'package:intl/intl.dart';

class ArchivedGuestsScreen extends StatelessWidget {
  const ArchivedGuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lượt truy cập của khách', style: TextStyle(color: app_colors.textLight)),
        backgroundColor: app_colors.background,
        iconTheme: const IconThemeData(color: app_colors.textLight),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('archived_guests').orderBy('signedOutAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có lượt truy cập nào của khách.', style: TextStyle(color: app_colors.textLight)));
          }

          final guests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: guests.length,
            itemBuilder: (context, index) {
              final guestData = guests[index].data() as Map<String, dynamic>;
              final String guestId = guestData['uid'];
              final Timestamp signedOutAt = guestData['signedOutAt'];
              
              final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(signedOutAt.toDate());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.person_off_outlined),
                  title: Text('Guest ID: ...${guestId.substring(guestId.length - 8)}'),
                  subtitle: Text('Đã kết thúc: $formattedDate'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => HistoryScreen(
                        userId: guestId,
                        onScanNow: (){},
                        isGuest: true, // <-- Đánh dấu đây là khách

                      )
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}