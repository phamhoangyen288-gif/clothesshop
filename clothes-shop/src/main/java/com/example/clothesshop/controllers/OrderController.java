package com.example.clothesshop.controllers;

import com.example.clothesshop.dto.CartItem;
import com.example.clothesshop.models.*;
import com.example.clothesshop.repositories.*;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
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

    @PostMapping("/checkout")
    public String checkout(@RequestParam("fullName") String fullName,
                           @RequestParam("phone") String phone,
                           @RequestParam("address") String address,
                           HttpSession session) {

        List<CartItem> cart = (List<CartItem>) session.getAttribute("cart");
        if (cart == null || cart.isEmpty()) {
            return "redirect:/cart";
        }

        Order order = new Order();
        // Lấy tạm User ID số 1 trong DB làm mẫu mua hàng
        User user = userRepository.findById(1L).orElse(null);
        order.setUser(user);
        order.setOrderDate(LocalDateTime.now());
        order.setShippingAddress(address);
        order.setPhoneNumber(phone);
        order.setStatus("PENDING"); // Đơn hàng ở trạng thái Chờ duyệt

        double total = 0;
        List<OrderDetail> details = new ArrayList<>();

        for (CartItem item : cart) {
            OrderDetail detail = new OrderDetail();
            detail.setOrder(order);

            ProductVariant variant = variantRepository.findById(item.getVariantId()).orElse(null);
            if (variant != null) {
                detail.setProductVariant(variant);
                detail.setQuantity(item.getQuantity());
                detail.setPrice(item.getPrice());
                total += item.getPrice() * item.getQuantity();

                // Thuật toán trừ kho tự động
                variant.setStockQuantity(variant.getStockQuantity() - item.getQuantity());
                variantRepository.save(variant);

                details.add(detail);
            }
        }

        order.setTotalAmount(total);
        order.setOrderDetails(details);

        // Lưu đơn hàng xuống CSDL
        orderRepository.save(order);

        // Đặt hàng thành công thì làm sạch giỏ hàng session
        session.removeAttribute("cart");

        return "redirect:/order/success";
    }

    @GetMapping("/success")
    public String orderSuccess() {
        return "client/success";
    }
}