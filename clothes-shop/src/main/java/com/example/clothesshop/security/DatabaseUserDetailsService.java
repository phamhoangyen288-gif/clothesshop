package com.example.clothesshop.security;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class DatabaseUserDetailsService implements UserDetailsService {

    private final JdbcTemplate jdbcTemplate;

    public DatabaseUserDetailsService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        List<Map<String, Object>> users = jdbcTemplate.queryForList(
                "SELECT username, password, role FROM users WHERE username = ? OR email = ?",
                username,
                username
        );

        if (users.isEmpty()) {
            throw new UsernameNotFoundException("Không tìm thấy tài khoản: " + username);
        }

        Map<String, Object> user = users.get(0);
        String dbUsername = String.valueOf(user.get("username"));
        String password = String.valueOf(user.get("password"));
        String role = String.valueOf(user.get("role"));

        return new org.springframework.security.core.userdetails.User(
                dbUsername,
                password,
                List.of(new SimpleGrantedAuthority("ROLE_" + role))
        );
    }
}
