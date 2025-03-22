package com.example.test.entities;

import lombok.Getter;

import java.util.Arrays;

@Getter
public class DIASecteur extends Diagrame{
    private String[] label;
    private int[] value;
    public DIASecteur(int id, String name, String description, String[] label, int[] value,String backgroundColor, String tecoColor ,int positionX, int positionY, int weight, int length) {
        super(id, name, description, backgroundColor, tecoColor, positionX, positionY, weight, length);
        this.label = label;
        this.value = value;
    }

    @Override
    public String getGraphScript() {
        return String.format(
                """
                const ctx%d = document.getElementById('chart%d').getContext('2d');
                new Chart(ctx%d, {
                    type: 'pie',
                    data: {
                        labels: %s, // Labels des segments
                        datasets: [{
                            data: %s, // Valeurs des segments
                            backgroundColor: '%s', // Couleur de fond héritée
                            borderColor: '%s', // Couleur de bordure héritée
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false
                    }
                });
                """,
                this.getId(), // Identifiant unique du graphique
                this.getId(),
                this.getId(),
                Arrays.toString(label), // Sérialisation des labels
                Arrays.toString(value), // Sérialisation des valeurs
                this.getBackgroundColor(), // Couleur de fond héritée
                this.getTecoColor() // Couleur de bordure héritée
        );
    }
}


