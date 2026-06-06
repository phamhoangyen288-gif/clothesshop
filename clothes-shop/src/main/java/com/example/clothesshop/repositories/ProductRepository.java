package com.example.clothesshop.repositories;

import com.example.clothesshop.models.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    // Tìm kiếm theo từ khóa ô Search
    List<Product> findByNameContainingIgnoreCase(String name);

    // Lọc sản phẩm theo tên danh mục (ví dụ: 'Áo Thun', 'Quần Jean')
    List<Product> findByCategoryNameContainingIgnoreCase(String categoryName);

    // Lọc sản phẩm theo mã bộ sưu tập (ví dụ: 'tet', 'jeans', 'cloudrunner')
    List<Product> findByCollectionIgnoreCase(String collection);
}