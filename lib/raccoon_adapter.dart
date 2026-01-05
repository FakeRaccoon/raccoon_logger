import 'package:raccoon/raccoon_service.dart';

/// Convenience mixin that exposes the shared [RaccoonService] instance.
mixin RaccoonAdapter {
  RaccoonService get service => RaccoonService();
}
