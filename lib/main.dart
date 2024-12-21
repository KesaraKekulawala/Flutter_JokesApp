import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(JokesApp());

class JokesApp extends StatelessWidget {
  const JokesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jokes App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const JokesHomePage(),
    );
  }
}

class JokesHomePage extends StatefulWidget {
  const JokesHomePage({super.key});

  @override
  _JokesHomePageState createState() => _JokesHomePageState();
}

class _JokesHomePageState extends State<JokesHomePage> {
  List<String> jokes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJokes();
  }

  Future<void> fetchJokes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(Uri.parse('https://official-joke-api.appspot.com/jokes/ten'));

      if (response.statusCode == 200) {
        final List<dynamic> jokeData = json.decode(response.body);
        jokes = jokeData.map((joke) => "${joke['setup']} - ${joke['punchline']}").toList();
        await prefs.setString('cached_jokes', json.encode(jokes));
      } else {
        throw Exception('Failed to load jokes');
      }
    } catch (e) {
      // Load cached jokes if offline or API fails
      final cachedJokes = prefs.getString('cached_jokes');
      if (cachedJokes != null) {
        jokes = List<String>.from(json.decode(cachedJokes));
      } else {
        jokes = ["No jokes available. Please check your internet connection."];
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jokes App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, )),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text("Fetching jokes...", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : jokes.isEmpty
              ? Center(
                  child: Text(
                    "No jokes available. Please check your internet connection.",
                    style: TextStyle(fontSize: 16, color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jokes.length,
                  itemBuilder: (context, index) => JokeCard(joke: jokes[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchJokes,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class JokeCard extends StatelessWidget {
  final String joke;

  const JokeCard({required this.joke});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          joke,
          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
        ),
      ),
    );
  }
}
