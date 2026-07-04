import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'local_sparkline_model.dart';
export 'local_sparkline_model.dart';

class LocalSparklineWidget extends StatefulWidget {
  const LocalSparklineWidget({
    super.key,
    this.data,
  });

  final String? data;

  @override
  State<LocalSparklineWidget> createState() => _LocalSparklineWidgetState();
}

class _LocalSparklineWidgetState extends State<LocalSparklineWidget> {
  late LocalSparklineModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalSparklineModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60.0,
      height: 24.0,
      child: FlutterFlowLineChart(
        data: [
          FFLineChartData(
            xData: ([0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0])!,
            yData: ([10.0, 12.0, 11.0, 14.0, 18.0, 17.0, 22.0])!,
            settings: LineChartBarData(
              color: FlutterFlowTheme.of(context).primary,
              barWidth: 2.0,
              isCurved: true,
              dotData: FlDotData(show: false),
            ),
          )
        ],
        chartStylingInfo: ChartStylingInfo(
          backgroundColor: Colors.transparent,
          showBorder: false,
        ),
        axisBounds: AxisBounds(
          minY: 0.0,
          maxY: 26.4,
        ),
        xAxisLabelInfo: AxisLabelInfo(
          showLabels: true,
          labelTextStyle: TextStyle(
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
          reservedSize: 32.0,
        ),
        yAxisLabelInfo: AxisLabelInfo(),
      ),
    );
  }
}
