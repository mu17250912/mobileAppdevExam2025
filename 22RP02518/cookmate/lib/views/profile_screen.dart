import 'package:flutter/material.dart';
import '../models/user.dart';
import 'edit_profile_screen.dart';
import '../services/contact_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'favorite_recipes_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final bool allowEdit;
  final Map<String, int>? recipeViews;
  final List<ContactRequest> Function(String chefId)? getChefRequests;
  final List<ContactRequest> Function(String userId)? getUserRequests;
  final AppUser? Function(String id)? getUserById;
  final List allRecipes;
  const ProfileScreen({
    required this.user,
    this.allowEdit = false,
    this.recipeViews,
    this.getChefRequests,
    this.getUserRequests,
    this.getUserById,
    this.allRecipes = const [],
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppUser _user;
  final ContactService _contactService = ContactService();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _user),
      ),
    );
    if (updated != null && updated is AppUser) {
      setState(() {
        _user = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChef = _user.role == 'chef';
    final isUser = _user.role == 'user';
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text('Name: ${_user.name}', style: TextStyle(fontSize: 18)),
            Text('Email: ${_user.email}', style: TextStyle(fontSize: 18)),
            Text('Role: ${_user.role}', style: TextStyle(fontSize: 18)),
            if (_user.role == 'chef') ...[
              Text('Phone: ${_user.phone ?? 'Not set'}', style: TextStyle(fontSize: 18)),
              Text('Location: ${_user.location ?? 'Not set'}', style: TextStyle(fontSize: 18)),
              Text('Contact Email: ${_user.emailAddress ?? _user.email}', style: TextStyle(fontSize: 18)),
            ],
            if (widget.allowEdit)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Edit Profile'),
                  onPressed: _editProfile,
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Favorites Card (for all roles)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(_user.id).collection('favorites').snapshots(),
                  builder: (context, snapshot) {
                    final favorites = snapshot.data?.docs ?? [];
                    return Card(
                      margin: EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 16),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            child: Row(
                              children: [
                                Icon(Icons.favorite, color: Colors.red, size: 40),
                                SizedBox(width: 16),
                                Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                Spacer(),
                                Text('${favorites.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.red)),
                              ],
                            ),
                          ),
                          Divider(),
                          if (favorites.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.visibility),
                                label: Text('View Favorites'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FavoriteRecipesScreen(user: _user),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                              child: Text('No favorite recipes yet.'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                // Sent Contact Requests Card (for all roles)
                StreamBuilder<List<ContactRequest>>(
                  stream: _contactService.getContactRequestsForUser(_user.id),
                  builder: (context, userSnapshot) {
                    final userRequests = userSnapshot.data ?? [];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            child: Row(
                              children: [
                                Icon(Icons.send, color: Colors.orange, size: 40),
                                SizedBox(width: 16),
                                Text('Sent Contact Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                Spacer(),
                                Text('${userRequests.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.orange)),
                              ],
                            ),
                          ),
                          Divider(),
                          ...userRequests.map((r) {
                            final chefNameFuture = FirebaseFirestore.instance.collection('users').doc(r.chefId).get();
                            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              future: chefNameFuture,
                              builder: (context, snapshot) {
                                String chefName = r.chefId;
                                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                  final data = snapshot.data!.data();
                                  if (data != null && data['name'] != null) chefName = data['name'];
                                }
                                return ListTile(
                                  leading: r.status == ContactRequestStatus.approved
                                      ? Icon(Icons.verified, color: Colors.green)
                                      : r.status == ContactRequestStatus.rejected
                                          ? Icon(Icons.cancel, color: Colors.red)
                                          : Icon(Icons.hourglass_empty, color: Colors.orange),
                                  title: Text('Chef: $chefName'),
                                  subtitle: Text(
                                    r.status == ContactRequestStatus.approved
                                        ? 'Contact approved!'
                                        : r.status == ContactRequestStatus.rejected
                                            ? 'Sorry, your request was not approved.'
                                            : 'Pending approval...'),
                                  trailing: r.status == ContactRequestStatus.pending
                                      ? IconButton(
                                          icon: Icon(Icons.cancel, color: Colors.red),
                                          tooltip: 'Cancel Request',
                                          onPressed: () async {
                                            await _contactService.updateContactRequestStatus(r.docId!, ContactRequestStatus.rejected);
                                          },
                                        )
                                      : null,
                                );
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
                // Received Contact Requests Card (for chefs only)
                if (isChef)
                  StreamBuilder<List<ContactRequest>>(
                    stream: _contactService.getContactRequestsForChef(_user.id),
                    builder: (context, chefSnapshot) {
                      final chefRequests = chefSnapshot.data ?? [];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                              child: Row(
                                children: [
                                  Icon(Icons.inbox, color: Colors.blue, size: 40),
                                  SizedBox(width: 16),
                                  Text('Received Contact Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                  Spacer(),
                                  Text('${chefRequests.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.blue)),
                                ],
                              ),
                            ),
                            Divider(),
                            ...chefRequests.map((r) {
                              final userNameFuture = FirebaseFirestore.instance.collection('users').doc(r.userId).get();
                              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                future: userNameFuture,
                                builder: (context, snapshot) {
                                  String userName = r.userId;
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                    final data = snapshot.data!.data();
                                    if (data != null && data['name'] != null) userName = data['name'];
                                  }
                                  return ListTile(
                                    leading: r.status == ContactRequestStatus.approved
                                        ? Icon(Icons.verified, color: Colors.green)
                                        : r.status == ContactRequestStatus.rejected
                                            ? Icon(Icons.cancel, color: Colors.red)
                                            : Icon(Icons.hourglass_empty, color: Colors.orange),
                                    title: Text('User: $userName'),
                                    subtitle: Text(
                                      r.status == ContactRequestStatus.approved
                                          ? 'You approved this request.'
                                          : r.status == ContactRequestStatus.rejected
                                              ? 'You rejected this request.'
                                              : 'Pending your action...'),
                                    trailing: r.status == ContactRequestStatus.pending
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.check, color: Colors.green),
                                                tooltip: 'Accept',
                                                onPressed: () async {
                                                  await _contactService.updateContactRequestStatus(r.docId!, ContactRequestStatus.approved);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.close, color: Colors.red),
                                                tooltip: 'Reject',
                                                onPressed: () async {
                                                  await _contactService.updateContactRequestStatus(r.docId!, ContactRequestStatus.rejected);
                                                },
                                              ),
                                            ],
                                          )
                                        : null,
                                  );
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                // Analytics Card (for chefs only)
                if (isChef)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('recipes').where('authorId', isEqualTo: _user.id).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox();
                      final recipes = snapshot.data!.docs;
                      final totalViews = recipes.fold<int>(0, (sum, doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final views = data.containsKey('views') ? data['views'] as int : 0;
                        return sum + views;
                      });
                      return Card(
                        margin: EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 16),
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                              child: Row(
                                children: [
                                  Icon(Icons.analytics, color: Colors.deepPurple, size: 40),
                                  SizedBox(width: 16),
                                  Text('Total Recipe Views', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                  Spacer(),
                                  Text('$totalViews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.deepPurple)),
                                ],
                              ),
                            ),
                            Divider(),
                            ExpansionTile(
                              leading: Icon(Icons.restaurant_menu, color: Colors.amber[800]),
                              title: Text('View per Recipe', style: TextStyle(fontWeight: FontWeight.bold)),
                              children: [
                                ...recipes.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final views = data.containsKey('views') ? data['views'] as int : 0;
                                  return ListTile(
                                    leading: Icon(Icons.restaurant_menu, color: Colors.amber[800]),
                                    title: Text(data['title'] ?? ''),
                                    trailing: Text('$views views', style: TextStyle(fontWeight: FontWeight.bold)),
                                  );
                                }).whereType<ListTile>().toList(),
                              ],
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
    );
  }

  List<Widget> _buildChefContactRequests() {
    final requests = widget.getChefRequests!(_user.id);
    if (requests.isEmpty) {
      return [SizedBox(height: 24), Text('No contact requests yet.')];
    }
    return [
      SizedBox(height: 32),
      Text('Manage Contact Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ...requests.map((r) => ListTile(
            title: Text('User: '
                '${widget.getUserById != null ? (widget.getUserById!(r.userId)?.name ?? r.userId) : r.userId}'),
            subtitle: Text('Status: ${r.status.name}'),
            trailing: r.status == ContactRequestStatus.pending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            r.status = ContactRequestStatus.approved;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            r.status = ContactRequestStatus.rejected;
                          });
                        },
                      ),
                    ],
                  )
                : null,
          )),
    ];
  }

  List<Widget> _buildChefSentContactRequests() {
    final sentRequests = widget.getUserRequests!(_user.id);
    if (sentRequests.isEmpty) {
      return [SizedBox(height: 24), Text('No sent contact requests.')];
    }
    return [
      SizedBox(height: 32),
      Text('Sent Contact Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ...sentRequests.map((r) {
        final chefName = widget.getUserById != null ? (widget.getUserById!(r.chefId)?.name ?? r.chefId) : r.chefId;
        return ListTile(
          title: Text('To Chef: $chefName'),
          subtitle: Text('Status: ${r.status.name}'),
        );
      }).whereType<ListTile>().toList(),
    ];
  }

  List<Widget> _buildUserContactNotifications() {
    final requests = widget.getUserRequests!(_user.id);
    if (requests.isEmpty) {
      return [SizedBox(height: 24), Text('No contact requests sent.')];
    }
    return [
      SizedBox(height: 32),
      Text('Contact Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ...requests.map((r) {
        final chef = widget.getUserById != null ? widget.getUserById!(r.chefId) : null;
        final chefName = chef?.name ?? r.chefId;
        final chefEmail = chef?.email ?? 'Unavailable';
        if (r.status == ContactRequestStatus.approved) {
          return ListTile(
            title: Text('Chef: $chefName'),
            subtitle: Text('Contact approved! Here is the chef contact: $chefEmail'),
            leading: Icon(Icons.check, color: Colors.green),
          );
        } else if (r.status == ContactRequestStatus.rejected) {
          return ListTile(
            title: Text('Chef: $chefName'),
            subtitle: Text('Sorry, your request was not approved at the moment.'),
            leading: Icon(Icons.close, color: Colors.red),
          );
        } else {
          return ListTile(
            title: Text('Chef: $chefName'),
            subtitle: Text('Pending approval...'),
            leading: Icon(Icons.hourglass_empty, color: Colors.orange),
          );
        }
      }).whereType<ListTile>().toList(),
    ];
  }
} 