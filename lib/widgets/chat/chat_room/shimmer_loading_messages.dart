import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerMessageList extends StatelessWidget {

  const ShimmerMessageList({
    super.key,

  });
final int count = 11 ;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = count.isEven
        ? Colors.grey.withOpacity(0.3)
        : Colors.grey.withOpacity(0.2);
    final highlight = count.isEven
        ? Colors.grey.withOpacity(0.4)
        : Colors.grey.withOpacity(0.3);

    return ListView.builder(
      itemCount: 11,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0; // Alternate between sender and receiver
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Message Bubble
              Flexible(
                child: Column(
                  crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: base,
                      highlightColor: highlight,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? base : highlight, // Differentiate sender/receiver
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight:
                            isMe ? Radius.zero : const Radius.circular(16),
                            bottomLeft:
                            isMe ? const Radius.circular(16) : Radius.zero,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          height: 16 + (index % 3) * 10, // Vary height slightly
                          decoration: BoxDecoration(
                            color: isMe ? highlight : base, // Inner shimmer contrast
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Timestamp Placeholder
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}