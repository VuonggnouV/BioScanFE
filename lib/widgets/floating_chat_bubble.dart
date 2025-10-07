// lib/widgets/floating_chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bioscan/services/chat_bubble_notifier.dart';
import 'package:bioscan/theme/colors.dart' as app_colors;

class FloatingChatBubble extends StatelessWidget {
  const FloatingChatBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatBubbleNotifier>(
      builder: (context, notifier, child) {
        if (!notifier.isBubbleVisible) {
          return const SizedBox.shrink();
        }
        
        if (notifier.isChatOpen) {
          final screenSize = MediaQuery.of(context).size;
          final chatWindowWidth = screenSize.width * 0.9;
          final bubbleX = notifier.position.dx;
          
          double chatWindowX = bubbleX - (chatWindowWidth / 2) + 25;

          if (chatWindowX < 10) chatWindowX = 10;
          if (chatWindowX + chatWindowWidth > screenSize.width - 10) {
            chatWindowX = screenSize.width - chatWindowWidth - 10;
          }
          
          double chatWindowY = (screenSize.height - (screenSize.height * 0.6)) / 2;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: notifier.toggleChat,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),
              Positioned(
                top: chatWindowY,
                left: chatWindowX,
                child: _buildChatWindow(context),
              ),
            ],
          );
        } else {
          return Stack(
            children: [
              Positioned(
                left: notifier.position.dx,
                top: notifier.position.dy,
                child: Draggable(
                  feedback: _buildBubble(context),
                  childWhenDragging: const SizedBox.shrink(),
                  onDragEnd: (details) => _updateDragPosition(details, context, notifier),
                  child: _buildBubble(context),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  void _updateDragPosition(DraggableDetails details, BuildContext context, ChatBubbleNotifier notifier) {
      final size = MediaQuery.of(context).size;
      double newX = details.offset.dx;
      double newY = details.offset.dy;
      if (newX < 0) newX = 0;
      if (newY < 0) newY = 0;
      if (newX > size.width - 50) newX = size.width - 50;
      if (newY > size.height - 50) newY = size.height - 50;
      notifier.updatePosition(Offset(newX, newY));
  }

  Widget _buildBubble(BuildContext context) {
    final notifier = Provider.of<ChatBubbleNotifier>(context, listen: false);
    return FloatingActionButton(
      onPressed: notifier.toggleChat,
      backgroundColor: app_colors.primaryButton,
      child: const Icon(Icons.smart_toy, color: Colors.white),
    );
  }
  
  Widget _buildChatWindow(BuildContext context) {
    final notifier = Provider.of<ChatBubbleNotifier>(context);
    final screenSize = MediaQuery.of(context).size;
    final textController = TextEditingController();

    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 8,
      child: Container(
        height: screenSize.height * 0.6,
        width: screenSize.width * 0.9,
        decoration: BoxDecoration(
          color: app_colors.background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: app_colors.primaryButton,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trợ lý AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: notifier.toggleChat,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: notifier.messages.length,
                itemBuilder: (context, index) {
                  final message = notifier.messages[index];
                   return Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: message.isUser ? app_colors.primaryButton : app_colors.formBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(color: message.isUser ? app_colors.textLight : app_colors.textDark),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (notifier.isLoading) const LinearProgressIndicator(),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      onSubmitted: (value) {
                          notifier.sendMessage(value);
                          textController.clear();
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi...',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: app_colors.textLight),
                    onPressed: () {
                        notifier.sendMessage(textController.text);
                        textController.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}