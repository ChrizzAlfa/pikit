import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pikit/models/outlet_model.dart';
import 'package:pikit/shop.dart';
import 'package:pikit/theme/app_colors.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class OutletPage extends StatefulWidget {
  const OutletPage({super.key});

  @override
  _OutletPageState createState() => _OutletPageState();
}

class _OutletPageState extends State<OutletPage> {
  final panelController = PanelController();
  Future<OutletModels>? outletModelsFuture;
  int? selectedIndex; // Track the selected index
  bool isFabVisible = false; // Track the visibility of the FAB

  @override
  void initState() {
    super.initState();
    outletModelsFuture = fetchOutlets();
  }

  Future<OutletModels> fetchOutlets() async {
    final response = await http.get(Uri.parse("YOUR_POCKETBASE_URL/api/collections/outlets/records"));

    if (response.statusCode == 200) {
      return OutletModels.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load outlets');
    }
  }

  void _onTileTap(int index) {
    setState(() {
      selectedIndex = index; // Update the selected index
      isFabVisible = true; // Show FAB when a tile is selected
    });
  }

void _onPikitButtonPressed() {
  if (selectedIndex != null) {
    outletModelsFuture?.then((outletModels) {
      final selectedOutlet = outletModels.items![selectedIndex!]; 
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShopPage(
            outletAddress: selectedOutlet.address ?? 'Unknown Address', 
            outletId: selectedOutlet.id ?? '', 
          ),
        ),
      );
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        controller: panelController,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: MediaQuery.of(context).size.height * 0.15,
        parallaxEnabled: true,
        parallaxOffset: .5,
        color: AppColors.primary,
        body: _buildMap(context),
        panelBuilder: (controller) {
          return FutureBuilder<OutletModels>(
            future: outletModelsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.items == null) {
                return const Center(child: Text('No outlets found.'));
              }

              final items = snapshot.data!.items!;
              return ListView.separated(
                controller: controller,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: selectedIndex == index
                            ? Border.all(color: AppColors.accent, width: 1)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          title: Text(item.address ?? ''),
                          trailing: const Text("10KM"), // You can replace this with actual distance if available
                          leading: SvgPicture.asset(
                            item.retail == "indomaret" ? 'assets/vectors/indomaret.svg' : 'assets/vectors/alfamart.svg',
                            width: 64,
                          ),
                          titleTextStyle: const TextStyle(
                            color: AppColors.accent,
                          ),
                          leadingAndTrailingTextStyle: const TextStyle(
                            color: AppColors.secondary,
                          ),
                          minTileHeight: 104,
                          onTap: () => _onTileTap(index), // Handle tap
                        ),
                      ),
                    )
                  );
                },
              );
            },
          );
        },
        onPanelSlide: (position) {
          // Update FAB visibility based on panel position
          setState(() {
            isFabVisible = position > 0.15; // Show FAB when panel is above minimum height
          });
        },
      ),
      floatingActionButton: isFabVisible // Show button only if it is visible
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0, right: 16.0), // Add padding to position the button
              child: ElevatedButton(
                onPressed: _onPikitButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent, // Set the button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Pill shape
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Adjust padding for the button
                ),
                child: const Text(
                  "PIKIT",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ), // Text color
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMap(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(-1.2381219237901093, 116.85226291498557),
        initialZoom: 12,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.pinchMove,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.pikit',
        ),
      ],
    );
  }
}