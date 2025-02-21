import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerMessageList extends StatelessWidget {
  const ShimmerMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Number of placeholder items
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0; // Alternate alignment for visual effect
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 20 + (index % 2) * 10, // Vary heights for realism
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12).copyWith(
                    bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                    bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
