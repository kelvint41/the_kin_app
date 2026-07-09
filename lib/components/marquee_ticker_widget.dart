import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marquee_ticker_model.dart';
export 'marquee_ticker_model.dart';

/// A dual-row, continuously-auto-scrolling Kindex ticker styled like a
/// financial news ticker - top row is business Kindex scores (name,
/// score, trend arrow), bottom row is customer Kindex scores (ticker
/// symbol, score, trend arrow).
class MarqueeTickerWidget extends StatefulWidget {
  const MarqueeTickerWidget({
    super.key,
    required this.businessEntries,
    required this.customerEntries,
    this.rowHeight = 28.0,
    this.pixelsPerSecond = 40.0,
  });

  final List<KindexTickerEntry> businessEntries;
  final List<KindexTickerEntry> customerEntries;
  final double rowHeight;
  final double pixelsPerSecond;

  @override
  State<MarqueeTickerWidget> createState() => _MarqueeTickerWidgetState();
}

class _MarqueeTickerWidgetState extends State<MarqueeTickerWidget>
    with SingleTickerProviderStateMixin {
  late MarqueeTickerModel _model;
  late final Ticker _ticker;
  final ScrollController _topController = ScrollController();
  final ScrollController _bottomController = ScrollController();
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MarqueeTickerModel());
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _topController.dispose();
    _bottomController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) {
      _lastElapsed = elapsed;
      return;
    }
    final deltaSeconds = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _advance(_topController, widget.businessEntries, deltaSeconds);
    _advance(_bottomController, widget.customerEntries, deltaSeconds);
  }

  void _advance(
    ScrollController controller,
    List<KindexTickerEntry> entries,
    double deltaSeconds,
  ) {
    // ListView.builder cycles entries via index % length (see
    // _MarqueeRow.build), so there's no natural end to jump back to - the
    // offset just grows forever. That's fine for how long this screen
    // stays open.
    if (!controller.hasClients || entries.isEmpty) return;
    controller
        .jumpTo(controller.offset + widget.pixelsPerSecond * deltaSeconds);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.businessEntries.isEmpty && widget.customerEntries.isEmpty) {
      return SizedBox(height: widget.rowHeight * 2);
    }

    return Container(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MarqueeRow(
            controller: _topController,
            entries: widget.businessEntries,
            height: widget.rowHeight,
          ),
          Container(height: 1.0, color: Colors.white12),
          _MarqueeRow(
            controller: _bottomController,
            entries: widget.customerEntries,
            height: widget.rowHeight,
          ),
        ],
      ),
    );
  }
}

class _MarqueeRow extends StatelessWidget {
  const _MarqueeRow({
    required this.controller,
    required this.entries,
    required this.height,
  });

  final ScrollController controller;
  final List<KindexTickerEntry> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final entry = entries[index % entries.length];
          return _MarqueeItem(entry: entry);
        },
      ),
    );
  }
}

class _MarqueeItem extends StatelessWidget {
  const _MarqueeItem({required this.entry});

  final KindexTickerEntry entry;

  @override
  Widget build(BuildContext context) {
    final trendColor = entry.isTrendingUp
        ? FlutterFlowTheme.of(context).success
        : FlutterFlowTheme.of(context).error;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            entry.name.toUpperCase(),
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  color: Colors.white,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8.0),
          Text(
            entry.score.toStringAsFixed(0),
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                  color: Colors.white70,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 4.0),
          Icon(
            entry.isTrendingUp
                ? Icons.arrow_drop_up_rounded
                : Icons.arrow_drop_down_rounded,
            color: trendColor,
            size: 20.0,
          ),
          const SizedBox(width: 16.0),
          Container(
            width: 1.0,
            height: 12.0,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }
}
