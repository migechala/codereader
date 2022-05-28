// ignore: import_of_legacy_library_into_null_safe
import 'package:http/http.dart' as http;

Future getData(url) async {
  http.Response response = await http.get(url);
  return response.body;
}
