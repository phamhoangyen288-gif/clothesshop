package com.example.clothesshop.controllers;

import com.example.clothesshop.dto.CartItem;
import com.example.clothesshop.models.ProductVariant;
import com.example.clothesshop.repositories.ProductVariantRepository;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("/cart")
public class CartController {

    @Autowired
    private ProductVariantRepository variantRepository;

    @GetMapping
    public String viewCart(HttpSession session, Model model) {
        List<CartItem> cart = getCart(session);
        double total = cart.stream()
                .mapToDouble(item -> item.getPrice() * item.getQuantity())
                .sum();
        int totalQuantity = cart.stream()
                .mapToInt(CartItem::getQuantity)
                .sum();

        model.addAttribute("cartItems", cart);
        model.addAttribute("totalPrice", total);
        model.addAttribute("totalQuantity", totalQuantity);
        return "client/cart";
    }

    @PostMapping("/add")
    public String addToCart(@RequestParam("variantId") Long variantId,
                            @RequestParam("quantity") Integer quantity,
                            HttpSession session,
                            RedirectAttributes redirectAttributes) {
        if (quantity == null || quantity < 1) {
            quantity = 1;
        }

        ProductVariant variant = variantRepository.findById(variantId).orElse(null);
        if (variant == null) {
            redirectAttributes.addFlashAttribute("error", "Biến thể sản phẩm không tồn tại.");
            return "redirect:/cart";
        }

        if (variant.getStockQuantity() == null || variant.getStockQuantity() <= 0) {
            redirectAttributes.addFlashAttribute("error", "Sản phẩm này hiện đã hết hàng.");
            return "redirect:/cart";
        }

        if (quantity > variant.getStockQuantity()) {
            quantity = variant.getStockQuantity();
        }

        List<CartItem> cart = getCart(session);
        boolean isExist = false;

        for (CartItem item : cart) {
            if (item.getVariantId().equals(variantId)) {
                int newQuantity = item.getQuantity() + quantity;
                if (newQuantity > variant.getStockQuantity()) {
                    newQuantity = variant.getStockQuantity();
                }
                item.setQuantity(newQuantity);
                isExist = true;
                break;
            }
        }

        if (!isExist) {
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

        session.setAttribute("cart", cart);
        redirectAttributes.addFlashAttribute("success", "Đã thêm sản phẩm vào giỏ hàng.");
        return "redirect:/cart";
    }

    @PostMapping("/update")
    public String updateCartItem(@RequestParam("variantId") Long variantId,
                                 @RequestParam("quantity") Integer quantity,
                                 HttpSession session,
                                 RedirectAttributes redirectAttributes) {
        List<CartItem> cart = getCart(session);

        if (quantity == null || quantity <= 0) {
            cart.removeIf(item -> item.getVariantId().equals(variantId));
            session.setAttribute("cart", cart);
            redirectAttributes.addFlashAttribute("success", "Đã xóa sản phẩm khỏi giỏ hàng.");
            return "redirect:/cart";
        }

        ProductVariant variant = variantRepository.findById(variantId).orElse(null);
        int maxStock = variant != null && variant.getStockQuantity() != null ? variant.getStockQuantity() : quantity;

        for (CartItem item : cart) {
            if (item.getVariantId().equals(variantId)) {
                item.setQuantity(Math.min(quantity, maxStock));
                break;
            }
        }

        session.setAttribute("cart", cart);
        redirectAttributes.addFlashAttribute("success", "Đã cập nhật giỏ hàng.");
        return "redirect:/cart";
    }

    @PostMapping("/remove")
    public String removeCartItem(@RequestParam("variantId") Long variantId,
                                 HttpSession session,
                                 RedirectAttributes redirectAttributes) {
        List<CartItem> cart = getCart(session);
        cart.removeIf(item -> item.getVariantId().equals(variantId));
        session.setAttribute("cart", cart);
        redirectAttributes.addFlashAttribute("success", "Đã xóa sản phẩm khỏi giỏ hàng.");
        return "redirect:/cart";
    }

    @PostMapping("/clear")
    public String clearCart(HttpSession session, RedirectAttributes redirectAttributes) {
        session.removeAttribute("cart");
        redirectAttributes.addFlashAttribute("success", "Đã xóa toàn bộ giỏ hàng.");
        return "redirect:/cart";
    }

    @SuppressWarnings("unchecked")
    private List<CartItem> getCart(HttpSession session) {
        List<CartItem> cart = (List<CartItem>) session.getAttribute("cart");
        if (cart == null) {
            cart = new ArrayList<>();
            session.setAttribute("cart", cart);
        }
        return cart;
    }
}
