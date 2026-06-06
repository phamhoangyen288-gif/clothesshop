package com.example.clothesshop.controllers;

import com.example.clothesshop.dto.CartItem;
import com.example.clothesshop.models.Order;
import com.example.clothesshop.models.ProductVariant;
import com.example.clothesshop.models.User;
import com.example.clothesshop.repositories.OrderRepository;
import com.example.clothesshop.repositories.ProductVariantRepository;
import com.example.clothesshop.repositories.UserRepository;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.format.DateTimeFormatter;
import java.util.List;

@Controller
@RequestMapping("/order")
public class OrderController {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ProductVariantRepository variantRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PostMapping("/checkout")
    @Transactional
    @SuppressWarnings("unchecked")
    public String checkout(@RequestParam("fullName") String fullName,
                           @RequestParam("phone") String phone,
                           @RequestParam("address") String address,
                           HttpSession session,
                           RedirectAttributes redirectAttributes) {

        List<CartItem> cart = (List<CartItem>) session.getAttribute("cart");
        if (cart == null || cart.isEmpty()) {
            redirectAttributes.addFlashAttribute("error", "Giỏ hàng đang trống, vui lòng chọn sản phẩm trước khi đặt hàng.");
            return "redirect:/cart";
        }

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getName())) {
            return "redirect:/login";
        }

        User user = userRepository.findByUsername(authentication.getName()).orElse(null);
        if (user == null) {
            redirectAttributes.addFlashAttribute("error", "Không tìm thấy tài khoản đặt hàng.");
            return "redirect:/cart";
        }

        double total = 0;
        for (CartItem item : cart) {
            ProductVariant variant = variantRepository.findById(item.getVariantId()).orElse(null);
            if (variant == null || variant.getProduct() == null) {
                redirectAttributes.addFlashAttribute("error", "Có sản phẩm không còn tồn tại trong hệ thống.");
                return "redirect:/cart";
            }

            int stock = variant.getStockQuantity() == null ? 0 : variant.getStockQuantity();
            int quantity = item.getQuantity() == null ? 1 : item.getQuantity();
            if (quantity < 1) {
                quantity = 1;
                item.setQuantity(quantity);
            }

            if (stock < quantity) {
                redirectAttributes.addFlashAttribute(
                        "error",
                        "Sản phẩm \"" + variant.getProduct().getName() + "\" chỉ còn " + stock + " sản phẩm trong kho."
                );
                return "redirect:/cart";
            }

            total += variant.getPrice() * quantity;
        }

        Long orderId = insertOrderAndReturnId(user.getId(), total, address, phone);

        for (CartItem item : cart) {
            ProductVariant variant = variantRepository.findById(item.getVariantId()).orElse(null);
            if (variant == null) {
                throw new IllegalStateException("Không tìm thấy biến thể sản phẩm khi lưu chi tiết đơn hàng.");
            }

            int quantity = item.getQuantity() == null ? 1 : item.getQuantity();
            double price = variant.getPrice();
            double subtotal = price * quantity;

            jdbcTemplate.update(
                    "INSERT INTO order_details (order_id, variant_id, quantity, price_at_order_time, subtotal) VALUES (?, ?, ?, ?, ?)",
                    orderId,
                    variant.getId(),
                    quantity,
                    price,
                    subtotal
            );
        }

        session.setAttribute("lastReceiverName_" + orderId, fullName);
        session.removeAttribute("cart");

        return "redirect:/order/success/" + orderId;
    }

    /**
     * Tạo đơn bằng JDBC để tránh lỗi Hibernate/JPA với SQL Server khi bảng orders có trigger.
     * SET NOCOUNT ON giúp SQL Server không trả update-count trước ResultSet, nên queryForObject lấy được id mới.
     */
    private Long insertOrderAndReturnId(Long userId, double total, String address, String phone) {
        String sql = """
                SET NOCOUNT ON;
                INSERT INTO orders
                    (user_id, order_date, total_amount, shipping_address, receiver_phone, status, stock_deducted, created_at, updated_at)
                VALUES (?, GETDATE(), ?, ?, ?, 'PENDING', 0, GETDATE(), GETDATE());
                SELECT CAST(SCOPE_IDENTITY() AS BIGINT);
                """;

        return jdbcTemplate.queryForObject(sql, Long.class, userId, total, address, phone);
    }

    @GetMapping("/success/{id}")
    public String orderSuccess(@PathVariable("id") Long id,
                               HttpSession session,
                               Model model,
                               RedirectAttributes redirectAttributes) {
        Order order = orderRepository.findInvoiceById(id).orElse(null);
        if (order == null) {
            redirectAttributes.addFlashAttribute("error", "Không tìm thấy hóa đơn đơn hàng.");
            return "redirect:/cart";
        }

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getName())) {
            return "redirect:/login";
        }

        boolean isAdmin = authentication.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(authority -> "ROLE_ADMIN".equals(authority) || "ADMIN".equals(authority));

        if (!isAdmin && order.getUser() != null && !authentication.getName().equals(order.getUser().getUsername())) {
            redirectAttributes.addFlashAttribute("error", "Bạn không có quyền xem hóa đơn này.");
            return "redirect:/cart";
        }

        Object receiverName = session.getAttribute("lastReceiverName_" + id);
        if (receiverName == null && order.getUser() != null) {
            receiverName = order.getUser().getFullName();
        }

        String orderDateText = order.getOrderDate() != null
                ? order.getOrderDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"))
                : "";

        model.addAttribute("order", order);
        model.addAttribute("receiverName", receiverName == null ? "Khách hàng" : receiverName);
        model.addAttribute("orderDateText", orderDateText);
        return "client/success";
    }

    @GetMapping("/success")
    public String orderSuccessWithoutId() {
        return "redirect:/cart";
    }
}
