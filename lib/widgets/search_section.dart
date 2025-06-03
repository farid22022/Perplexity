import 'package:flutter/material.dart';
import 'package:perplexity/services/chat_web_service.dart';
import 'package:perplexity/theme/color.dart';
import 'package:perplexity/widgets/search_bar_button.dart';
import 'dart:convert';

class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> with SingleTickerProviderStateMixin {
  final queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final ChatWebService _chatWebService = ChatWebService();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);

    // Initialize WebSocket and listen for messages
    _chatWebService.connect();
    _chatWebService.messages.listen((message) {
      final data = json.decode(message);
      setState(() {
        _messages.add(data);
      });
      // Scroll to the latest message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
      if (data['type'] == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['data'],
              style: TextStyle(color: AppColors.whiteColor),
            ),
            backgroundColor: AppColors.cardColor,
          ),
        );
      }
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'WebSocket error: $error',
            style: TextStyle(color: AppColors.whiteColor),
          ),
          backgroundColor: AppColors.cardColor,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    queryController.dispose();
    _scrollController.dispose();
    _chatWebService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Black Jarvis',
          style: TextStyle(
            color: const Color.fromARGB(255, 228, 228, 228),
            fontSize: 40,
            fontWeight: FontWeight.w400,
            height: 2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 700,
          decoration: BoxDecoration(
            color: const Color.fromARGB(121, 32, 30, 41),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.searchBarBorder, width: 1.5),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: queryController,
                  decoration: InputDecoration(
                    hintText: 'Search anything...',
                    hintStyle: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(color: AppColors.whiteColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    SearchBarButton(
                      icon: Icons.auto_awesome_outlined,
                      text: 'Focus',
                    ),
                    const SizedBox(width: 12),
                    SearchBarButton(
                      icon: Icons.add_circle_outline,
                      text: 'Attach',
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTapDown: (_) => _controller.forward(),
                      onTapUp: (_) {
                        _controller.reverse();
                        if (queryController.text.trim().isNotEmpty) {
                          // Send query and add to messages
                          _chatWebService.chat(queryController.text.trim());
                          setState(() {
                            _messages.add({
                              'type': 'query',
                              'data': queryController.text.trim(),
                            });
                          });
                          queryController.clear();
                          // Scroll to the latest message
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter a search query',
                                style: TextStyle(color: AppColors.whiteColor),
                              ),
                              backgroundColor: AppColors.cardColor,
                            ),
                          );
                        }
                      },
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.submitButton,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: AppColors.background,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isQuery = message['type'] == 'query';
              final isError = message['type'] == 'error';
              return Align(
                alignment: isQuery ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isQuery
                        ? AppColors.submitButton
                        : isError
                            ? AppColors.cardColor
                            : AppColors.searchBar,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isQuery
                        ? message['data']
                        : isError
                            ? 'Error: ${message['data']}'
                            : message['data'],
                    style: TextStyle(
                      color: isQuery ? AppColors.background : AppColors.whiteColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}