package com.example.clothesshop.models;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "product_variants")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductVariant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(nullable = false, length = 20)
    private String size;

    @Column(nullable = false, length = 50)
    private String color;

    // Database SQL hiện không có cột price riêng trong product_variants.
    // Giá sẽ lấy từ products.sale_price hoặc products.original_price.
    @Transient
    private Double price;

    @Column(name = "stock_quantity", nullable = false)
    private Integer stockQuantity;

    // Database SQL hiện không có cột image_url riêng trong product_variants.
    // Ảnh sẽ lấy từ products.main_image.
    @Transient
    private String imageUrl;

    public Double getPrice() {
        if (price != null) {
            return price;
        }
        if (product == null) {
            return 0.0;
        }
        BigDecimal currentPrice = product.getSalePrice() != null ? product.getSalePrice() : product.getOriginalPrice();
        return currentPrice != null ? currentPrice.doubleValue() : 0.0;
    }

    public String getImageUrl() {
        if (imageUrl != null && !imageUrl.isBlank()) {
            return normalizeImagePath(imageUrl);
        }
        if (product != null && product.getMainImage() != null && !product.getMainImage().isBlank()) {
            return normalizeImagePath(product.getMainImage());
        }
        return "https://placehold.co/300x300?text=No+Image";
    }

    private String normalizeImagePath(String path) {
        if (path == null || path.isBlank()) {
            return "https://placehold.co/300x300?text=No+Image";
        }
        if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("/")) {
            return path;
        }
        return "/images/" + path;
    }
}
