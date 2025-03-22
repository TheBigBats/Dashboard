package com.example.test.controllers;

import com.example.test.entities.User;
import com.example.test.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import com.example.test.entities.DIABarre;
import com.example.test.entities.DIASecteur;
import com.example.test.entities.Diagrame;

import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
@Controller
public class DiagrameController {
    private final DIABarre exampleBar = new DIABarre(
            1,
            "Vente",
            "Coucou je descriptione",
            new String[]{"'Jan'", "'Feb'", "'Mar'"},
            new int[]{100, 200, 150},
            "rgba(75, 192, 192, 0.2)", // Couleur en format RGBA pour Chart.js
            "rgba(75, 192, 192, 1)",  // Couleur du contour
            50,
            50,
            400,
            300
    );

    private final DIASecteur diasSecteur = new DIASecteur(
            2,
            "Venteuh",
            "Coucou je descriptione",
            new String[]{"'A'", "'B'", "'C'"},
            new int[]{20, 30, 50},
            "rgba(255, 99, 132, 0.2)",
            "rgba(255, 99, 132, 1)",
            500,
            50,
            400,
            300
    );
    private UserRepository userRepository;
    private static final String JSON_FILE_PATH = "/shared-data/graphs.json"; // Chemin du fichier JSON
    @PostMapping("/user/create")
    public User createUser(@RequestBody User user) {
        return userRepository.save(user);
    }

    @GetMapping("/user/all")
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }
    @GetMapping("/json")
    public ResponseEntity<?> getJsonFromR() {
        try {
            // Lire le contenu du fichier JSON
            File jsonFile = new File(JSON_FILE_PATH);
            if (!jsonFile.exists()) {
                return ResponseEntity.notFound().build(); // Retourne 404 si le fichier n'existe pas
            }

            String content = new String(Files.readAllBytes(Paths.get(JSON_FILE_PATH)));

            // Retourner le contenu du fichier JSON
            return ResponseEntity.ok(content);

        } catch (IOException e) {
            // Gérer les erreurs de lecture du fichier
            return ResponseEntity.internalServerError().body("Erreur lors de la lecture du fichier JSON : " + e.getMessage());
        }
    }
    @GetMapping("/diagrams")
    public String diagrame(Model model) {
        // Ajouter les objets au modèle
        List<Diagrame> diagrams = Arrays.asList(exampleBar,diasSecteur);
        model.addAttribute("diagrams", diagrams);

        System.out.println(exampleBar);
        System.out.println(diasSecteur);


        return "diagrams"; // Nom du fichier HTML Thymeleaf
    }

    @GetMapping("/diagramsv2")
    public String diagrames(Model model) {
        // Liste des diagrammes (exemples + dynamiques)
        List<Diagrame> diagrams = new ArrayList<>();
        diagrams.add(exampleBar); // Graphique statique
        diagrams.add(diasSecteur); // Graphique statique

        // Lire le fichier JSON généré par R
        String jsonFilePath = "/shared-data/graphs.json"; // Chemin du fichier JSON
        try {
            File jsonFile = new File(jsonFilePath);
            if (jsonFile.exists()) {
                ObjectMapper objectMapper = new ObjectMapper();
                JsonNode rootNode = objectMapper.readTree(jsonFile);
                JsonNode graphsNode = rootNode.path("graphs");

                System.out.println("JSON 'graphs' : " + graphsNode);

                // Parcourir chaque graphique dans le fichier JSON
                int idCounter = 3; // Commence après les graphiques statiques
                for (JsonNode graphNode : graphsNode) {
                    JsonNode dataNode = graphNode.get("data");
                    String title = graphNode.get("options").get("title").asText(); // Titre du graphique
                if (title.isEmpty()) { title = "titre vide"; }
                    // Initialiser les tableaux avec la taille des données
                    int dataSize = dataNode.size();
                    String[] labels = new String[dataSize];
                    int[] values = new int[dataSize];

                    // Remplir les tableaux
                    for (int i = 0; i < dataSize; i++) {
                        JsonNode entry = dataNode.get(i);
                        labels[i] = "'" + entry.get("label").asText() +"'";
                        values[i] = entry.get("total").asInt();

                        System.out.println("Label : " + labels[i] + ", Total : " + values[i]);
                    }

                    // Créer un graphique dynamique
                    DIABarre dynamicBar = new DIABarre(
                            idCounter++,                               // ID unique
                            title,                                    // Nom du graphique
                            "Graphique généré dynamiquement",         // Description
                            labels,                                   // Labels
                            values,                                   // Valeurs
                            "rgba(54, 162, 235, 0.2)",                // Couleur de fond
                            "rgba(54, 162, 235, 1)",                  // Couleur de contour
                            50,                                       // Position X par défaut
                            50 * idCounter,                           // Position Y décalée
                            400,                                      // Largeur par défaut
                            300                                       // Hauteur par défaut
                    );

                    System.out.println("Graphique dynamique créé : " + dynamicBar);
                    System.out.println("Graphique dynamique créé : ");
                    System.out.println("  Title: " + dynamicBar.getTitle());
                    System.out.println("  Labels: " + Arrays.toString(labels));
                    System.out.println("  Values: " + Arrays.toString(values));
                    System.out.println("  Dynamic Bar: " + dynamicBar);
                    diagrams.add(dynamicBar); // Ajouter le graphique à la liste
                }
            } else {
                System.out.println("Fichier JSON introuvable : " + jsonFilePath);
            }
        } catch (IOException e) {
            System.err.println("Erreur lors de la lecture du fichier JSON : " + e.getMessage());
        }

        // Ajouter les diagrammes au modèle
        model.addAttribute("diagrams", diagrams);

        System.out.println("Diagrammes finaux : " + diagrams);

        return "diagrams"; // Nom du fichier HTML Thymeleaf
    }
}
