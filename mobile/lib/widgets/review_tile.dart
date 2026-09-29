import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/format.dart';
import 'star_rating.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.title, this.trailing, this.onTap});

  final Review review;

  /// Replaces the reviewer's name, e.g. with "Pad Thai · Thai Orchid Kitchen".
  final String? title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(review.user.initials, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title ?? review.user.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StarRating(rating: review.rating.toDouble(), size: 14),
                      const SizedBox(width: 8),
                      Text(timeAgo(review.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                  ),
                  if (review.body != null) ...[
                    const SizedBox(height: 6),
                    Text(review.body!, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
