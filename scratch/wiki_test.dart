import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final query = 'Sneijder footballer';
  final searchUrl = Uri.parse('https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$query&utf8=&format=json&srlimit=1');
  
  final searchRes = await http.get(searchUrl);
  final searchJson = jsonDecode(searchRes.body);
  final title = searchJson['query']['search'][0]['title'] as String;
  
  final catUrl = Uri.parse('https://en.wikipedia.org/w/api.php?action=query&prop=categories&titles=${Uri.encodeComponent(title)}&cllimit=max&format=json');
  final catRes = await http.get(catUrl);
  final categories = jsonDecode(catRes.body)['query']['pages'].values.first['categories'] as List;
  
  for (final cat in categories) {
    print(cat['title']);
  }
}
