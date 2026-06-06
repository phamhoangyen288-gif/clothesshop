package com.example.clothesshop.controllers;

import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Controller
@RequestMapping("/admin")
public class AdminController {

    private static final String UPLOAD_DIR = "uploads/products";

    private final JdbcTemplate jdbcTemplate;

    public AdminController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping({"", "/", "/dashboard"})
    public String dashboard(Model model) {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalCategories", queryLong("SELECT COUNT(*) FROM categories"));
        stats.put("totalProducts", queryLong("SELECT COUNT(*) FROM products"));
        stats.put("activeProducts", queryLong("SELECT COUNT(*) FROM products WHERE status = 'ACTIVE'"));
        stats.put("inactiveProducts", queryLong("SELECT COUNT(*) FROM products WHERE status = 'INACTIVE'"));
        stats.put("totalVariants", queryLong("SELECT COUNT(*) FROM product_variants"));
        stats.put("totalStock", queryLong("SELECT COALESCE(SUM(stock_quantity), 0) FROM product_variants"));
        stats.put("totalUsers", queryLong("SELECT COUNT(*) FROM users"));
        stats.put("totalCustomers", queryLong("SELECT COUNT(*) FROM users WHERE role = 'CUSTOMER'"));
        stats.put("totalOrders", queryLong("SELECT COUNT(*) FROM orders"));
        stats.put("totalRevenue", queryDecimal("SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE status = 'COMPLETED'"));

        List<Map<String, Object>> orderStatusStats = jdbcTemplate.queryForList("""
                SELECT status, COUNT(*) AS quantity, COALESCE(SUM(total_amount), 0) AS total_amount
                FROM orders
                GROUP BY status
                ORDER BY status
                """);

        List<Map<String, Object>> productByCategory = jdbcTemplate.queryForList("""
                SELECT c.id, c.name, COUNT(p.id) AS quantity
                FROM categories c
                LEFT JOIN products p ON c.id = p.category_id
                GROUP BY c.id, c.name
                ORDER BY c.id
                """);

        List<Map<String, Object>> lowStockProducts = jdbcTemplate.queryForList("""
                SELECT TOP 10
                       pv.id AS variant_id,
                       p.name AS product_name,
                       pv.size,
                       pv.color,
                       pv.stock_quantity
                FROM product_variants pv
                INNER JOIN products p ON pv.product_id = p.id
                WHERE pv.stock_quantity <= 10
                ORDER BY pv.stock_quantity ASC, p.name ASC
                """);

        List<Map<String, Object>> topSellingProducts = jdbcTemplate.queryForList("""
                SELECT TOP 5
                       p.id AS product_id,
                       p.name AS product_name,
                       SUM(od.quantity) AS sold_quantity,
                       SUM(od.subtotal) AS total_money
                FROM order_details od
                INNER JOIN product_variants pv ON od.variant_id = pv.id
                INNER JOIN products p ON pv.product_id = p.id
                INNER JOIN orders o ON od.order_id = o.id
                WHERE o.status IN ('CONFIRMED', 'SHIPPING', 'COMPLETED')
                GROUP BY p.id, p.name
                ORDER BY sold_quantity DESC
                """);

        List<Map<String, Object>> recentOrders = jdbcTemplate.queryForList("""
                SELECT TOP 8
                       o.id,
                       u.full_name,
                       o.order_date,
                       o.total_amount,
                       o.status
                FROM orders o
                INNER JOIN users u ON o.user_id = u.id
                ORDER BY o.order_date DESC
                """);

        List<Map<String, Object>> revenueByMonth = jdbcTemplate.queryForList("""
                SELECT YEAR(order_date) AS year_value,
                       MONTH(order_date) AS month_value,
                       COUNT(*) AS order_count,
                       COALESCE(SUM(total_amount), 0) AS revenue
                FROM orders
                WHERE status = 'COMPLETED'
                GROUP BY YEAR(order_date), MONTH(order_date)
                ORDER BY year_value, month_value
                """);

        model.addAttribute("stats", stats);
        model.addAttribute("orderStatusStats", orderStatusStats);
        model.addAttribute("productByCategory", productByCategory);
        model.addAttribute("lowStockProducts", lowStockProducts);
        model.addAttribute("topSellingProducts", topSellingProducts);
        model.addAttribute("recentOrders", recentOrders);
        model.addAttribute("revenueByMonth", revenueByMonth);
        return "admin/dashboard";
    }

