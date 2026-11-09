import 'package:flutter/material.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool status = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(),
      appBar: AppBar(
        title: Text('My Shop'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(onPressed: (){
            status = !status;
            setState(() {

            });
          }, icon: Icon(status ? Icons.grid_3x3 : Icons.list))
        ],
      ),
      body: status ? _buildList() : _buildGrid()
    );
  }
}

Widget _buildList() {
  return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index){
        final product = data[index];
        return Container(
          clipBehavior: Clip.hardEdge,
          height: 100,
          margin: EdgeInsets.only(left: 15, right: 15, top: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow:[
              BoxShadow(
                color: Colors.grey.shade500,
                blurRadius: 3
              )
            ]
          ),
          child: Row(
            children: [
              Image.network(
                  width: 100,
                  height: 100,
                  fit: .cover,
                  '${product['image']}'
              ),
              SizedBox(width: 15,),
              Expanded(
                  child: Column(
                    mainAxisAlignment: .spaceEvenly,
                    crossAxisAlignment: .start,
                    children: [
                      Text('${product['title']}', style: TextStyle(fontSize: 18, fontWeight: .bold),),
                      Text('${product['category']}', style: TextStyle(fontSize: 16),),
                      Text('${product['capacity']}')
                    ],
                  )
              ),
              Column(
                mainAxisAlignment: .spaceEvenly,
                crossAxisAlignment: .end,
                children: [
                  Icon(Icons.favorite_border),
                  Text('\$${product['price']}', style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: .bold),)
                ],
              ),
              SizedBox(width: 15,)
            ],
          ),
        );
      });
}

Widget _buildGrid() {
  return GridView.builder(
    padding: const EdgeInsets.all(15),
    itemCount: data.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 0.7,
    ),
    itemBuilder: (context, index) {
      final product = data[index];

      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade500,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                '${product['image']}',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product['title']}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${product['category']} • ${product['capacity']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product['price']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Icon(
                        Icons.favorite_border,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

final data = [
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