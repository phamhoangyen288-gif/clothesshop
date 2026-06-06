package com.example.clothesshop.models;

import jakarta.persistence.*;
import lombok.*;

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
    private String size; // Ví dụ: S, M, L, XL

    @Column(nullable = false, length = 50)
    private String color; // Ví dụ: Đỏ, Đen, Trắng

    @Column(nullable = false)
    private Double price; // Giá bán riêng cho từng biến thể (nếu có)

    @Column(nullable = false)
    private Integer stockQuantity; // Số lượng tồn kho của size/màu này

    private String imageUrl; // Ảnh riêng của biến thể màu đó
}