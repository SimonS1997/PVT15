import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../managers/saved_events_manager.dart';
import '../models/event_location.dart';

class EventMapView extends StatefulWidget {
  const EventMapView({
    super.key,
    required this.events,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.initialPlanOnly = false,
    this.initialSelectedEvent,
  });

  final List<EventLocation> events;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final bool initialPlanOnly;
  final EventLocation? initialSelectedEvent;

  @override
  State<EventMapView> createState() => _EventMapViewState();
}

class _EventMapViewState extends State<EventMapView> {
  static const LatLng stockholm = LatLng(59.3293, 18.0686);
  static const double _mapControlBottom = 16;
  static const double _selectedEventControlBottom = 232;
  static const bool _hideMapControlsWhenEventSelected = true;
  static const Map<String, String> categoryLabels = {
    'MUSIC': 'Musik',
    'ART': 'Konst',
    'THEATRE': 'Teater',
    'FILM': 'Film',
    'DANCE': 'Dans',
    'GUIDED_TOUR': 'Guidad tur',
    'HISTORY': 'Historia',
    'LITERATURE': 'Litteratur',
    'WELLNESS': 'Wellness',
    'WORKSHOP': 'Workshop',
    'OTHER': 'Övrigt',
  };

  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? mapController;
  bool locationEnabled = false;
  late bool showPlanOnly = widget.initialPlanOnly;
  String searchQuery = '';
  Set<String> selectedCategories = {};
  EventLocation? selectedEvent;
  bool _didFocusInitialEvent = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeLocation());
  }

  @override
  void dispose() {
    _searchController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    if (!mounted) return;
    setState(() {
      locationEnabled = true;
    });

    if (widget.initialSelectedEvent != null) return;

    final lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      _moveToPosition(lastKnownPosition, zoom: 13);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 4),
      );
      _moveToPosition(position, zoom: 13);
    } catch (_) {
      // The map is usable without a fresh GPS fix.
    }
  }

  void _moveToPosition(Position position, {required double zoom}) {
    if (!mounted || mapController == null) return;
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  Future<void> _focusOnUserLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    if (mounted && !locationEnabled) {
      setState(() {
        locationEnabled = true;
      });
    }

    final lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      _moveToPosition(lastKnownPosition, zoom: 15);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 4),
      );
      _moveToPosition(position, zoom: 15);
    } catch (_) {
      // Last known position is good enough if a fresh GPS fix times out.
    }
  }

  Set<int> get _savedEventIds =>
      SavedEventsManager.instance.savedEventIds.toSet();

  List<String> get availableCategories {
    final categories = widget.events
        .map((event) => event.category)
        .whereType<String>()
        .where((category) => category.trim().isNotEmpty)
        .toSet()
        .toList();
    categories.sort(
      (a, b) => _categoryLabel(a).compareTo(_categoryLabel(b)),
    );
    return categories;
  }

  @override
  void didUpdateWidget(covariant EventMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focusInitialEventIfReady();
  }

  void _focusInitialEventIfReady() {
    if (_didFocusInitialEvent || mapController == null) return;
    final initialEvent = widget.initialSelectedEvent;
    if (initialEvent == null) return;

    final event = widget.events.firstWhere(
      (event) => event.id == initialEvent.id,
      orElse: () => initialEvent,
    );

    _didFocusInitialEvent = true;
    setState(() {
      selectedEvent = event;
      showPlanOnly = false;
    });
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: event.position, zoom: 15),
      ),
    );
  }

  static String _categoryLabel(String category) {
    return categoryLabels[category] ?? category;
  }

  List<EventLocation> get visibleEvents {
    Iterable<EventLocation> events = widget.events;

    if (showPlanOnly) {
      final savedIds = _savedEventIds;
      events = events.where((event) => savedIds.contains(event.id));
    }

    if (selectedCategories.isNotEmpty) {
      events = events.where(
        (event) => selectedCategories.contains(event.category),
      );
    }

    return events.toList();
  }

  List<EventLocation> get searchResults {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return [];

    return visibleEvents.where((event) {
      return event.name.toLowerCase().contains(query) ||
          event.venue.toLowerCase().contains(query) ||
          event.address.toLowerCase().contains(query) ||
          (event.category?.toLowerCase().contains(query) ?? false) ||
          (event.category != null &&
              _categoryLabel(event.category!).toLowerCase().contains(query)) ||
          (event.district?.toLowerCase().contains(query) ?? false);
    }).take(6).toList();
  }

  Set<Marker> get markers {
    return visibleEvents.map((event) {
      final bool isSelected = selectedEvent?.id == event.id;

      return Marker(
        markerId: MarkerId(event.id.toString()),
        position: event.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected
              ? BitmapDescriptor.hueViolet
              : BitmapDescriptor.hueMagenta,
        ),
        onTap: () {
          setState(() {
            selectedEvent = event;
            searchQuery = '';
          });
          _searchController.clear();
        },
      );
    }).toSet();
  }

  void _setPlanFilter(bool value) {
    setState(() {
      showPlanOnly = value;
      _clearSelectedEventIfHidden();
    });
  }

  void _setSearchQuery(String value) {
    setState(() {
      searchQuery = value;
    });
  }

  void _selectSearchResult(EventLocation event) {
    FocusScope.of(context).unfocus();
    _searchController.text = event.name;
    setState(() {
      searchQuery = '';
      selectedEvent = event;
    });
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: event.position, zoom: 15),
      ),
    );
  }

  void _setCategories(Set<String> categories) {
    setState(() {
      selectedCategories = categories;
      _clearSelectedEventIfHidden();
    });
  }

  void _clearSelectedEventIfHidden() {
    if (selectedEvent != null &&
        !visibleEvents.any((event) => event.id == selectedEvent!.id)) {
      selectedEvent = null;
    }
  }

  Future<void> _openCategoryFilter() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: const Color(0xFF1B0030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return _CategoryFilterSheet(
          categories: availableCategories,
          selectedCategories: selectedCategories,
          categoryLabel: _categoryLabel,
        );
      },
    );

    if (result != null) {
      _setCategories(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SavedEventsManager.instance,
      builder: (context, child) {
        return SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _MapHeader(
                    controller: _searchController,
                    onChanged: _setSearchQuery,
                    onFilterTap: _openCategoryFilter,
                    activeFilterCount: selectedCategories.length,
                  ),
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: stockholm,
                        zoom: 12,
                      ),
                      onMapCreated: (controller) {
                        mapController = controller;
                        _focusInitialEventIfReady();
                      },
                      myLocationEnabled: locationEnabled,
                      myLocationButtonEnabled: false,
                      markers: markers,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                  ),
                ],
              ),

              if (widget.isLoading)
                const Positioned(
                  left: 16,
                  right: 16,
                  top: 88,
                  child: _MapStatus(message: 'Hämtar events...'),
                ),

              if (widget.error != null)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 88,
                  child: _MapError(
                    message: widget.error!,
                    onRetry: widget.onRetry,
                  ),
                ),

              if (searchResults.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 80,
                  child: _SearchResultsList(
                    events: searchResults,
                    onSelect: _selectSearchResult,
                  ),
                ),

              if (selectedEvent == null ||
                  !_hideMapControlsWhenEventSelected)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: selectedEvent == null
                      ? _mapControlBottom
                      : _selectedEventControlBottom,
                  child: _FilterBar(
                    showPlanOnly: showPlanOnly,
                    onShowAll: () => _setPlanFilter(false),
                    onShowPlan: () => _setPlanFilter(true),
                  ),
                ),

              if (selectedEvent == null ||
                  !_hideMapControlsWhenEventSelected)
                Positioned(
                  right: 16,
                  bottom: selectedEvent == null
                      ? _mapControlBottom
                      : _selectedEventControlBottom,
                  child: FloatingActionButton.small(
                    heroTag: 'focusUserLocation',
                    tooltip: 'Fokusera på min plats',
                    onPressed: _focusOnUserLocation,
                    backgroundColor: const Color(0xFF26003D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF662080)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.my_location),
                  ),
                ),

              if (selectedEvent != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _EventInfoCard(
                    event: selectedEvent!,
                    onClose: () {
                      setState(() {
                        selectedEvent = null;
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    required this.activeFilterCount,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B0030),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFFD84DFF),
              decoration: InputDecoration(
                hintText: 'Sök event',
                hintStyle: const TextStyle(color: Color(0xFFD4A4FF)),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFD4A4FF),
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.close),
                        color: const Color(0xFFD4A4FF),
                      ),
                filled: true,
                fillColor: const Color(0xFF26003D),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF662080)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF662080)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD84DFF)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            width: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IconButton(
                    tooltip: 'Filtrera kategori',
                    onPressed: onFilterTap,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF26003D),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF662080)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.tune),
                  ),
                ),
                if (activeFilterCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFD84DFF),
                      ),
                      child: Text(
                        activeFilterCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.events,
    required this.onSelect,
  });

  final List<EventLocation> events;
  final ValueChanged<EventLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF21B0030),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF662080)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: events.length,
          separatorBuilder: (context, index) {
            return const Divider(
              color: Color(0xFF3B0A57),
              height: 1,
            );
          },
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              dense: true,
              onTap: () => onSelect(event),
              leading: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFD84DFF),
              ),
              title: Text(
                event.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                event.venue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFD4A4FF)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.showPlanOnly,
    required this.onShowAll,
    required this.onShowPlan,
  });

  final bool showPlanOnly;
  final VoidCallback onShowAll;
  final VoidCallback onShowPlan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'Alla',
          selected: !showPlanOnly,
          onTap: onShowAll,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Min plan',
          selected: showPlanOnly,
          onTap: onShowPlan,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFD84DFF) : const Color(0xFF1B0030),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF662080)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterSheet extends StatefulWidget {
  const _CategoryFilterSheet({
    required this.categories,
    required this.selectedCategories,
    required this.categoryLabel,
  });

  final List<String> categories;
  final Set<String> selectedCategories;
  final String Function(String category) categoryLabel;

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late Set<String> selectedCategories;

  @override
  void initState() {
    super.initState();
    selectedCategories = {...widget.selectedCategories};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Filtrera kategori',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedCategories.clear();
                    });
                  },
                  child: const Text('Rensa'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Inga kategorier hittades.',
                  style: TextStyle(color: Color(0xFFD4A4FF)),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in widget.categories)
                        _CategoryChoice(
                          label: widget.categoryLabel(category),
                          selected: selectedCategories.contains(category),
                          onTap: () {
                            setState(() {
                              if (selectedCategories.contains(category)) {
                                selectedCategories.remove(category);
                              } else {
                                selectedCategories.add(category);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context, selectedCategories);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD84DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Visa resultat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: const Color(0xFF26003D),
      selectedColor: const Color(0xFFD84DFF),
      checkmarkColor: Colors.white,
      side: const BorderSide(color: Color(0xFF662080)),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MapStatus extends StatelessWidget {
  const _MapStatus({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE61B0030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF662080)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD84DFF),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapError extends StatelessWidget {
  const _MapError({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE61B0030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF662080)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Försök igen'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({
    required this.event,
    required this.onClose,
  });

  final EventLocation event;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SavedEventsManager.instance,
      builder: (context, child) {
        final bool isSaved = SavedEventsManager.instance.isSaved(event.id);

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1B0030),
            border: Border(
              top: BorderSide(color: Color(0xFF662080)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryBadge(label: event.category ?? 'Event'),
                  const SizedBox(width: 10),
                  Text(
                    event.timeStart ?? '',
                    style: const TextStyle(
                      color: Color(0xFFD84DFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      SavedEventsManager.instance.toggleSave(event.id);
                    },
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: const Color(0xFFD84DFF),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFD4A4FF),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.venue,
                      style: const TextStyle(
                        color: Color(0xFFD4A4FF),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (event.address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.address,
                  style: const TextStyle(
                    color: Color(0xFFBFA6D9),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3B0A57),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
