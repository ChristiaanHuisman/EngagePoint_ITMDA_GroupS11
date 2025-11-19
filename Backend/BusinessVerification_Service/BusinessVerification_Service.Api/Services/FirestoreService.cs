using BusinessVerification_Service.Api.Interfaces.ServicesInterfaces;
using Google.Cloud.Firestore;

namespace BusinessVerification_Service.Api.Services
{
    public class FirestoreService : IFirestoreService
    {
        // Inject dependencies
        private readonly FirestoreDb _firestoreDb;

        // Constructor for dependency injection
        public FirestoreService(FirestoreDb firestoreDb)
        {
            _firestoreDb = firestoreDb;
        }

        // Generic method
        //
        // Need to carefully specify path to document when calling the method
        //
        // Retrieve relevant model from Firestore spcified document
        public async Task<T?> GetDocumentFromFirestore<T>(string documentPath)
            where T : class
        {
            try
            {
                // Get a snapshot of the specific Firestore document
                DocumentReference documentReference = _firestoreDb.Document(documentPath);
                DocumentSnapshot documentSnapshot = await
                    documentReference.GetSnapshotAsync();
                if (!documentSnapshot.Exists)
                {
                    return null;
                }

                // Return the dictionary as the relevant model
                return documentSnapshot.ConvertTo<T>();
            }
            catch
            {
                // If the document does not exist
                return null;
            }
        }

        // Generic method
        //
        // Need to carefully specify path to document when calling the method
        //
        // Overwrite and merge relevant model to Firestore spcified document
        public async Task SetDocumentByFirestorePath<T>(string documentPath, T document)
            where T : class
        {
            // Overwrite existing fields, create fields that do not exist, and
            // do not remove other fields
            DocumentReference documentReference = _firestoreDb.Document(documentPath);
            await documentReference.SetAsync(document, SetOptions.MergeAll);
        }

        // Generic method
        //
        // Need to carefully specify path to document when calling the method
        //
        // Delete relevant document specified from Firestore collection
        public async Task DeleteDocumentFromFirestore(string documentPath)
        {
            // Get a reference to the specified Firestore document and delete it
            DocumentReference documentReference = _firestoreDb.Document(documentPath);
            await documentReference.DeleteAsync();
        }

        // Generic method
        //
        // Need to specify collection name, field name, and field value of the desired
        // deleted documents when calling this method
        //
        // Delete relevant Firestore documents by qury from a specified field
        public async Task DeleteDocumentsFromCollectionByField(string collectionName,
            string fieldName, string fieldValue)
        {
            // Get all document snapshots from collection that match the query
            CollectionReference collectionReference = _firestoreDb.Collection(collectionName);
            Query query = collectionReference.WhereEqualTo(fieldName, fieldValue);
            QuerySnapshot querySnapshot = await query.GetSnapshotAsync();

            // Add all documents delete tasks
            List<Task> deleteTasks = [];
            foreach (DocumentSnapshot documentSnapshot in querySnapshot.Documents)
            {
                deleteTasks.Add(documentSnapshot.Reference.DeleteAsync());
            }

            // Delete all documents concurrently
            await Task.WhenAll(deleteTasks);
        }

        // Generic method
        //
        // For successful conversion between model enums and Firestore strings
        //
        // Converter that tells Firestore how to store and read enums as strings
        // instead of the default numeric representation
        public class FirestoreEnumStringConverter<TEnum> : IFirestoreConverter<TEnum>
            where TEnum : struct, Enum
        {
            // Called when reading data from Firestore to model
            public TEnum FromFirestore(object value)
            {
                // Try to convert Firestore string to enum
                return Enum.Parse<TEnum>(value.ToString(), true);
            }

            // Called when reading data from model to Firestore
            public object ToFirestore(TEnum value)
            {
                // Store the enum as its string name in Firestore
                return value.ToString();
            }
        }
    }
}
