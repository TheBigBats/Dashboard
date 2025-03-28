try {
    const status = rs.status();
    print("Replica set already initialized.");
} catch (e) {
    print("Initializing replica set...");
    // ⏳ Attendre que MongoDB se mette à jour

    rs.initiate();


    (() => {
        const dbName = "DataBase";
        const collectionName = "init";

        // Utilise une autre variable pour ne pas écraser `db` global
        const mydb = db.getSiblingDB(dbName);

        if (mydb.getCollectionNames().includes(collectionName)) {
            print(`✅ La base '${dbName}' et la collection '${collectionName}' existent déjà.`);
        } else {
            print(`📦 Création de la base '${dbName}' avec la collection '${collectionName}'...`);
            mydb[collectionName].insertOne({ initialized_at: new Date() });
            print("✅ Base initialisée !");
        }
    })();


}


// pour start un réplica afin que airbyte le lise

// Fichier : ./mongo-init/init-replica.js
