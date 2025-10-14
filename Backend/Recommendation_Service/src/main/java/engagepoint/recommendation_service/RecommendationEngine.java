package engagepoint.recommendation_service;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import engagepoint.recommendation_service.models.Post;
import java.util.ArrayList;
import java.util.HashMap;
import engagepoint.recommendation_service.models.User;
import engagepoint.recommendation_service.services.Interaction;

public class RecommendationEngine {
   List<Post> posts;

   public RecommendationEngine(List<Post> posts) {
       this.posts = posts;
   }

   public List<Post> recommendPosts(User user, int recommendations) {
        Map<Post, Double> postScores = new HashMap<>();
    
        List<String> userProfileCategories = new ArrayList<>();
        for (Post category : user.getPreferredCategories()) {
            userProfileCategories.addAll(category.getCategory());
        }

        for (Post post : posts) {
            if (!user.getPreferredCategories().contains(post)) {
                double score = Interaction.calculateInteractionScore(userProfileCategories, post.getCategory());
                postScores.put(post, score);
            }
        }

        List<Map.Entry<Post, Double>> sortedEntries = new ArrayList<>(postScores.entrySet());
        sortedEntries.sort(Entry.comparingByValue((a, b) -> Double.compare(b, a)));

        List<Post> recommendedPosts = new ArrayList<>();
        for (int i = 0; i < Math.min(recommendations, sortedEntries.size()); i++) {
            recommendedPosts.add(sortedEntries.get(i).getKey());
        }
        return recommendedPosts;
   }
}