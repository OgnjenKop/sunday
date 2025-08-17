import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/location_manager.dart';
import '../services/uv_service.dart';
import '../services/vitamin_d_calculator.dart';
import '../services/health_manager.dart';
import '../services/network_monitor.dart';
import 'clothing_picker.dart';
import 'sunscreen_picker.dart';
import 'skin_type_picker.dart';
import 'manual_exposure_sheet.dart';
import 'session_completion_sheet.dart';

class ContentView extends StatelessWidget {
  const ContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationManager()),
        ChangeNotifierProvider(create: (_) => HealthManager()),
        ChangeNotifierProvider(create: (_) => UVService()),
        ChangeNotifierProvider(create: (_) => NetworkMonitor()),
        ChangeNotifierProvider(
          create: (context) => VitaminDCalculator(
            context.read<UVService>(),
            context.read<HealthManager>(),
          ),
        ),
      ],
      child: const MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  Timer? _uvTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationManager>().requestPermission();
      context.read<HealthManager>().requestAuthorization();
      // Schedule periodic UV updates (5 minutes) while app is in foreground
      _uvTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        final location = context.read<LocationManager>().location;
        if (location != null) {
          context.read<UVService>().fetchUVData(location);
          // Switch to significant location changes for efficiency
          context.read<LocationManager>().startSignificantLocationChanges();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationManager = context.watch<LocationManager>();
    final uvService = context.watch<UVService>();

    if (locationManager.location != null && !uvService.isLoading) {
      uvService.fetchUVData(locationManager.location!);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: uvService.isLoading
                ? const CircularProgressIndicator()
                : uvService.hasNoData
                    ? const Text('No data available')
                    : _buildContentView(context),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uvTimer?.cancel();
    super.dispose();
  }

  Widget _buildContentView(BuildContext context) {
    final uvService = context.watch<UVService>();
    final vitaminDCalculator = context.watch<VitaminDCalculator>();
    final locationManager = context.watch<LocationManager>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildUvSection(uvService, locationManager),
            const SizedBox(height: 20),
            _buildVitaminDSection(vitaminDCalculator),
            const SizedBox(height: 20),
            _buildActionButtons(context, vitaminDCalculator, uvService),
            const SizedBox(height: 20),
            _buildPickerButtons(context, vitaminDCalculator),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'SUN DAY',
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildUvSection(UVService uvService, LocationManager locationManager) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'UV INDEX',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            uvService.currentUV.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildUvInfo(
                  uvService.shouldShowTomorrowTimes ? 'MAX TMRW' : 'MAX UVI',
                  uvService.displayMaxUV.toStringAsFixed(1)),
              _buildUvInfo('SUNRISE', _formatTime(uvService.displaySunrise)),
              _buildUvInfo('SUNSET', _formatTime(uvService.displaySunset)),
            ],
          ),
          const SizedBox(height: 10),
          _buildBurnLimitRow(context),
          const SizedBox(height: 10),
          if (locationManager.locationName.isNotEmpty)
            Text(
              locationManager.locationName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUvInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildVitaminDSection(VitaminDCalculator vitaminDCalculator) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVitaminDInfo('RATE', '${vitaminDCalculator.currentVitaminDRate.toStringAsFixed(0)} IU/min'),
          _buildVitaminDInfo('SESSION', '${vitaminDCalculator.sessionVitaminD.toStringAsFixed(0)} IU'),
          // _buildVitaminDInfo('TODAY', '0 IU'),
        ],
      ),
    );
  }

  Widget _buildBurnLimitRow(BuildContext context) {
    final uvService = context.watch<UVService>();
    final vitaminDCalculator = context.watch<VitaminDCalculator>();
    final skinTypeIndex = vitaminDCalculator.skinType.index + 1; // 1-6
    final minutes = uvService.burnTimeMinutes[skinTypeIndex] ?? 60;
    final label = minutes < 60
        ? '$minutes min'
        : '${minutes ~/ 60}h ${minutes % 60 == 0 ? '' : '${minutes % 60}m'}'.trim();
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'BURN LIMIT: $label',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildVitaminDInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, VitaminDCalculator vitaminDCalculator, UVService uvService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              if (vitaminDCalculator.isInSun) {
                final action = await showModalBottomSheet<SessionAction>(
                  context: context,
                  builder: (_) => SessionCompletionSheet(
                    sessionAmount: vitaminDCalculator.sessionVitaminD,
                  ),
                );
                if (!mounted) return;
                if (action == SessionAction.save) {
                  await context.read<HealthManager>().saveVitaminD(
                        vitaminDCalculator.sessionVitaminD,
                        DateTime.now(),
                      );
                  vitaminDCalculator.stopSession();
                } else if (action == SessionAction.endWithoutSave) {
                  vitaminDCalculator.stopSession();
                } else {
                  // continueTracking: do nothing
                }
              } else {
                vitaminDCalculator.toggleSunExposure(uvService.currentUV);
              }
            },
            child: Text(vitaminDCalculator.isInSun ? 'Stop' : 'Start'),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => const ManualExposureSheet(),
            );
          },
          child: const Icon(Icons.history),
        ),
      ],
    );
  }

  Widget _buildPickerButtons(BuildContext context, VitaminDCalculator vitaminDCalculator) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => ClothingPicker(
                onSelectionChanged: (level) {
                  vitaminDCalculator.setClothingLevel(level);
                },
              ),
            );
          },
          child: const Text('Clothing'),
        ),
        ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => SunscreenPicker(
                onSelectionChanged: (level) {
                  vitaminDCalculator.setSunscreenLevel(level);
                },
              ),
            );
          },
          child: const Text('Sunscreen'),
        ),
        ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => SkinTypePicker(
                onSelectionChanged: (type) {
                  vitaminDCalculator.setSkinType(type);
                },
              ),
            );
          },
          child: const Text('Skin Type'),
        ),
      ],
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
