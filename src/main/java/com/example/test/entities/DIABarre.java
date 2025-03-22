package com.example.test.entities;

import java.util.Arrays;

public class DIABarre extends Diagrame{
    private String[] label;
    private int[] value;

    public DIABarre(int id, String name, String description, String[] label, int[] value, String backgroundColor, String tecoColor, int positionX, int positionY, int positionWidth, int positionHeight) {
        super(id, name, description, backgroundColor, tecoColor, positionX, positionY, positionWidth, positionHeight);
        this.label = label;
        this.value = value;
    }
    @Override
    public String getGraphScript() {
        return String.format(
                """
                const ctx%d = document.getElementById('chart%d').getContext('2d');
                new Chart(ctx%d, {
                    type: 'bar',
                    data: {
                        labels: %s,
                        datasets: [{
                            label: '%s',
                            data: %s,
                            backgroundColor: '%s',
                            borderColor: '%s',
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            y: { beginAtZero: true }
                        }
                    }
                });
                """,
                getId(),
                getId(),
                getId(),
                Arrays.toString(label),
                getTitle(),
                Arrays.toString(value),
                getBackgroundColor(),
                getTecoColor()
        );
    }
}
