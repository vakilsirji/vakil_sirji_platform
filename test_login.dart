import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var url = Uri.parse('https://pjzscmoskmarshvlgodv.supabase.co/auth/v1/token?grant_type=password');
  var response = await http.post(url, headers: {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqenNjbW9za21hcnNodmxnb2R2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NzI5OTQsImV4cCI6MjA5NzU0ODk5NH0.1GGnx8PzDtGhnRLZG22xu3cjoffB49_vMPYqcdIri2I',
    'Content-Type': 'application/json'
  }, body: jsonEncode({
    'email': 'admin@vakilsirji.com',
    'password': 'password123'
  }));
  print(response.body);
}
