package engagepoint.recommendation_service.models;

public class Business {
    public String businessName;
    public String category;

    public Business() {
        // Default constructor required for calls to DataSnapshot.getValue(Business.class)
    }

    public Business(String name, String category) {
        this.businessName = name;
        this.category = category;
    }

    public String getBusinessName() {
        return businessName;
    }

    public String getCategory() {
        return category;
    }

    public void setBusinessName(String name) {
        this.businessName = name;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    @Override
    public String toString() {
        return "Business{" +
                "name='" + businessName + '\'' +
                ", category='" + category + '\'' +
                '}';
    }
}