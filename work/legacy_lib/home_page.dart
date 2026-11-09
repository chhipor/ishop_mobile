import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String _heroImage = 'assets/HeroSection-Angkor-Wat.jpg';
  static const String _leftImage = 'assets/angkor_wat_1.jpg';
  static const String _rightImage = 'assets/angkor_wat_2.webp';
  static const String _flagImage = 'assets/Flag_of_Cambodia.svg.webp';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF20000),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'My App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      // body: SafeArea(
      //   child: ListView(
      //     padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      //     children: [
      //       _RoundedImage(imageUrl: _heroImage, height: 210),
      //       const SizedBox(height: 18),
      //       const Text(
      //         'About Angkor Wat',
      //         style: TextStyle(
      //           fontSize: 22,
      //           fontWeight: FontWeight.w700,
      //           color: Colors.black,
      //         ),
      //       ),
      //       const SizedBox(height: 16),
      //       const Text(
      //         'Angkor Wat, temple complex at Angkor, near Siem Reap, Cambodia, that was built in the 12th century by King Suryavarman II (reigned 1113–c. 1150) of the Khmer empire. The vast religious complex of Angkor Wat comprises more than a thousand buildings, and it is one of the great cultural wonders of the world. Angkor Wat is the world\'s largest religious structure, covering some 400 acres (160 hectares), and marks the high point of Khmer architecture.',
      //         textAlign: TextAlign.justify,
      //         style: TextStyle(
      //           fontSize: 14,
      //           height: 1.35,
      //           color: Color(0xFF222222),
      //         ),
      //       ),
      //       const SizedBox(height: 28),
      //       const _InfoCard(
      //         icon: _FlagTile(imageUrl: _flagImage),
      //         text: 'Country : Cambodia',
      //       ),
      //       const SizedBox(height: 14),
      //       const _InfoCard(
      //         icon: Icon(Icons.calendar_month, size: 30, color: Colors.black87),
      //         text: 'Built in : 12th Century',
      //       ),
      //       const SizedBox(height: 15),
      //       const Row(
      //         children: [
      //           Expanded(child: _GalleryImage(imageUrl: _leftImage)),
      //           SizedBox(width: 18),
      //           Expanded(child: _GalleryImage(imageUrl: _rightImage)),
      //         ],
      //       ),
      //     ],
      //   ),
      // ),

        body: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
              ),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [

                  // Product Image
                  SizedBox(
                    width: 100,
                    height: 120,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.network(
                        data[index]['image'] as String,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Product Information
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 5,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Title + Favorite
                          Row(
                            children: [

                              Expanded(
                                child: Text(
                                  data[index]['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                              Container(
                                padding: EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.favorite_border,
                                  size: 24,
                                ),
                              )
                              // SizedBox(
                              //   width: 20,
                              // )
                            ],
                          ),

                          const SizedBox(height: 5),

                          // Category
                          Text(
                            data[index]['category'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // Size + Price
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data[index]['capacity'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              Text(
                                "\$${(data[index]['price'] as double).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    );
  }
}

var data = [
  {
    "id": 1,
    "title": "Coca Cola",
    "category": "Soft Drink",
    "capacity": "330ml",
    "price": 1.00,
    "image":
    "https://images.unsplash.com/photo-1629203849820-fdd70d49c38e?auto=format&fit=crop&w=400&q=80",
  },
  {
    "id": 2,
    "title": "Pepsi",
    "category": "Soft Drink",
    "capacity": "330ml",
    "price": 1.00,
    "image":
    "https://images.unsplash.com/photo-1554866585-cd94860890b7?auto=format&fit=crop&w=400&q=80",
  },
  {
    "id": 3,
    "title": "Cambodia Beer",
    "category": "Beer",
    "capacity": "330ml",
    "price": 0.75,
    "image":
    "https://images.unsplash.com/photo-1515003197210-e0cd71810b5f?auto=format&fit=crop&w=400&q=80",
  },
  {
    "id": 4,
    "title": "Orange Juice",
    "category": "Juice",
    "capacity": "500ml",
    "price": 1.50,
    "image":
    "https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&w=400&q=80",
  },
  {
    "id": 5,
    "title": "Mineral Water",
    "category": "Water",
    "capacity": "500ml",
    "price": 0.50,
    "image":
    "https://images.unsplash.com/photo-1564419320461-6870880221ad?auto=format&fit=crop&w=400&q=80",
  },
  {
    "id": 6,
    "title": "Iced Coffee",
    "category": "Coffee",
    "capacity": "350ml",
    "price": 2.00,
    "image":
    "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=400&q=80",
  },
];

class _RoundedImage extends StatelessWidget {
  const _RoundedImage({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFE6E6E6),
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 56, color: Colors.black38),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 54, height: 34, child: Center(child: icon)),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 17, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  const _FlagTile({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.asset(
        imageUrl,
        width: 54,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 54,
            height: 34,
            color: const Color(0xFFF20000),
            alignment: Alignment.center,
            child: const Icon(Icons.flag, size: 18, color: Colors.white),
          );
        },
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFE6E6E6),
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 44, color: Colors.black38),
            );
          },
        ),
      ),
    );
  }
}
