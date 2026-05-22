import '/components/cinematic_reel_widget.dart';
import '/components/ticker_pulse_item2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'page1_welcome_mission_copy2_widget.dart'
    show Page1WelcomeMissionCopy2Widget;
import 'package:flutter/material.dart';

class Page1WelcomeMissionCopy2Model
    extends FlutterFlowModel<Page1WelcomeMissionCopy2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for CinematicReel component.
  late CinematicReelModel cinematicReelModel;
  // Model for TickerPulseItem2 component.
  late TickerPulseItem2Model tickerPulseItem2Model1;
  // Model for TickerPulseItem2 component.
  late TickerPulseItem2Model tickerPulseItem2Model2;
  // Model for TickerPulseItem2 component.
  late TickerPulseItem2Model tickerPulseItem2Model3;
  // Model for TickerPulseItem2 component.
  late TickerPulseItem2Model tickerPulseItem2Model4;

  @override
  void initState(BuildContext context) {
    cinematicReelModel = createModel(context, () => CinematicReelModel());
    tickerPulseItem2Model1 =
        createModel(context, () => TickerPulseItem2Model());
    tickerPulseItem2Model2 =
        createModel(context, () => TickerPulseItem2Model());
    tickerPulseItem2Model3 =
        createModel(context, () => TickerPulseItem2Model());
    tickerPulseItem2Model4 =
        createModel(context, () => TickerPulseItem2Model());
  }

  @override
  void dispose() {
    cinematicReelModel.dispose();
    tickerPulseItem2Model1.dispose();
    tickerPulseItem2Model2.dispose();
    tickerPulseItem2Model3.dispose();
    tickerPulseItem2Model4.dispose();
  }
}