    @GetMapping("/products")
    public String products(@RequestParam(required = false) String keyword,
                           @RequestParam(required = false) String status,
                           Model model) {
        StringBuilder sql = new StringBuilder("""
                SELECT p.id,
                       p.name,
                       c.name AS category_name,
                       p.original_price,
                       p.sale_price,
                       p.status,
                       p.main_image,
                       COALESCE(SUM(pv.stock_quantity), 0) AS total_stock
                FROM products p
                LEFT JOIN categories c ON p.category_id = c.id
                LEFT JOIN product_variants pv ON p.id = pv.product_id
                WHERE 1 = 1
                """);

        new ProductQueryBuilder(sql, keyword, status);

        List<Object> params = ProductQueryBuilder.params(keyword, status);
        List<Map<String, Object>> products = jdbcTemplate.queryForList(sql.toString(), params.toArray());

        model.addAttribute("products", products);
        model.addAttribute("keyword", keyword);
        model.addAttribute("status", status);
        return "admin/products";
    }

    @GetMapping("/products/create")
    public String createProductForm(Model model) {
        model.addAttribute("product", new LinkedHashMap<String, Object>());
        model.addAttribute("categories", getCategories());
        model.addAttribute("formTitle", "Thêm mặt hàng mới");
        return "admin/product-form";
    }

    @GetMapping("/products/edit/{id}")
    public String editProductForm(@PathVariable Long id, Model model, RedirectAttributes redirectAttributes) {
        try {
            Map<String, Object> product = jdbcTemplate.queryForMap("""
                    SELECT id, category_id, name, description, main_image, original_price, sale_price, status
                    FROM products
                    WHERE id = ?
                    """, id);

            model.addAttribute("product", product);
            model.addAttribute("categories", getCategories());
            model.addAttribute("formTitle", "Sửa mặt hàng");
            return "admin/product-form";
        } catch (EmptyResultDataAccessException e) {
            redirectAttributes.addFlashAttribute("error", "Không tìm thấy sản phẩm cần sửa.");
            return "redirect:/admin/products";
        }
    }

