import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:jameel/models/location_model.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/styles/app_design.dart';

const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d222d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#9ca3af"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1d222d"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2b3242"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f141e"}]}
]
''';

class LocationHistorySection extends StatefulWidget {
  const LocationHistorySection({super.key, required this.items});

  final List<LocationCheckInModel> items;

  @override
  State<LocationHistorySection> createState() => _LocationHistorySectionState();
}

class _LocationHistorySectionState extends State<LocationHistorySection> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('location_history'.tr(), trailing: _toggle()),
        const SizedBox(height: 14),
        if (_showMap)
          _mapView(widget.items)
        else
          _timelineListView(widget.items),
      ],
    );
  }

  Widget _toggle() {
    Widget item(
      IconData icon,
      String tooltip,
      bool selected,
      VoidCallback onTap,
    ) {
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () {
            AppHaptics.light();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : context.mutedColor,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.toggleTrackColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(
            Icons.view_list_rounded,
            'list_view'.tr(),
            !_showMap,
            () => setState(() => _showMap = false),
          ),
          item(
            Icons.map_rounded,
            'map_view'.tr(),
            _showMap,
            () => setState(() => _showMap = true),
          ),
        ],
      ),
    );
  }

  Widget _timelineListView(List<LocationCheckInModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String bucketFor(DateTime dt) {
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day == today) return 'date_today';
      if (day == yesterday) return 'date_yesterday';
      return 'date_earlier';
    }

    final children = <Widget>[];
    String? currentBucket;

    for (final item in items) {
      final bucket = bucketFor(item.timestamp);
      if (bucket != currentBucket) {
        currentBucket = bucket;
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: children.isEmpty ? 0 : 16,
              bottom: 8,
              left: 4,
              right: 4,
            ),
            child: Text(
              bucket.tr(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: context.mutedColor,
              ),
            ),
          ),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildLocationCard(item),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildLocationCard(LocationCheckInModel item) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(item.timestamp);
    final formattedTime = DateFormat('HH:mm').format(item.timestamp);
    final coordsText =
        '${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}';
    final subtitle = (item.address != null && item.address!.isNotEmpty)
        ? item.address!
        : coordsText;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBubble(
            icon: item.isCheckOut ? Icons.logout_rounded : Icons.place_rounded,
            color: item.isCheckOut ? AppColors.info : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.isCheckOut
                      ? 'check_out_title'.tr()
                      : 'check_in_title'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: context.inkColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection:
                      (item.address != null && item.address!.isNotEmpty)
                          ? null
                          : ui.TextDirection.ltr,
                  style: TextStyle(
                    color: context.mutedColor,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: context.inkColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formattedDate,
                style: TextStyle(
                  color: context.mutedColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<LocationCheckInModel> items) {
    return items.map((item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        infoWindow: InfoWindow(
          title:
              item.isCheckOut ? 'check_out_title'.tr() : 'check_in_title'.tr(),
          snippet: item.address,
        ),
      );
    }).toSet();
  }

  Widget _mapView(List<LocationCheckInModel> items) {
    final markers = _buildMarkers(items);
    final initial = items.isNotEmpty
        ? LatLng(items.first.latitude, items.first.longitude)
        : const LatLng(0, 0);

    return Stack(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.borderColor),
            boxShadow: context.isDark ? null : AppShadows.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 13),
            markers: markers,
            style: context.isDark ? _darkMapStyle : null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
        ),
        PositionedDirectional(
          top: 12,
          end: 12,
          child: Material(
            color: context.surfaceColor.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              icon: Icon(
                Icons.open_in_full_rounded,
                size: 20,
                color: context.inkColor,
              ),
              tooltip: 'expand_map'.tr(),
              onPressed: () => _openFullScreenMap(context, initial, markers),
            ),
          ),
        ),
      ],
    );
  }

  void _openFullScreenMap(
    BuildContext context,
    LatLng initial,
    Set<Marker> markers,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: Text('location_history'.tr())),
          body: GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 13),
            markers: markers,
            style: ctx.isDark ? _darkMapStyle : null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
        ),
      ),
    );
  }
}
