import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'dart:typed_data'; // For Web Bytes
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int applicationId;
  final String jobTitle;

  const ChatScreen({super.key, required this.applicationId, required this.jobTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  int? _currentUserId;
  bool _showEmoji = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    try {
      final user = await ApiService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUserId = user['id']);
      }
      _loadMessages();
    } catch (e) {
      print("Error initializing chat: $e");
    }
  }

  void _loadMessages() async {
    try {
      final msgs = await ApiService.getMessages(widget.applicationId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      print("Error loading messages: $e");
    }
  }

  void _sendMessage({String? content, String? filePath, Uint8List? fileBytes, String? fileName}) async {
    if ((content == null || content.isEmpty) && filePath == null && fileBytes == null) return;
    
    try {
      await ApiService.sendMessage(
        applicationId: widget.applicationId, 
        content: content ?? "",
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName
      );
      _messageController.clear();
      _loadMessages();
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send")));
      }
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      final file = result.files.single;
      if (foundation.kIsWeb) {
        _sendMessage(fileBytes: file.bytes, fileName: file.name);
      } else {
        _sendMessage(filePath: file.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(widget.jobTitle, style: TextStyle(color: Colors.white)),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == _currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
            ),
            _buildInputArea(),
            if (_showEmoji)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      _messageController.text = _messageController.text + emoji.emoji;
                    });
                  },
                  // UPDATED CONFIG FOR v6.0+
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
                      backgroundColor: const Color(0xFF202020),
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      initCategory: Category.RECENT,
                      backgroundColor: const Color(0xFF202020),
                      indicatorColor: Color(0xFFD4FF00),
                      iconColor: Colors.grey,
                      iconColorSelected: Color(0xFFD4FF00),
                      tabBarHeight: 46.0,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: const Color(0xFF202020),
                      buttonColor: const Color(0xFF202020),
                      buttonIconColor: Colors.white70,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: const Color(0xFF202020),
                      buttonIconColor: Colors.white70,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    final hasAttachment = msg['attachment_url'] != null;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFFD4FF00) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAttachment)
              Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attachment, size: 20, color: isMe ? Colors.black : Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Attachment", 
                      style: TextStyle(
                        color: isMe ? Colors.black : Colors.white,
                        fontStyle: FontStyle.italic
                      )
                    ),
                  ],
                ),
              ),
            if (msg['content'] != null && msg['content'].isNotEmpty)
              Text(
                msg['content'],
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w500
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: Color(0xFFD4FF00)),
            onPressed: _pickFile,
          ),
          IconButton(
            icon: Icon(Icons.emoji_emotions_outlined, color: Colors.white70),
            onPressed: () {
              setState(() => _showEmoji = !_showEmoji);
              FocusScope.of(context).unfocus();
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              onTap: () => setState(() => _showEmoji = false),
              decoration: InputDecoration(
                hintText: "Type message...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Color(0xFFD4FF00)),
            onPressed: () => _sendMessage(content: _messageController.text),
          ),
        ],
      ),
    );
  }
}