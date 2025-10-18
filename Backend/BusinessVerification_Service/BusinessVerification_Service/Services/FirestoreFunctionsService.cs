using BusinessVerification_Service.Interfaces;
using Google.Cloud.Firestore;

namespace BusinessVerification_Service.Services
{
    public class FirestoreFunctionsService : IFirestoreFunctionsService
    {
        // Injected dependencies
        private readonly ILogger<FirestoreFunctionsService> _logger;
        private readonly FirestoreDb _firestoreDb;

        // Constructor for dependency injection
        public FirestoreFunctionsService(ILogger<FirestoreFunctionsService> logger, FirestoreDb firestoreDb)
        {
            _logger = logger;
            _firestoreDb = firestoreDb;
        }
    }
}
