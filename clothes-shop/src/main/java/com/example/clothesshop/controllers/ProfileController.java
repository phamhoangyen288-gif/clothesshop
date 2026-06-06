package com.example.clothesshop.controllers;

import com.example.clothesshop.models.User;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ProfileController {

    @GetMapping("/profile")
    public String viewProfile(HttpSession session, Model model) {
        // Lấy thông tin User đang đăng nhập từ Session ra
        User currentUser = (User) session.getAttribute("currentUser");

        // Nếu chưa đăng nhập (Session trống), đá người dùng về trang Login
        if (currentUser == null) {
            return "redirect:/login";
        }

        model.addAttribute("user", currentUser);
        return "client/profile";
    }
}