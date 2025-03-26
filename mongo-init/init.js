try {
    const status = rs.status();
    print("Replica set already initialized.");
} catch (e) {
    print("Initializing replica set...");
    rs.initiate();
}

// pour start un réplica afin que airbyte le lise