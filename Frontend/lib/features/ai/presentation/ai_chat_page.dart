import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../stock/data/api_base.dart';
import '../data/ai_repository.dart';

class AiChatPage extends StatefulWidget {
  final String? stockCode;
  const AiChatPage({super.key, this.stockCode});
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _repo = AiRepository();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _loading = false;
  bool _ollamaOk = false;
  String _ollamaModel = '';
  bool _statusChecked = false;

  @override
  void initState() {
    super.initState();
    _checkOllama();
  }

  Future<void> _checkOllama() async {
    try {
      final d = await apiGet('/api/ai-advisor/ollama-status');
      final ok = d['ok'] == true;
      String model = '';
      if (ok && d['models'] != null) {
        final models = (d['models']['models'] as List? ?? []);
        if (models.isNotEmpty) {
          model = models.first['name'] ?? '';
        }
      }
      if (mounted) {
        setState(() {
          _ollamaOk = ok;
          _ollamaModel = model;
          _statusChecked = true;
        });
        _messages.add(_ChatMsg(
          role: 'assistant',
          text: ok
              ? '✅ Ollama接続OK（モデル: ${model.isNotEmpty ? model : "検出済み"}）\n\n'
                  '${widget.stockCode != null ? "【${widget.stockCode}】について" : "ポートフォリオや銘柄について"}何でも質問してください。\n\n'
                  '※投資助言ではなく学習用のサポートです。'
              : '⚠️ Ollamaに接続できませんでした。\n\n'
                  '以下を確認してください：\n'
                  '1. ollama serve が起動しているか\n'
                  '2. モデルがインストールされているか\n'
                  '   → ollama pull qwen2.5:1.5b\n'
                  '3. BackendがOllamaと同じPCで動いているか',
        ));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() { _ollamaOk = false; _statusChecked = true; });
        _messages.add(_ChatMsg(role: 'assistant', text: '⚠️ Ollama状態確認中にエラーが発生しました。\nBackendが起動しているか確認してください。'));
        setState(() {});
      }
    }
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _loading) return;
    setState(() {
      _messages.add(_ChatMsg(role: 'user', text: msg));
      _loading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();
    try {
      final reply = await _repo.chat(msg, stockCode: widget.stockCode);
      if (mounted) setState(() => _messages.add(_ChatMsg(role: 'assistant', text: reply)));
    } catch (e) {
      if (mounted) setState(() => _messages.add(_ChatMsg(
          role: 'assistant',
          text: 'エラー: ${e.toString().replaceFirst("Exception: ", "")}')));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Widget _bubble(_ChatMsg m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10, left: isUser ? 50 : 0, right: isUser ? 0 : 50),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(m.text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, height: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/ai-advisor'), icon: const Icon(Icons.arrow_back)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AIチャット', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_statusChecked)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_ollamaOk ? Icons.circle : Icons.circle, size: 8,
                  color: _ollamaOk ? Colors.green : Colors.red),
              const SizedBox(width: 4),
              Text(
                _ollamaOk ? 'Ollama: $_ollamaModel' : 'Ollama: 未接続',
                style: TextStyle(fontSize: 11, color: _ollamaOk ? Colors.green[700] : Colors.red),
              ),
            ]),
        ]),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Ollama再確認',
            onPressed: () { setState(() { _statusChecked = false; }); _checkOllama(); },
          ),
        ],
      ),
      body: Column(children: [
        if (!_statusChecked)
          const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: CircleAvatar(
                      radius: 16, backgroundColor: Colors.white,
                      child: SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)))));
              }
              return _bubble(_messages[i]);
            },
          ),
        ),
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(
              left: 16, right: 8, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                enabled: _ollamaOk || !_statusChecked,
                decoration: InputDecoration(
                  hintText: _ollamaOk ? '質問を入力…' : 'Ollamaが未接続です',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
                maxLines: 3, minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _ollamaOk ? _send : null,
              icon: Icon(Icons.send,
                  color: _ollamaOk ? const Color(0xFF2563EB) : Colors.grey),
              iconSize: 28,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ChatMsg {
  final String role, text;
  _ChatMsg({required this.role, required this.text});
}
