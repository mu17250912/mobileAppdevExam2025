import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageName;
  final String? userEmail;
  const CustomTopBar({Key? key, required this.pageName, this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      title: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hello, ',
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
              ),
              if (userEmail != null && userEmail!.isNotEmpty)
                Text(
                  userEmail!,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(width: 6),
              const Icon(Icons.waving_hand, color: Colors.orange, size: 22),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                pageName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('payments').snapshots(),
                builder: (context, paymentSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('savings').snapshots(),
                    builder: (context, savingSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('Cards').snapshots(),
                        builder: (context, cardSnap) {
                      int count = 0;
                      if (paymentSnap.hasData) count += paymentSnap.data!.docs.length;
                      if (savingSnap.hasData) count += savingSnap.data!.docs.length;
                      if (cardSnap.hasData) count += cardSnap.data!.docs.length;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.orange),
                            tooltip: 'Recent Transactions',
                            onPressed: () {},
                          ),
                          if (count > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                child: Center(
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                        },
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.green),
                tooltip: 'Logout',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/splash');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 