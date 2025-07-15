import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ComedyShorts extends StatelessWidget {
  final List<Map<String, String>> shorts = [
    {
      'title': 'Rusine',
      'url': 'https://www.youtube.com/shorts/m3CNJW47CTo?feature=share',
    },
    {
      'title': 'Muhinde',
      'url': 'https://www.youtube.com/shorts/RWDoiSsCWuU?feature=share',
    },
    {
      'title': 'Kwamamaza',
      'url': 'https://www.youtube.com/shorts/V0rRz35F-dg?feature=share',
    },
  ];

  ComedyShorts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comedy Shorts')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: shorts.length,
              itemBuilder: (context, index) {
                final short = shorts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: ListTile(
                    title: Text(short['title'] ?? 'Short'),
                    subtitle: Text(short['url'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 32),
                      onPressed: () async {
                        final url = short['url']!;
                        try {
                          final Uri uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open video')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error opening video: $e')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // Partner Ad Banner
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.15)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Promote your business with Facebook Audience Network!',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[800]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Special Offer'),
                              content: const Text(
                                'Get exclusive access to Facebook Audience Network promotions and boost your business reach! Contact us for partnership opportunities or click below to learn more.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    const url = 'https://www.facebook.com/audiencenetwork/';
                                    try {
                                      final Uri uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not open partner link')),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error opening link: $e')),
                                      );
                                    }
                                  },
                                  child: const Text('Learn More'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Special Offer',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () async {
                          const url = 'https://www.facebook.com/audiencenetwork/';
                          try {
                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open partner link')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error opening link: $e')),
                            );
                          }
                        },
                        child: const Text('Learn More >',
                            style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      const url = 'https://www.facebook.com/audiencenetwork/';
                      try {
                        final Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open partner link')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error opening link: $e')),
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/advertise.png',
                        fit: BoxFit.contain,
                        height: 80,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
