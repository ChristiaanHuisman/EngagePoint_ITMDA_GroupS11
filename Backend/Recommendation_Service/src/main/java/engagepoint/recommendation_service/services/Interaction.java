package engagepoint.recommendation_service.services;

import java.util.List;
import java.util.Set;

import engagepoint.recommendation_service.models.User;

public class Interaction {
    private String interactionType;

    public static double calculateInteractionScore(List<String> userCategories, List<String> postCategories) {
        Set<String> userCategorySet = Set.copyOf(userCategories);
        Set<String> postCategorySet = Set.copyOf(postCategories);

        Set<String> intersection = userCategorySet.stream()
                .filter(postCategorySet::contains)
                .collect(java.util.stream.Collectors.toSet());

        if (userCategorySet.isEmpty()) {
            return 0.0;
        }
        return (double) intersection.size() / userCategorySet.size();
    }

    public static void logInteraction(String userId, String postId, String interactionType) {
       User user = new User();
       user.addPreferredCategory(null);
    }
}