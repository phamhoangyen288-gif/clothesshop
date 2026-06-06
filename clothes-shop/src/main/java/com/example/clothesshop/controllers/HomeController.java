package com.example.clothesshop.controllers;

import com.example.clothesshop.models.Product;
import com.example.clothesshop.repositories.CategoryRepository;
import com.example.clothesshop.repositories.ProductRepository;
import com.example.clothesshop.services.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import java.util.List;

@Controller
public class HomeController {

    @Autowired
    private ProductService productService;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private ProductRepository productRepository;

    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("listProducts", productService.getAllProducts());
        return "client/index";
    }

    // Xử lý Tìm kiếm kết hợp xem danh sách sản phẩm
    @GetMapping("/products")
    public String showAllProducts(@RequestParam(value = "keyword", required = false) String keyword,
                                  @RequestParam(value = "category", required = false) String category,
                                  @RequestParam(value = "collection", required = false) String collection,
                                  @RequestParam(value = "filter", required = false) String filter,
                                  Model model) {
        List<Product> products;
        String pageTitle = "Tất Cả Sản Phẩm Quần Áo"; // Tiêu đề mặc định ban đầu

        // 1. Lọc theo từ khóa tìm kiếm (Keyword)
        if (keyword != null && !keyword.trim().isEmpty()) {
            products = productRepository.findByNameContainingIgnoreCase(keyword);
            pageTitle = "Kết quả tìm kiếm cho: \"" + keyword + "\"";
            model.addAttribute("keyword", keyword);
        }
        // 2. Lọc theo tên phân loại sản phẩm (Áo thun, Quần jean...)
        // TÌM VÀ SỬA LẠI ĐOẠN CHECK CATEGORY TRONG HOMECONTROLLER
        else if (category != null && !category.trim().isEmpty()) {
            String categoryName = "";

            // Chỉ cần lấy từ khóa cốt lõi không dấu để tìm kiếm trong DB, tránh lỗi font
            if (category.equals("ao-thun")) categoryName = "Thun";
            else if (category.equals("ao-polo")) categoryName = "Polo";
            else if (category.equals("ao-so-mi")) categoryName = "Sơ Mi";
            else if (category.equals("quan-jean")) categoryName = "Jean";
            else if (category.equals("quan-short")) categoryName = "Short";
            else if (category.equals("that-lung")) categoryName = "Lưng";
            else if (category.equals("vi-da")) categoryName = "Ví";
            else if (category.equals("tre-em")) categoryName = "Em";

            // Hàm này sẽ tìm tất cả danh mục chứa từ khóa trên (Ví dụ: "Jean" sẽ khớp với cả "Quần Jean" hay "Qu?n Jean")
            products = productRepository.findByCategoryNameContainingIgnoreCase(categoryName);

            // Gán lại tiêu đề hiển thị cho đẹp mắt
            if (category.equals("quan-jean")) pageTitle = "Danh mục: Quần Jean";
            else if (category.equals("tre-em")) pageTitle = "Danh mục: Thời Trang Trẻ Em";
            else pageTitle = "Danh mục: " + categoryName;
        }
        // 3. Lọc theo mã bộ sưu tập (Collection)
        else if (collection != null && !collection.trim().isEmpty()) {
            products = productRepository.findByCollectionIgnoreCase(collection);

            String collectionName = collection;
            if (collection.equals("cloudrunner")) collectionName = "Cloudrunner Collection";
            else if (collection.equals("travellers")) collectionName = "Travellers Selection";
            else if (collection.equals("travelling")) collectionName = "Travelling Collection";
            else if (collection.equals("tet")) collectionName = "Tết Collection";
            else if (collection.equals("jeans")) collectionName = "Deep Black Premium Jeans";

            pageTitle = "Bộ sưu tập: " + collectionName;
        }
        // 4. Lọc theo nhóm Khuyến mãi / Sản phẩm mới
        else if (filter != null && !filter.trim().isEmpty()) {
            products = productService.getAllProducts();
            if (filter.equals("new")) pageTitle = "Hàng Mới Về (New Arrivals)";
            else if (filter.equals("sale")) pageTitle = "Chương Trình Đồng Giá 195k";
            else if (filter.equals("sale20")) pageTitle = "Hàng Thanh Lý Xả Kho -20%";
        }
        // 5. Mặc định nếu không chọn gì thì load tất cả sản phẩm ra
        else {
            products = productService.getAllProducts();
        }

        // Đẩy chuỗi tiêu đề động sang giao diện HTML công khai
        model.addAttribute("pageTitle", pageTitle);
        model.addAttribute("listProducts", products);
        model.addAttribute("listCategories", categoryRepository.findAll());
        return "client/shop";
    }

    @GetMapping("/product/detail/{id}")
    public String showProductDetail(@PathVariable("id") Long id, Model model) {
        Product product = productService.getProductById(id);
        if (product == null) return "redirect:/";
        model.addAttribute("product", product);
        return "client/detail";
    }


}