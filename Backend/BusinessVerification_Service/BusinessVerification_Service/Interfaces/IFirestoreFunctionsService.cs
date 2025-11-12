using BusinessVerification_Service.Dtos;

namespace BusinessVerification_Service.Interfaces
{
    // Interface for dependency injection of the Firestore functions services
    public interface IFirestoreFunctionsService
    {
        Task WriteVerificationRequest(DomainVerificationFirebaseResponseDto firestoreRequestDto);
    }
}
