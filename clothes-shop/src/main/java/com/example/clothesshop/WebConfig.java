package com.example.clothesshop;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Đã sửa đường dẫn trỏ chính xác vào thư mục C:/project/images/ của bạn
        registry.addResourceHandler("/images/**")
                .addResourceLocations("file:C:\\HocDaiHoc\\Java\\images");
    }
}