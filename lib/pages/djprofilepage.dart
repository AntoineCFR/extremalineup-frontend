import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DJProfilePage extends StatelessWidget {
  final Map<String, dynamic> djData;

  const DJProfilePage({super.key, required this.djData});

  static String getDjImagePath(String djName) {
    final normalized = djName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll(RegExp(r'[^\w]'), '');
    return 'lib/assets/$normalized.jpg';
  }

  @override
  Widget build(BuildContext context) {
    String imagePath = getDjImagePath(djData['name']);

    final socialMedia = [
      {'name': 'spotify', 'icon': FontAwesomeIcons.spotify, 'url': djData['spotify_link']},
      {'name': 'soundcloud', 'icon': FontAwesomeIcons.soundcloud, 'url': djData['soundcloud_link']},
      {'name': 'instagram', 'icon': FontAwesomeIcons.instagram, 'url': djData['instagram_link']},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(djData['name'])),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                djData['bio'] ?? 'Aucune bio disponible.',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Réseaux sociaux :',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: socialMedia.map((social) {
                if (social['url'] == null || social['url']!.isEmpty) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IconButton(
                    icon: FaIcon(social['icon'] as IconData),
                    iconSize: 32,
                    onPressed: () async {
                      // Solution finale : Utilisation de maybeOf + vérification
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      if (await canLaunchUrl(Uri.parse(social['url']!))) {
                        await launchUrl(Uri.parse(social['url']!));
                      } else if (messenger != null) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Impossible d\'ouvrir ${social['url']!}')),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}