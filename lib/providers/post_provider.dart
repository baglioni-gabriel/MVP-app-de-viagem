import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location_service.dart';

// ─── Location service singleton ──────────────────────────────────────

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// ─── Post provider ───────────────────────────────────────────────────
// Post-creation logic is handled directly in the create_post_screen
// (imperative flow: validate → upload image → write doc → navigate back).
//
// This file exposes the service provider and will be expanded in
// Phase 4 with feed/stream providers.
