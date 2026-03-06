import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        container = NSPersistentContainer(name: "Chail")
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.loadPersistentStores { _, error in
            if let error {
                // Im Production-Code: graceful recovery statt fatalError
                fatalError("CoreData konnte nicht geladen werden: \(error)")
            }
        }
    }

    /// Neuer Hintergrund-Context für Schreiboperationen
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}
