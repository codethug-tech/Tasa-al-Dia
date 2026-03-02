import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';

void main() {
  runApp(const TasaAlDiaApp());
}

class TasaAlDiaApp extends StatelessWidget {
  const TasaAlDiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasa al Día',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5BFF), // Electric Blue from Stitch
          primary: const Color(0xFF2D5BFF),
          secondary: const Color(0xFF00C853), // Emerald Green
          surface: const Color(0xFFF4F7FA), // Soft Slate Background
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF4F7FA),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF1A1C1E),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2D5BFF).withOpacity(0.1),
          labelTextStyle: MaterialStateProperty.all(
            GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const MainContainer(),
    );
  }
}

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _ratesData = {};
  bool _isLoading = true;
  String? _error;
  String _lastUpdate = "--:--";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.fetchRates();
      setState(() {
        _ratesData = data['rates'];
        final timestamp = DateTime.parse(data['timestamp']);
        _lastUpdate = DateFormat('h:mm a').format(timestamp);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Servidor fuera de línea";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            RatesDashboard(
              rates: _ratesData,
              isLoading: _isLoading,
              onRefresh: _fetchData,
              lastUpdate: _lastUpdate,
              error: _error,
            ),
            ConverterDashboard(rates: _ratesData),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded, color: Colors.grey),
            selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF2D5BFF)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.calculate_rounded, color: Color(0xFF2D5BFF)),
            label: 'Convertir',
          ),
        ],
      ),
    );
  }
}

class RatesDashboard extends StatelessWidget {
  final Map<String, dynamic> rates;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String lastUpdate;
  final String? error;

  const RatesDashboard({
    super.key,
    required this.rates,
    required this.isLoading,
    required this.onRefresh,
    required this.lastUpdate,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (error != null) _buildErrorCard() else ...[
            _buildMainRateCard(context),
            const SizedBox(height: 20),
            Text(
              "Otras Fuentes",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 12),
            ...rates.entries
                .where((e) => e.key != 'usd_parallel')
                .map((e) => SecondaryRateCard(rateKey: e.key, data: e.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tasa al Día", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text("Actualizado: $lastUpdate", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: isLoading 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Icon(Icons.refresh, size: 20),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          const Text("No se pudo obtener datos", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(error ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRefresh, child: const Text("Reintentar")),
        ],
      ),
    );
  }

  Widget _buildMainRateCard(BuildContext context) {
    final parallel = rates['usd_parallel'];
    if (parallel == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5BFF), Color(0xFF5B8BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5BFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("DÓLAR PARALELO", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text("Favorito", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${double.parse(parallel['rate'].toString()).toStringAsFixed(2)}",
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800),
          ),
          const Text("Bs. por cada 1 USD", style: TextStyle(color: Colors.white60, fontSize: 14)),
        ],
      ),
    );
  }
}

class SecondaryRateCard extends StatelessWidget {
  final String rateKey;
  final dynamic data;

  const SecondaryRateCard({super.key, required this.rateKey, required this.data});

  @override
  Widget build(BuildContext context) {
    final double rate = double.parse(data['rate'].toString());
    final bool isOfficial = rateKey.contains('official');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOfficial ? const Color(0xFF2D5BFF).withOpacity(0.05) : const Color(0xFFF1B434).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOfficial ? Icons.account_balance_rounded : Icons.currency_bitcoin_rounded,
              color: isOfficial ? const Color(0xFF2D5BFF) : const Color(0xFFF1B434),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(isOfficial ? "BCV Oficial" : "P2P Market", style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(
            rate.toStringAsFixed(2),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(width: 4),
          const Text("Bs.", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ConverterDashboard extends StatefulWidget {
  final Map<String, dynamic> rates;
  const ConverterDashboard({super.key, required this.rates});

  @override
  State<ConverterDashboard> createState() => _ConverterDashboardState();
}

class _ConverterDashboardState extends State<ConverterDashboard> {
  final TextEditingController _usdController = TextEditingController();
  final TextEditingController _vesController = TextEditingController();
  String? _selectedKey;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    if (widget.rates.containsKey('usd_parallel')) _selectedKey = 'usd_parallel';
  }

  void _convert(String val, bool isUsd) {
    if (_isUpdating || _selectedKey == null) return;
    _isUpdating = true;
    final double? input = double.tryParse(val);
    final double rate = double.parse(widget.rates[_selectedKey]['rate'].toString());

    if (input == null) {
      if (isUsd) _vesController.clear(); else _usdController.clear();
    } else {
      if (isUsd) {
        _vesController.text = (input * rate).toStringAsFixed(2);
      } else {
        _usdController.text = (input / rate).toStringAsFixed(2);
      }
    }
    _isUpdating = false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Calculadora", style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800)),
          const Text("Conversión instantánea", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          
          _buildInputGroup("Monto en Dólares", "USD", _usdController, true),
          const SizedBox(height: 24),
          _buildInputGroup("Monto en Bolívares", "VES", _vesController, false),
          
          const SizedBox(height: 32),
          Text("Tasa de Referencia", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.05))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedKey,
                items: widget.rates.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['name'], style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() { _selectedKey = v; _convert(_usdController.text, true); }),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildInputGroup(String label, String currency, TextEditingController controller, bool isUsd) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(isUsd ? "\$" : "Bs.", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF2D5BFF))),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _convert(v, isUsd),
                  style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(hintText: "0.00", border: InputBorder.none, contentPadding: EdgeInsets.zero),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 10,
      children: [1, 5, 10, 20, 50, 100].map((a) => ActionChip(
        label: Text("\$$a", style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () { _usdController.text = a.toString(); _convert(a.toString(), true); },
        backgroundColor: Colors.white,
        side: BorderSide(color: const Color(0xFF2D5BFF).withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )).toList(),
    );
  }
}
