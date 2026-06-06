package com.example.clothesshop.controllers;

import com.example.clothesshop.models.User;
import com.example.clothesshop.repositories.UserRepository;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Optional;

@Controller
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/login")
    public String showLoginPage(HttpSession session) {
        User user = (User) session.getAttribute("currentUser");
        if (user != null) {
            // Nếu admin quay lại trang login thì đẩy thẳng vào trang admin dashboard
            if ("ROLE_ADMIN".equals(user.getRole())) {
                return "redirect:/admin/dashboard";
            }
            return "redirect:/";
        }
        return "client/login";
    }

    @PostMapping("/login")
    public String handleLogin(@RequestParam("username") String username,
                              @RequestParam("password") String password,
                              HttpSession session,
                              Model model) {

        // RÀNG BUỘC BACKEND: Kiểm tra dữ liệu rỗng đầu vào bảo mật nâng cao
        if (username.trim().isEmpty() || password.trim().isEmpty()) {
            model.addAttribute("error", "Tài khoản và mật khẩu không được phép để trống!");
            return "client/login";
        }
        if (password.length() < 6) {
            model.addAttribute("error", "Mật khẩu bảo mật phải từ 6 ký tự trở lên!");
            return "client/login";
        }

        Optional<User> userOpt = userRepository.findByUsername(username);

        if (userOpt.isPresent()) {
            User user = userOpt.get();

            if (user.getPassword().equals(password)) {
                // Lưu thông tin người dùng vào Session dùng chung
                session.setAttribute("currentUser", user);

                // XỬ LÝ PHÂN QUYỀN ĐĂNG NHẬP RÕ RÀNG
                if ("ROLE_ADMIN".equals(user.getRole())) {
                    System.out.println(">>> Đăng nhập quyền ADMIN: Chuyển hướng trang quản trị");
                    return "redirect:/admin/dashboard";
                } else {
                    System.out.println(">>> Đăng nhập quyền USER: Quay về trang chủ mua hàng");
                    return "redirect:/";
                }
            }
        }

        model.addAttribute("error", "Tài khoản hoặc mật khẩu không chính xác!");
        return "client/login";
    }

    @GetMapping("/logout")
    public String handleLogout(HttpSession session) {
        session.invalidate();
        return "redirect:/";
    }

    // Tạo nhanh 2 trang để chặn lỗi Whitelabel 404 khi nhấn link Đăng ký / Quên MK
    @GetMapping("/register")
    public String showRegisterPage() {
        return "client/register"; // Tạo file register.html nếu muốn làm tiếp form đăng ký nhé
    }

    @GetMapping("/forgot-password")
    public String showForgotPasswordPage() {
        return "client/forgot-password";
    }
}