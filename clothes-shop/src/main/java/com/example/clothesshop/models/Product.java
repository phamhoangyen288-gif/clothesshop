package com.example.clothesshop.models;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "products")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    // PHẦN THÊM MỚI 1: Tên file ảnh đại diện để liên kết qua WebConfig
    @Column(name = "main_image", length = 500)
    private String mainImage;

    // PHẦN THÊM MỚI 2: Giá gốc của sản phẩm
    @Column(name = "original_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal originalPrice;

    // PHẦN THÊM MỚI 3: Giá khuyến mãi (có thể null nếu không giảm giá)
    @Column(name = "sale_price", precision = 12, scale = 2)
    private BigDecimal salePrice;

    // PHẦN THÊM MỚI 4: Trạng thái sản phẩm (ACTIVE, INACTIVE)
    @Column(length = 20, nullable = false)
    private String status = "ACTIVE";

    @ManyToOne
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(length = 50)
    private String collection;

    // Một sản phẩm (ví dụ: Áo thun bản A) sẽ có nhiều biến thể size/màu khác nhau
    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL)
    private List<ProductVariant> variants;

    // PHẦN THÊM MỚI 5: Các trường lưu vết thời gian khởi tạo và cập nhật
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();
}