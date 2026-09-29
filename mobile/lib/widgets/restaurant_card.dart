import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'star_rating.dart';

/// A restaurant in search results with the rating of each searched dish.
class RestaurantResultCard extends StatelessWidget {
  const RestaurantResultCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.onDishTap,
  });

  final Restaurant restaurant;
  final VoidCallback onTap;
  final ValueChanged<RestaurantDish> onDishTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      restaurant.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (restaurant.distanceMiles != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_outlined, size: 16, color: muted),
                          const SizedBox(width: 2),
                          Text(formatDistance(restaurant.distanceMiles), style: theme.textTheme.labelLarge),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(restaurant.fullAddress, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              const SizedBox(height: 6),
              RatingSummary(rating: restaurant.rating, reviewsCount: restaurant.reviewsCount),
              if (restaurant.dishes.isNotEmpty) ...[
                const Divider(height: 16),
                for (final dish in restaurant.dishes)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onDishTap(dish),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu, size: 16, color: brandColor),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dish.name, style: theme.textTheme.bodyMedium)),
                          RatingSummary(
                            rating: dish.averageRating,
                            reviewsCount: dish.reviewsCount,
                            size: 14,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