    @PostMapping("/products/save")
    public String saveProduct(@RequestParam(required = false) Long id,
                              @RequestParam Long categoryId,
                              @RequestParam String name,
                              @RequestParam(required = false) String description,
                              @RequestParam(required = false) String existingMainImage,
                              @RequestParam(required = false) MultipartFile imageFile,
                              @RequestParam BigDecimal originalPrice,
                              @RequestParam(required = false) BigDecimal salePrice,
                              @RequestParam String status,
                              RedirectAttributes redirectAttributes) {
        String redirectUrl = id == null ? "redirect:/admin/products/create" : "redirect:/admin/products/edit/" + id;

        if (salePrice != null && salePrice.compareTo(BigDecimal.ZERO) < 0) {
            redirectAttributes.addFlashAttribute("error", "Giá khuyến mãi không được nhỏ hơn 0.");
            return redirectUrl;
        }

        if (originalPrice.compareTo(BigDecimal.ZERO) < 0) {
            redirectAttributes.addFlashAttribute("error", "Giá gốc không được nhỏ hơn 0.");
            return redirectUrl;
        }

        if (!"ACTIVE".equals(status) && !"INACTIVE".equals(status)) {
            status = "ACTIVE";
        }

        String mainImage;
        try {
            mainImage = saveUploadedImage(imageFile, existingMainImage);
        } catch (IllegalArgumentException | IOException e) {
            redirectAttributes.addFlashAttribute("error", e.getMessage());
            return redirectUrl;
        }

        if (id == null) {
            jdbcTemplate.update("""
                    INSERT INTO products
                    (category_id, name, description, main_image, original_price, sale_price, status, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, categoryId, name, emptyToNull(description), emptyToNull(mainImage), originalPrice, salePrice, status);
            redirectAttributes.addFlashAttribute("success", "Đã thêm mặt hàng mới.");
        } else {
            jdbcTemplate.update("""
                    UPDATE products
                    SET category_id = ?,
                        name = ?,
                        description = ?,
                        main_image = ?,
                        original_price = ?,
                        sale_price = ?,
                        status = ?,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """, categoryId, name, emptyToNull(description), emptyToNull(mainImage), originalPrice, salePrice, status, id);
            redirectAttributes.addFlashAttribute("success", "Đã cập nhật mặt hàng.");
        }

        return "redirect:/admin/products";
    }

    @PostMapping("/products/delete/{id}")
    public String deleteProduct(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        // Xóa mềm để không lỗi khóa ngoại với order_details/product_variants.
        jdbcTemplate.update("UPDATE products SET status = 'INACTIVE', updated_at = CURRENT_TIMESTAMP WHERE id = ?", id);
        redirectAttributes.addFlashAttribute("success", "Đã ẩn mặt hàng khỏi cửa hàng.");
        return "redirect:/admin/products";
    }

    @PostMapping("/products/restore/{id}")
    public String restoreProduct(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        jdbcTemplate.update("UPDATE products SET status = 'ACTIVE', updated_at = CURRENT_TIMESTAMP WHERE id = ?", id);
        redirectAttributes.addFlashAttribute("success", "Đã mở bán lại mặt hàng.");
        return "redirect:/admin/products";
    }

    private String saveUploadedImage(MultipartFile imageFile, String currentImage) throws IOException {
        if (imageFile == null || imageFile.isEmpty()) {
            return currentImage;
        }

        String contentType = imageFile.getContentType();
        if (contentType == null || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
            throw new IllegalArgumentException("File tải lên phải là ảnh.");
        }

        String originalName = StringUtils.cleanPath(imageFile.getOriginalFilename() == null ? "product" : imageFile.getOriginalFilename());
        String extension = getExtension(originalName);
        if (!isAllowedImageExtension(extension)) {
            throw new IllegalArgumentException("Chỉ hỗ trợ ảnh JPG, JPEG, PNG, GIF hoặc WEBP.");
        }

        Files.createDirectories(Paths.get(UPLOAD_DIR));

        String fileName = "product_" + UUID.randomUUID() + extension;
        Path targetPath = Paths.get(UPLOAD_DIR).resolve(fileName).normalize();
        Files.copy(imageFile.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

        return "/uploads/products/" + fileName;
    }

    private String getExtension(String fileName) {
        int dotIndex = fileName.lastIndexOf('.');
        if (dotIndex < 0) {
            return "";
        }
        return fileName.substring(dotIndex).toLowerCase(Locale.ROOT);
    }

    private boolean isAllowedImageExtension(String extension) {
        return extension.equals(".jpg")
                || extension.equals(".jpeg")
                || extension.equals(".png")
                || extension.equals(".gif")
                || extension.equals(".webp");
    }

    private List<Map<String, Object>> getCategories() {
        return jdbcTemplate.queryForList("SELECT id, name FROM categories ORDER BY name");
    }

    private Long queryLong(String sql) {
        Long value = jdbcTemplate.queryForObject(sql, Long.class);
        return value == null ? 0L : value;
    }

    private BigDecimal queryDecimal(String sql) {
        BigDecimal value = jdbcTemplate.queryForObject(sql, BigDecimal.class);
        return value == null ? BigDecimal.ZERO : value;
    }

    private String emptyToNull(String value) {
        return value == null || value.trim().isEmpty() ? null : value.trim();
    }

    private static class ProductQueryBuilder {
        ProductQueryBuilder(StringBuilder sql, String keyword, String status) {
            if (keyword != null && !keyword.trim().isEmpty()) {
                sql.append(" AND (p.name LIKE ? OR p.description LIKE ? OR c.name LIKE ?) ");
            }
            if (status != null && !status.trim().isEmpty()) {
                sql.append(" AND p.status = ? ");
            }
            sql.append("""
                    GROUP BY p.id, p.name, c.name, p.original_price, p.sale_price, p.status, p.main_image
                    ORDER BY p.id DESC
                    """);
        }

        static List<Object> params(String keyword, String status) {
            java.util.ArrayList<Object> params = new java.util.ArrayList<>();
            if (keyword != null && !keyword.trim().isEmpty()) {
                String key = "%" + keyword.trim() + "%";
                params.add(key);
                params.add(key);
                params.add(key);
            }
            if (status != null && !status.trim().isEmpty()) {
                params.add(status.trim());
            }
            return params;
        }
    }
}
