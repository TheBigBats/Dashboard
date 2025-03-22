package com.example.test.entities;

import lombok.*;

@Getter
@Setter
@ToString
public abstract class Diagrame {
    private int id;
    private String title;
    private String description;
    private String backgroundColor;
    private String tecoColor;
    private int positionX; // Position horizontale initiale (en pixels)
    private int positionY; // Position verticale initiale (en pixels)
    private int width;  // Largeur en pixels
    private int height; // Hauteur en pixels
    public Diagrame(int id, String title, String description, String backgroundColor, String tecoColor, int positionX, int positionY, int width, int height) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.backgroundColor = backgroundColor;
        this.tecoColor = tecoColor;
        this.positionX = positionX;
        this.positionY = positionY;
        this.width = width;
        this.height = height;
    }
    public abstract String getGraphScript();
}
