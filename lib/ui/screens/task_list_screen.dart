import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import '../../services/api_services.dart';
import '../../models/tugas_model.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<TugasModel>> _futureTugas;
  String _selectedStatus = ""; // Kosong = Semua Tugas

  final List<Map<String, String>> _statusFilters = [
    {"label": "Semua", "value": ""},
    {"label": "Baru", "value": "Pending"},
    {"label": "Proses", "value": "Proses"},
    {"label": "Selesai", "value": "Selesai"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _futureTugas = _getTugasDariServer();
    });
  }

  Future<List<TugasModel>> _getTugasDariServer() async {
    try {
      final response = await _apiService.getTugas(status: _selectedStatus);
      var data = response.data;
      if (data is String) data = jsonDecode(data);

      List<dynamic> listRaw = data['data']?['data'] ?? data['data'] ?? [];
      return listRaw.map((e) => TugasModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error list tugas: $e");
      return [];
    }
  }

  Color _getStatusColor(String status) {
    String s = status.toLowerCase();
    if (s == 'pending' || s == 'belum dibaca') return Colors.orange;
    if (s == 'proses' || s == 'sudah dibaca') return Colors.blue;
    if (s == 'selesai') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Penugasan Saya",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Filter Status Horizontal
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedStatus == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(filter['label']!, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0087FF),
                    backgroundColor: Colors.grey[200],
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedStatus = filter['value']!;
                        _fetchData();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<TugasModel>>(
              future: _futureTugas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0087FF)));
                }

                List<TugasModel> list = snapshot.data ?? [];

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Belum ada tugas buat Tuan.", style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      Color statusColor = _getStatusColor(item.status);

                      return GestureDetector(
                        onTap: () async {
                          final res = await Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => TaskDetailScreen(tugas: item))
                          );
                          if (res == true) _fetchData(); // Refresh kalau ada perubahan status
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(item.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  Text("Tenggat: ${item.jadwalTenggat}", style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(item.deskripsi, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text("${item.namaBarang} (${item.kodeBarcode})", style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}