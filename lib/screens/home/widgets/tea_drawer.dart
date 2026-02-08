import 'package:flutter/material.dart';

class TeaFilterDrawer extends StatelessWidget {
  const TeaFilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(child: Text('Фильтры', style: TextStyle(fontSize: 24))),
          ListTile(leading: Icon(Icons.filter_list), title: Text('Только Улуны')),
        ],
      ),
    );
  }
}
