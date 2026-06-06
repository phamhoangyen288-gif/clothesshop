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
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Optional;

@Controller
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/login")
    public String showLoginPage(HttpSession session) {
        User user = (User) session.getAttribute("currentUser");

        if (user != null) {
            String role = user.getRole();
            if ("ADMIN".equalsIgnoreCase(role) || "ROLE_ADMIN".equalsIgnoreCase(role)) {
                return "redirect:/admin/dashboard";
            }
            return "redirect:/";
        }

        return "client/login";
    }

    // Truong hop du an chua dung Spring Security filter thi ham nay van ho tro dang nhap bang session.
    // Neu da dung SecurityConfig, request POST /login se duoc Spring Security xu ly truoc.
    @PostMapping("/login")
    public String handleLogin(@RequestParam("username") String username,
                              @RequestParam("password") String password,
                              HttpSession session,
                              Model model) {
        if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            model.addAttribute("error", "Tài khoản và mật khẩu không được phép để trống!");
            return "client/login";
        }

        Optional<User> userOpt = userRepository.findByUsername(username.trim());
        if (userOpt.isEmpty()) {
            userOpt = userRepository.findByEmail(username.trim());
        }

        if (userOpt.isPresent()) {
            User user = userOpt.get();
            if (user.getPassword().equals(password)) {
                session.setAttribute("currentUser", user);

                String role = user.getRole();
                if ("ADMIN".equalsIgnoreCase(role) || "ROLE_ADMIN".equalsIgnoreCase(role)) {
                    return "redirect:/admin/dashboard";
                }
                return "redirect:/";
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

    @GetMapping("/register")
    public String showRegisterPage() {
        return "client/register";
    }

    @PostMapping("/register")
    public String handleRegister(@RequestParam("fullName") String fullName,
                                 @RequestParam("email") String email,
                                 @RequestParam("username") String username,
                                 @RequestParam("password") String password,
                                 @RequestParam("confirmPassword") String confirmPassword,
                                 Model model,
                                 RedirectAttributes redirectAttributes) {
        fullName = fullName == null ? "" : fullName.trim();
        email = email == null ? "" : email.trim().toLowerCase();
        username = username == null ? "" : username.trim();

        model.addAttribute("fullName", fullName);
        model.addAttribute("email", email);
        model.addAttribute("username", username);

        if (fullName.isEmpty() || email.isEmpty() || username.isEmpty() || password == null || password.isEmpty()) {
            model.addAttribute("error", "Vui lòng nhập đầy đủ thông tin đăng ký.");
            return "client/register";
        }

        if (username.contains(" ")) {
            model.addAttribute("error", "Tên đăng nhập không được chứa khoảng trắng.");
            return "client/register";
        }

        if (password.length() < 6) {
            model.addAttribute("error", "Mật khẩu phải có ít nhất 6 ký tự.");
            return "client/register";
        }

        if (!password.equals(confirmPassword)) {
            model.addAttribute("error", "Mật khẩu xác nhận không khớp.");
            return "client/register";
        }

        if (userRepository.existsByUsername(username)) {
            model.addAttribute("error", "Tên đăng nhập đã tồn tại. Vui lòng chọn tên khác.");
            return "client/register";
        }

        if (userRepository.existsByEmail(email)) {
            model.addAttribute("error", "Email này đã được đăng ký. Vui lòng dùng email khác.");
            return "client/register";
        }

        User user = new User();
        user.setFullName(fullName);
        user.setEmail(email);
        user.setUsername(username);
        user.setPassword(password);
        user.setRole("CUSTOMER");
        userRepository.save(user);

        redirectAttributes.addFlashAttribute("success", "Đăng ký thành công! Bạn có thể đăng nhập ngay.");
        return "redirect:/login";
    }

    @GetMapping("/forgot-password")
    public String showForgotPasswordPage() {
        return "client/forgot-password";
    }
}
