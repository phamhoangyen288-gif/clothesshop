package com.example.clothesshop.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CartItem {
    private Long variantId;
    private String productName;
    private String size;
    private String color;
    private Double price;
    private Integer quantity;
    private String imageUrl;
}