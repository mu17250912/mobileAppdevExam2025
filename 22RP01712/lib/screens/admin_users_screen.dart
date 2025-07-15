import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'With CV', 'With Experience', 'With Degrees', 'With Certificates'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getAllUserProfiles();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Apply search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.idNumber.toLowerCase().contains(_searchQuery.toLowerCase());

        if (!matchesSearch) return false;

        // Apply category filter
        switch (_selectedFilter) {
          case 'With CV':
            return user.cvUrl != null && user.cvUrl!.isNotEmpty;
          case 'With Experience':
            return user.experiences.isNotEmpty;
          case 'With Degrees':
            return user.degrees.isNotEmpty;
          case 'With Certificates':
            return user.certificates.isNotEmpty;
          default:
            return true;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All User Profiles'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or ID number...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _filterUsers();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterUsers();
                    });
                  },
                ),
                SizedBox(height: 12),
                // Filter Dropdown
                Row(
                  children: [
                    Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      items: _filterOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFilter = newValue!;
                          _filterUsers();
                        });
                      },
                    ),
                    Spacer(),
                    Text('${_filteredUsers.length} users'),
                  ],
                ),
              ],
            ),
          ),
          // Users List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                                  ? 'No users match your search criteria'
                                  : 'No users found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: user.cvUrl != null ? NetworkImage(user.cvUrl!) : null,
              child: user.cvUrl == null ? Icon(Icons.person) : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildInfoChip('ID: ${user.idNumber}', Colors.blue),
              SizedBox(width: 8),
              if (user.cvUrl != null && user.cvUrl!.isNotEmpty)
                _buildInfoChip('CV', Colors.green),
              if (user.experiences.isNotEmpty)
                _buildInfoChip('${user.experiences.length} Exp', Colors.orange),
              if (user.degrees.isNotEmpty)
                _buildInfoChip('${user.degrees.length} Degrees', Colors.purple),
              if (user.certificates.isNotEmpty)
                _buildInfoChip('${user.certificates.length} Certs', Colors.teal),
            ],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information
                _buildInfoSection('Personal Information', [
                  'ID Number: ${user.idNumber}',
                  'Full Name: ${user.fullName}',
                  'Email: ${user.email}',
                  'Telephone: ${user.telephone}',
                ]),
                
                // Education
                if (user.degrees.isNotEmpty)
                  _buildInfoSection('Education', user.degrees),
                
                // Experience
                if (user.experiences.isNotEmpty)
                  _buildInfoSection('Work Experience', 
                    user.experiences.map((e) => e.description).toList()),
                
                // Certificates
                if (user.certificates.isNotEmpty)
                  _buildInfoSection('Certificates', user.certificates),
                
                // Action Buttons
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.edit),
                      label: Text('Edit'),
                      onPressed: () => _editUser(user),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text('Delete'),
                      onPressed: () => _deleteUser(user),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.visibility),
                      label: Text('View Details'),
                      onPressed: () => _viewUserDetails(user),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(left: 16, bottom: 4),
          child: Text('• $item'),
        )),
        SizedBox(height: 12),
      ],
    );
  }

  void _editUser(AppUser user) {
    // TODO: Navigate to edit user screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _deleteUser(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _userService.deleteUserProfile(user.id);
              if (success) {
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete user'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _viewUserDetails(AppUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(user: user),
      ),
    );
  }
}

class UserDetailsScreen extends StatelessWidget {
  final AppUser user;

  const UserDetailsScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: user.cvUrl != null ? NetworkImage(user.cvUrl!) : null,
                    child: user.cvUrl == null ? Icon(Icons.person, size: 60) : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            
            // Personal Information
            _buildDetailCard('Personal Information', [
              {'label': 'ID Number', 'value': user.idNumber},
              {'label': 'Full Name', 'value': user.fullName},
              {'label': 'Email', 'value': user.email},
              {'label': 'Telephone', 'value': user.telephone},
            ]),
            
            // Education
            if (user.degrees.isNotEmpty)
              _buildDetailCard('Education', 
                user.degrees.map((degree) => {'label': 'Degree', 'value': degree}).toList()),
            
            // Experience
            if (user.experiences.isNotEmpty)
              _buildDetailCard('Work Experience', 
                user.experiences.map((exp) => {'label': 'Experience', 'value': exp.description}).toList()),
            
            // Certificates
            if (user.certificates.isNotEmpty)
              _buildDetailCard('Certificates', 
                user.certificates.map((cert) => {'label': 'Certificate', 'value': cert}).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Map<String, String>> items) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${item['label']}:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(item['value']!),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
} 