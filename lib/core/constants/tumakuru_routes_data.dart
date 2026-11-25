import '../../models/trip_models.dart';
import 'transit_catalog.dart';

class TumakuruTransitMasterData {
  static const String depotMain = TransitCatalog.depotMain;
  static const String depotNorth = TransitCatalog.depotNorth;

  static List<TransitStop> get allStops => TransitCatalog.cr101Stops;
  static List<TransitRoute> get sampleRoutes => TransitCatalog.sampleRoutes;
}
