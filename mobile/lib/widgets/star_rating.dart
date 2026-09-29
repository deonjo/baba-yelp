import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';

/// Read-only stars, with half stars for fractional ratings.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});

  final double? rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = rating ?? 0;
    final emptyColor = Theme.of(context).colorScheme.outlineVariant;
    return Semantics(
      label: rating == null ? 'No ratings yet' : '${formatRating(rating)} out of 5 stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++)
              Icon(
                value >= i + 0.75
                    ? Icons.star_rounded
                    : value >= i + 0.25
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                size: size,
                color: rating == null ? emptyColor : starColor,
              ),
          ],
        ),
      ),
    );
  }
}

/// Stars followed by "4.5 · 23 reviews" (or "No reviews yet").
class RatingSummary extends StatelessWidget {
  const RatingSummary({
    super.key,
    required this.rating,
    required this.reviewsCount,
    this.size = 16,
    this.compact = false,
  });

  final double? rating;
  final int reviewsCount;
  final double size;

  /// "4.5 (23)" instead of "4.5 · 23 reviews".
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final String detail;
    if (reviewsCount == 0 || rating == null) {
      detail = 'No reviews yet';
    } else if (compact) {
      detail = '${formatRating(rating)} ($reviewsCount)';
    } else {
      detail = '${formatRating(rating)} · ${pluralize(reviewsCount, 'review')}';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(rating: reviewsCount == 0 ? null : rating, size: size),
        const SizedBox(width: 6),
        Text(detail, style: textTheme.bodyMedium?.copyWith(color: muted)),
      ],
    );
  }
}

/// Tap a star to pick a 1–5 rating.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  /// 0 when nothing is picked yet.
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var stars = 1; stars <= 5; stars++)
              Semantics(
                button: true,
                selected: stars == value,
                label: pluralize(stars, 'star'),
                child: IconButton(
                  key: ValueKey('star-$stars'),
                  tooltip: pluralize(stars, 'star'),
                  iconSize: size,
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                  onPressed: () => onChanged(stars),
                  icon: Icon(
                    stars <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: stars <= value ? starColor : outline,
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(
            ratingLabels[value.clamp(0, 5)],
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

/// Horizontal bars showing how many reviews gave each star rating.
class RatingDistribution extends StatelessWidget {
  const RatingDistribution({super.key, required this.distribution});

  final Map<int, int> distribution;

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var stars = 5; stars >= 1; stars--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 14, child: Text('$stars')),
                const Icon(Icons.star_rounded, size: 14, color: starColor),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : (distribution[stars] ?? 0) / total,
                      minHeight: 8,
                      color: starColor,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text('${distribution[stars] ?? 0}', textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
