import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'announcement_detail_screen.dart';

class MainFeedScreen extends StatelessWidget {
  const MainFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Akış'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, String>>>(
        stream: Stream.fromFuture(Future.delayed(const Duration(seconds: 2), () => [
          {"hoca": "Dr. Ahmet Yılmaz", "mesaj": "Arkadaşlar, vize sınavı konuları sisteme yüklendi."},
          {"hoca": "Asistan Elif Kaya", "mesaj": "Ödev teslimlerini yarın saat 17:00'ye kadar yapınız."},
          {"hoca": "Prof. Dr. Mehmet Demir", "mesaj": "Yarınki dersimiz konferans salonunda yapılacaktır."},
        ])),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }

          if (!snapshot.hasData) return const Center(child: Text("Veri bulunamadı"));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var post = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementDetailScreen(
                          title: post['hoca']!,
                          content: post['mesaj']!, // أضفنا الفاصلة هنا
                          date: "03.05.2026",
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              post['hoca']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(post['mesaj']!, style: const TextStyle(fontSize: 15)),
                        const Divider(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            ReactionButton(
                              label: "Anladım",
                              icon: Icons.check_circle_outline,
                              activeColor: Colors.green,
                            ),
                            ReactionButton(
                              label: "Beğendim",
                              icon: Icons.thumb_up_alt_outlined,
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class ReactionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color activeColor;

  const ReactionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.activeColor,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> with SingleTickerProviderStateMixin {
  bool isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  void _handlePress() {
    setState(() => isPressed = !isPressed);
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: _handlePress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: isPressed ? widget.activeColor : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: isPressed ? widget.activeColor : Colors.grey,
                  fontWeight: isPressed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}