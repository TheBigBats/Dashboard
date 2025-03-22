package com.example.test.controllers;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/data")
public class H2Controller {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/all")
    public Map<String, List<Map<String, Object>>> getAllTablesData() {
        // Stockage des résultats pour chaque table
        Map<String, List<Map<String, Object>>> databaseData = new HashMap<>();

        // Obtenir toutes les tables de la base de données
        List<String> tables = jdbcTemplate.queryForList(
                "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='PUBLIC'", String.class);


        for (String table : tables) {
            System.out.println(table);
            List<Map<String, Object>> tableData = jdbcTemplate.queryForList("SELECT * FROM " + table);
            databaseData.put(table, tableData);
        }

        return databaseData;
    }

}
