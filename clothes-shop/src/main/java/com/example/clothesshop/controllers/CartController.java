package com.example.clothesshop.controllers;

import com.example.clothesshop.dto.CartItem;
import com.example.clothesshop.models.ProductVariant;
import com.example.clothesshop.repositories.ProductVariantRepository;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("/cart")
public class CartController {

    @Autowired
    private ProductVariantRepository variantRepository;

    @GetMapping
    public String viewCart(HttpSession session, Model model) {
        List<CartItem> cart = (List<CartItem>) session.getAttribute("cart");
        if (cart == null) cart = new ArrayList<>();

        double total = cart.stream().mapToDouble(item -> item.getPrice() * item.getQuantity()).sum();
        model.addAttribute("cartItems", cart);
        model.addAttribute("totalPrice", total);
        return "client/cart";
    }

    @PostMapping("/add")
    public String addToCart(@RequestParam("variantId") Long variantId,
                            @RequestParam("quantity") Integer quantity,
                            HttpSession session) {
        List<CartItem> cart = (List<CartItem>) session.getAttribute("cart");
        if (cart == null) {
            cart = new ArrayList<>();
        }

        // Kiểm tra xem mặt hàng size/màu này đã có trong giỏ chưa
        boolean isExist = false;
        for (CartItem item : cart) {
            if (item.getVariantId().equals(variantId)) {
                item.setQuantity(item.getQuantity() + quantity);
                isExist = true;
                break;
            }
        }

        if (!isExist) {
            ProductVariant variant = variantRepository.findById(variantId).orElse(null);
            if (variant != null) {
                CartItem newItem = new CartItem(
                        variant.getId(),
                        variant.getProduct().getName(),
                        variant.getSize(),
                        variant.getColor(),
                        variant.getPrice(),
                        quantity,
                        variant.getImageUrl()
                );
                cart.add(newItem);
            }
        }

        session.setAttribute("cart", cart);
        return "redirect:/cart";
    }
}