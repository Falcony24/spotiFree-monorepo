import 'package:flutter/material.dart';
import 'package:frontend/screens/catalog_screen.dart';

class Abc extends StatefulWidget {
  @override
  State<Abc> createState() => _AbcState();
}

class _AbcState extends State<Abc> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Abc();
  }
}