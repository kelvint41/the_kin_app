import '/components/main_menu_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'support_chat_model.dart';
export 'support_chat_model.dart';

/// In-app support chat: answers questions about how KIN works and doubles
/// as the suggestions/comments intake mechanism - every message is
/// classified and logged server-side (see sendSupportChatMessage /
/// support_chat.js), whether it turns out to be a question, a bug report,
/// or a suggestion. There's no separate feedback form; a "suggestion" here
/// is just a message the model tagged that way, so it lands in the same
/// place an admin already reviews (see [SupportChatStats] on the Executive
/// Dashboard) instead of a second, disconnected inbox.
///
/// Reachable from Owner Profile's "Get Support" action and Customer
/// Profile's support row - see those pages for the entry points.
class SupportChatWidget extends StatefulWidget {
  const SupportChatWidget({super.key});

  static String routeName = 'SupportChat';
  static String routePath = '/supportChat';

  @override
  State<SupportChatWidget> createState() => _SupportChatWidgetState();
}

class _SupportChatWidgetState extends State<SupportChatWidget> {
  late SupportChatModel _model;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  // Client-generated, threads this session's exchanges together in
  // support_chat_logs without identifying anything about the device -
  // purely a grouping key.
  final _conversationId = const Uuid().v4();

  final List<SupportChatTurn> _turns = [];
  bool _sending = false;
  String? _error;

  // Asked once per chat session (this page has no cross-session state to
  // begin with - _conversationId is freshly generated every time this
  // widget is created) rather than pulled from the user's profile display
  // name, which is frequently empty - this is what actually got the admin
  // dashboard a name to show against a conversation.
  String? _visitorName;
  bool get _needsName => _visitorName == null;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportChatModel());
    _turns.add(SupportChatTurn(
      role: 'assistant',
      text: "Hi! Before we get started, what's your first name? "
          "(Last name's optional.)",
    ));
  }

  @override
  void dispose() {
    _model.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    if (_needsName) {
      // No AI call for this turn - capturing a name doesn't need a model,
      // and burning a Gemini call on it would only slow down the one
      // thing every visitor has to get through before they can actually
      // ask their question.
      final name = text.split(RegExp(r'\s+')).first;
      safeSetState(() {
        _turns.add(SupportChatTurn(role: 'user', text: text));
        _visitorName = name;
        _inputController.clear();
        _turns.add(SupportChatTurn(
          role: 'assistant',
          text: 'Thanks, $name! What can I help with?',
        ));
      });
      _scrollToEnd();
      return;
    }

    safeSetState(() {
      _turns.add(SupportChatTurn(role: 'user', text: text));
      _inputController.clear();
      _sending = true;
      _error = null;
    });
    _scrollToEnd();

    final result = await KinServices.sendSupportChatMessage(
      message: text,
      conversationId: _conversationId,
      visitorName: _visitorName,
      // Prior turns only - the message just added isn't context for
      // itself.
      history: _turns.sublist(0, _turns.length - 1),
    );

    if (!mounted) return;
    safeSetState(() {
      _sending = false;
      if (result.isSuccess) {
        _turns.add(result.data!);
      } else {
        _error = result.error;
      }
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'Get Support',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: MainMenuButton(),
        )],
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16.0),
                itemCount: _turns.length + (_sending ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _turns.length) return _typingBubble(theme);
                  return _bubble(theme, _turns[i]);
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: theme.bodySmall.override(color: theme.error),
                  ),
                ),
              ),
            _inputBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _bubble(FlutterFlowTheme theme, SupportChatTurn turn) {
    final isUser = turn.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.0),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? theme.primary : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          turn.text,
          style: theme.bodyMedium.override(
            // The user bubble's fill is theme.primary, a fixed dark green
            // that doesn't change between light/dark mode. accentOnSurface
            // flips to a deliberately darkened gold in light mode (tuned
            // for AA contrast on light backgrounds elsewhere), which reads
            // as near-invisible on this dark fill (2.05:1). accent1 is the
            // brand gold, fixed bright in both themes, and holds 5.8:1
            // against this specific green (0x0B3D2E) in both modes.
            color: isUser ? theme.accent1 : theme.primaryText,
            lineHeight: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _typingBubble(FlutterFlowTheme theme) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: 10.0),
          padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: SizedBox(
            width: 16.0,
            height: 16.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(theme.secondaryText),
            ),
          ),
        ),
      );

  Widget _inputBar(FlutterFlowTheme theme) => Padding(
        padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0,
            MediaQuery.of(context).padding.bottom + 12.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: _needsName ? 'Your first name...' : 'Type a message...',
                  hintStyle: theme.bodySmall.override(color: theme.hint),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                style: theme.bodyMedium.override(color: theme.primaryText),
              ),
            ),
            SizedBox(width: 8.0),
            InkWell(
              onTap: _sending ? null : _send,
              borderRadius: BorderRadius.circular(999.0),
              child: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: _sending ? theme.alternate : theme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.arrow_upward_rounded,
                    color: theme.accent1, size: 20.0),
              ),
            ),
          ],
        ),
      );
}
