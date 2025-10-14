package engagepoint.recommendation_service;

import engagepoint.recommendation_service.models.User;
import engagepoint.recommendation_service.services.Interaction;

public class Main {
    public static void main(String[] args) {
        User user = new User();
        user.getUsername();

        Interaction interaction = new Interaction();
        interaction.logInteraction("", "", "");

        RecommendationEngine engine = new RecommendationEngine();
        engine.getRecommendationsForUser(user); 

        // display recommended postsb for the user
    }
}