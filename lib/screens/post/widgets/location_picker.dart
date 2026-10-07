import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/post_provider.dart';
import '../../../services/location_service.dart';

/// Data returned by [LocationPickerWidget] when the user confirms a location.
class PickedLocation {
  final String address;
  final GeoPoint geoPoint;

  const PickedLocation({required this.address, required this.geoPoint});
}

/// Location picker widget — Places Autocomplete search bar that
/// lets the user type an address/place name, pick from suggestions,
/// and returns the resolved coordinates + formatted address.
class LocationPickerWidget extends ConsumerStatefulWidget {
  /// Currently picked location (for pre-filling in edit mode).
  final PickedLocation? initial;

  /// Called when the user selects a place from the suggestions.
  final ValueChanged<PickedLocation> onPicked;

  const LocationPickerWidget({
    super.key,
    this.initial,
    required this.onPicked,
  });

  @override
  ConsumerState<LocationPickerWidget> createState() =>
      _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends ConsumerState<LocationPickerWidget> {
  final _searchCtrl = TextEditingController();
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _resolved = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _searchCtrl.text = widget.initial!.address;
      _resolved = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    // If user starts editing after selecting, reset resolved state
    if (_resolved) {
      setState(() => _resolved = false);
    }

    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _loading = true);
      final results =
          await ref.read(locationServiceProvider).searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      }
    });
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    setState(() {
      _loading = true;
      _suggestions = [];
    });

    final detail =
        await ref.read(locationServiceProvider).getPlaceDetails(suggestion.placeId);

    if (detail != null && mounted) {
      _searchCtrl.text = detail.formattedAddress;
      final picked = PickedLocation(
        address: detail.formattedAddress,
        geoPoint: GeoPoint(detail.lat, detail.lng),
      );
      widget.onPicked(picked);
      setState(() {
        _resolved = true;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search field ──────────────────────────────────────
        TextFormField(
          controller: _searchCtrl,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Search for a place...',
            prefixIcon: Icon(
              _resolved
                  ? Icons.check_circle_rounded
                  : Icons.location_on_outlined,
              color: _resolved ? theme.colorScheme.primary : null,
            ),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _suggestions = [];
                            _resolved = false;
                          });
                        },
                      )
                    : null,
          ),
          validator: (_) =>
              !_resolved ? 'Please select a location from the list.' : null,
        ),

        // ── Suggestions dropdown ─────────────────────────────
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = _suggestions[i];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.place_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  title: Text(
                    s.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  onTap: () => _onSuggestionTap(s),
                );
              },
            ),
          ),
      ],
    );
  }
}
