package engagepoint.recommendation_service;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import engagepoint.recommendation_service.models.Post;
import java.util.Arrays;
import java.util.HashMap;
import engagepoint.recommendation_service.models.User;

public class RecommendationEngine {
    List<Post> posts = Arrays.asList(
        // list posts on user's feed user interacts with. use interaction to update recommendations based on interaction
    );

    Map<User, HashMap<Post, Double>> data = new HashMap<>();
    Map<Post, HashMap<Post, Integer>> freq = new HashMap<>();
    Map<Post, HashMap<Post, Double>> diff = new HashMap<>();
    Map<Post, Double> uPred = new HashMap<>();
    Map<Post, Integer> uFreq = new HashMap<>();

    public void processRecommendations() {
        for (HashMap<Post, Double> user : data.values()) {
            for (Entry<Post, Double> e : user.entrySet()) {
                if (!diff.containsKey(e.getKey())) {
                    diff.put(e.getKey(), new HashMap<Post, Double>());
                    freq.put(e.getKey(), new HashMap<Post, Integer>());
                }

                for (Entry<Post, Double> e2 : user.entrySet()) {
                    int oldCount = 0;
                    if (freq.get(e.getKey()).containsKey(e2.getKey())){
                        oldCount = freq.get(e.getKey()).get(e2.getKey()).intValue();
                    }

                    double oldDiff = 0.0;
                    if (diff.get(e.getKey()).containsKey(e2.getKey())){
                        oldDiff = diff.get(e.getKey()).get(e2.getKey()).doubleValue();
                    }
                    
                    double observedDiff = e.getValue() - e2.getValue();
                    freq.get(e.getKey()).put(e2.getKey(), oldCount + 1);
                    diff.get(e.getKey()).put(e2.getKey(), oldDiff + observedDiff);
                }
            }

            for (Entry<User, HashMap<Post, Double>> e : data.entrySet()) {
                for (Post j : e.getValue().keySet()) {
                    for (Post k : diff.keySet()) {
                        double predictedValue =
                        diff.get(k).get(j).doubleValue() + e.getValue().get(j).doubleValue();
                        double finalValue = predictedValue * freq.get(k).get(j).intValue();
                        uPred.put(k, uPred.get(k) + finalValue);
                        uFreq.put(k, uFreq.get(k) + freq.get(k).get(j).intValue());
                    }
                }
                HashMap<Post, Double> clean = new HashMap<Post, Double>();
                for (Post j : uPred.keySet()) {
                    if (uFreq.get(j) > 0) {
                        clean.put(j, uPred.get(j).doubleValue() / uFreq.get(j).intValue());
                    }
                }
                for (Post j : InputData.items) { //possibly need to change inputdata to interactions or something
                    if (e.getValue().containsKey(j)) {
                        clean.put(j, e.getValue().get(j));
                    } else if (!clean.containsKey(j)) {
                        clean.put(j, -1.0);
                    }
                }
            }
        }
    }
}