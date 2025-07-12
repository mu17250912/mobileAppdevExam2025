import 'package:flutter/material.dart';

class InfoHubScreen extends StatelessWidget {
  const InfoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Info Hub')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Welcome to the Info Hub',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore trusted information, videos, and resources about sexual health, wellness, and support.',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Articles
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.article_outlined, size: 36, color: Colors.blue),
              title: const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Read educational articles on sexual health, relationships, and self-care.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArticlesScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Videos
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.ondemand_video_outlined, size: 36, color: Colors.redAccent),
              title: const Text('Videos', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Watch helpful videos about health, safety, and empowerment.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VideosScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Resources
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.folder_open, size: 36, color: Colors.green),
              title: const Text('Resources', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Find links, contacts, and support services for your needs.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResourcesScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: const Center(child: Text('List of articles will appear here.')),
    );
  }
}

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Videos')),
      body: const Center(child: Text('List of videos will appear here.')),
    );
  }
}

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: const Center(child: Text('List of resources will appear here.')),
    );
  }
} 