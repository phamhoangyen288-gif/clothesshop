-- =========================================================================
-- 1. KHỞI TẠO VÀ LÀM SẠCH CƠ SỞ DỮ LIỆU CLOTHESSHOPDB
-- =========================================================================
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'ClothesShopDB')
BEGIN
    ALTER DATABASE ClothesShopDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ClothesShopDB;
END
GO

CREATE DATABASE ClothesShopDB;
GO

USE ClothesShopDB;
GO

-- =========================================================================
-- 2. TẠO CÁC BẢNG DỮ LIỆU (TABLES) ĐỒNG BỘ KIỂU BIGINT VỚI JAVA
-- =========================================================================

-- Bảng users
CREATE TABLE users (
    id BIGINT IDENTITY(1,1) NOT NULL,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name NVARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_users PRIMARY KEY (id),
    CONSTRAINT UK_users_username UNIQUE (username),
    CONSTRAINT UK_users_email UNIQUE (email),
    CONSTRAINT CHK_users_role CHECK (role IN ('ADMIN', 'CUSTOMER'))
);
GO

-- Bảng categories
CREATE TABLE categories (
    id BIGINT IDENTITY(1,1) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_categories PRIMARY KEY (id)
);
GO

-- Bảng products
CREATE TABLE products (
    id BIGINT IDENTITY(1,1) NOT NULL,
    category_id BIGINT NOT NULL,
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX) NULL,
    main_image VARCHAR(500) NULL,
    original_price DECIMAL(12,2) NOT NULL,
    sale_price DECIMAL(12,2) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_products PRIMARY KEY (id),
    CONSTRAINT FK_products_categories FOREIGN KEY (category_id) REFERENCES categories (id) ON UPDATE CASCADE,
    CONSTRAINT CHK_products_original_price CHECK (original_price >= 0),
    CONSTRAINT CHK_products_sale_price CHECK (sale_price IS NULL OR sale_price >= 0),
    CONSTRAINT CHK_products_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
);
GO

-- Bảng product_variants (Các biến thể sản phẩm - Đồng bộ tên với Java Entity)
CREATE TABLE product_variants (
    id BIGINT IDENTITY(1,1) NOT NULL,
    product_id BIGINT NOT NULL,
    size VARCHAR(20) NOT NULL,
    color NVARCHAR(50) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_product_variants PRIMARY KEY (id),
    CONSTRAINT UK_variant_size_color UNIQUE (product_id, size, color),
    CONSTRAINT FK_product_variants_products FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT CHK_product_variants_stock_quantity CHECK (stock_quantity >= 0)
);
GO

-- Bảng orders
CREATE TABLE orders (
    id BIGINT IDENTITY(1,1) NOT NULL,
    user_id BIGINT NOT NULL,
    order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    shipping_address NVARCHAR(500) NOT NULL,
    receiver_phone VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    stock_deducted TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_orders PRIMARY KEY (id),
    CONSTRAINT FK_orders_users FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE,
    CONSTRAINT CHK_orders_stock_deducted CHECK (stock_deducted IN (0,1)),
    CONSTRAINT CHK_orders_total_amount CHECK (total_amount >= 0),
    CONSTRAINT CHK_orders_status CHECK (status IN ('PENDING', 'CONFIRMED', 'SHIPPING', 'COMPLETED', 'CANCELLED'))
);
GO

-- Bảng order_details
CREATE TABLE order_details (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    variant_id BIGINT NOT NULL, -- variant_id đồng bộ hoàn toàn dữ liệu mapping Java
    quantity INT NOT NULL,
    price_at_order_time DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_order_details PRIMARY KEY (id),
    CONSTRAINT FK_order_details_orders FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_order_details_variants FOREIGN KEY (variant_id) REFERENCES product_variants (id) ON UPDATE CASCADE,
    CONSTRAINT CHK_order_details_price CHECK (price_at_order_time >= 0),
    CONSTRAINT CHK_order_details_quantity CHECK (quantity >= 0),
    CONSTRAINT CHK_order_details_subtotal CHECK (subtotal >= 0)
);
GO

-- Tự động cập nhật cột updated_at cho bảng orders và products
CREATE TRIGGER trg_orders_update_timestamp ON orders AFTER UPDATE AS 
BEGIN
    UPDATE orders SET updated_at = CURRENT_TIMESTAMP WHERE id IN (SELECT id FROM inserted);
END;
GO

CREATE TRIGGER trg_products_update_timestamp ON products AFTER UPDATE AS 
BEGIN
    UPDATE products SET updated_at = CURRENT_TIMESTAMP WHERE id IN (SELECT id FROM inserted);
END;
GO

-- =========================================================================
-- 3. CHÈN ĐẦY ĐỦ TOÀN BỘ DỮ LIỆU MẪU CÓ SẴN (KHÔNG LƯỢC BỚT)
-- =========================================================================

SET IDENTITY_INSERT users ON;
INSERT INTO users (id, username, password, full_name, email, phone, role, created_at) VALUES 
(1, 'admin', '123456', N'Quản trị viên', 'admin@clothingshop.com', '0900000000', 'ADMIN', '2026-06-06 12:55:34'),
(2, 'customer1', '123456', N'Nguyễn Văn A', 'customer1@gmail.com', '0911111111', 'CUSTOMER', '2026-06-06 12:55:34'),
(3, 'customer2', '123456', N'Trần Thị B', 'customer2@gmail.com', '0922222222', 'CUSTOMER', '2026-06-06 12:55:34');
SET IDENTITY_INSERT users OFF;
GO

SET IDENTITY_INSERT categories ON;
INSERT INTO categories (id, name, description, created_at) VALUES 
(1, N'Áo thun', N'Các mẫu áo thun nam nữ trẻ trung, năng động', '2026-06-06 12:55:34'),
(2, N'Quần jean', N'Quần jean thời trang dành cho nam và nữ', '2026-06-06 12:55:34'),
(3, N'Váy', N'Các mẫu váy công sở, váy dạo phố và váy dự tiệc', '2026-06-06 12:55:34'),
(4, N'Áo khoác', N'Áo khoác chống nắng, áo khoác jean, áo khoác dù', '2026-06-06 12:55:34'),
(5, N'Phụ kiện', N'Phụ kiện thời trang như nón, túi, thắt lưng', '2026-06-06 12:55:34'),
(6, N'Áo polo', N'Áo polo nam lịch sự, dễ phối đồ', '2026-06-06 12:59:15'),
(7, N'Áo sơ mi', N'Áo sơ mi nam công sở và casual', '2026-06-06 12:59:15'),
(8, N'Quần short', N'Quần short nam mặc hằng ngày, đi chơi, thể thao', '2026-06-06 12:59:15'),
(9, N'Hoodie & Sweater', N'Áo hoodie, sweater trẻ trung', '2026-06-06 12:59:15'),
(10, N'Đồ mặc nhà', N'Đồ mặc nhà thoải mái, chất liệu mềm', '2026-06-06 12:59:15');
SET IDENTITY_INSERT categories OFF;
GO

SET IDENTITY_INSERT products ON;
INSERT INTO products (id, category_id, name, description, main_image, original_price, sale_price, status, created_at, updated_at) VALUES 
(1, 1, N'Áo thun basic cotton', N'Áo thun cotton mềm mại, dễ phối đồ', 'ao_thun_basic.jpg', 150000.00, 120000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(2, 1, N'Áo thun oversize streetwear', N'Áo thun form rộng phong cách streetwear', 'ao_thun_oversize.jpg', 220000.00, 180000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(3, 1, N'Áo thun polo nam', N'Áo polo nam lịch sự, phù hợp đi học và đi làm', 'ao_polo_nam.jpg', 250000.00, 210000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(4, 2, N'Quần jean skinny nam', N'Quần jean skinny co giãn tốt', 'jean_skinny_nam.jpg', 420000.00, 350000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(5, 2, N'Quần jean baggy nữ', N'Quần jean baggy nữ trẻ trung', 'jean_baggy_nu.jpg', 390000.00, 330000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(6, 2, N'Quần jean ống rộng', N'Quần jean ống rộng phong cách Hàn Quốc', 'jean_ong_rong.jpg', 450000.00, 390000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(7, 3, N'Váy hoa nhí', N'Váy hoa nhí nhẹ nhàng, nữ tính', 'vay_hoa_nhi.jpg', 320000.00, 270000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(8, 3, N'Váy công sở dáng dài', N'Váy công sở thanh lịch', 'vay_cong_so.jpg', 480000.00, 420000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(9, 3, N'Váy dự tiệc sang trọng', N'Váy dự tiệc thiết kế sang trọng', 'vay_du_tiec.jpg', 750000.00, 650000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(10, 4, N'Áo khoác jean unisex', N'Áo khoác jean unisex cá tính', 'ao_khoac_jean.jpg', 520000.00, 450000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(11, 4, N'Áo khoác dù chống nắng', N'Áo khoác dù mỏng nhẹ chống nắng', 'ao_khoac_du.jpg', 280000.00, 240000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(12, 4, N'Áo hoodie nỉ', N'Áo hoodie nỉ ấm áp mùa đông', 'ao_hoodie.jpg', 390000.00, 340000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(13, 5, N'Nón bucket thời trang', N'Nón bucket phù hợp đi chơi, du lịch', 'non_bucket.jpg', 120000.00, 99000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(14, 5, N'Túi tote canvas', N'Túi tote canvas đơn giản, tiện dụng', 'tui_tote.jpg', 180000.00, 150000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(15, 5, N'Thắt lưng da basic', N'Thắt lưng da basic dễ phối đồ', 'that_lung_da.jpg', 200000.00, 170000.00, 'ACTIVE', '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(16, 1, N'Áo thun graphic streetwear', N'Áo thun nam in graphic phong cách đường phố, chất cotton co giãn.', 'ao_thun_graphic_streetwear.jpg', 249000.00, 199000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(17, 1, N'Áo thun minimal logo nhỏ', N'Áo thun basic logo nhỏ trước ngực, dễ phối quần jean hoặc short.', 'ao_thun_minimal_logo.jpg', 199000.00, 169000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(18, 1, N'Áo thun wash form rộng', N'Áo thun wash màu vintage, form rộng trẻ trung.', 'ao_thun_wash_form_rong.jpg', 289000.00, 239000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(19, 1, N'Áo thun thể thao quick dry', N'Áo thun chất liệu nhanh khô, phù hợp vận động.', 'ao_thun_the_thao_quickdry.jpg', 229000.00, 189000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(20, 6, N'Áo polo pique basic', N'Áo polo nam chất pique thoáng mát, phù hợp đi học, đi làm.', 'ao_polo_pique_basic.jpg', 299000.00, 249000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(21, 6, N'Áo polo phối cổ thể thao', N'Áo polo phối cổ trẻ trung, form vừa người.', 'ao_polo_phoi_co.jpg', 329000.00, 279000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(22, 6, N'Áo polo premium chống nhăn', N'Áo polo chất liệu mềm, ít nhăn, phù hợp công sở.', 'ao_polo_premium_chong_nhan.jpg', 379000.00, 319000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(23, 7, N'Áo sơ mi Oxford dài tay', N'Áo sơ mi Oxford nam lịch sự, dễ mặc với quần jean hoặc kaki.', 'ao_so_mi_oxford_dai_tay.jpg', 399000.00, 339000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(24, 7, N'Áo sơ mi caro casual', N'Áo sơ mi caro nam phong cách casual, mặc ngoài áo thun rất hợp.', 'ao_so_mi_caro_casual.jpg', 349000.00, 299000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(25, 7, N'Áo sơ mi linen ngắn tay', N'Áo sơ mi linen thoáng mát, phù hợp thời tiết nóng.', 'ao_so_mi_linen_ngan_tay.jpg', 369000.00, 319000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(26, 2, N'Quần jean slim fit xanh đậm', N'Quần jean nam slim fit, vải co giãn nhẹ, dễ phối đồ.', 'quan_jean_slim_fit_xanh_dam.jpg', 499000.00, 429000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(27, 2, N'Quần jean straight đen', N'Quần jean ống đứng màu đen, phù hợp phong cách tối giản.', 'quan_jean_straight_den.jpg', 529000.00, 459000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(28, 2, N'Quần jean rách nhẹ street style', N'Quần jean rách nhẹ cá tính, phù hợp đi chơi.', 'quan_jean_rach_nhe.jpg', 559000.00, 489000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(29, 8, N'Quần short kaki basic', N'Quần short kaki nam basic, mặc đi học, đi chơi đều phù hợp.', 'quan_short_kaki_basic.jpg', 299000.00, 249000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(30, 8, N'Quần short thể thao basic', N'Quần short thể thao nhẹ, co giãn, thoải mái vận động.', 'quan_short_the_thao_basic.jpg', 239000.00, 199000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(31, 8, N'Quần short jean nam', N'Quần short jean nam năng động, phù hợp mùa hè.', 'quan_short_jean_nam.jpg', 349000.00, 299000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(32, 4, N'Áo khoác bomber basic', N'Áo khoác bomber nam trẻ trung, dễ phối outfit.', 'ao_khoac_bomber_basic.jpg', 599000.00, 499000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(33, 4, N'Áo khoác gió chống nước nhẹ', N'Áo khoác gió mỏng nhẹ, chống nước nhẹ, tiện mang theo.', 'ao_khoac_gio_chong_nuoc.jpg', 459000.00, 399000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(34, 4, N'Áo khoác dù phối màu', N'Áo khoác dù phối màu cá tính, form rộng thoải mái.', 'ao_khoac_du_phoi_mau.jpg', 529000.00, 459000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(35, 9, N'Áo hoodie basic form rộng', N'Áo hoodie nỉ form rộng, phù hợp phong cách streetwear.', 'ao_hoodie_basic_form_rong.jpg', 459000.00, 389000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(36, 9, N'Áo hoodie zip kéo khóa', N'Hoodie zip kéo khóa tiện dụng, có thể mặc ngoài áo thun.', 'ao_hoodie_zip_keo_khoa.jpg', 499000.00, 429000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(37, 9, N'Áo sweater trơn minimal', N'Sweater trơn phong cách minimal, phù hợp thời tiết se lạnh.', 'ao_sweater_tron_minimal.jpg', 429000.00, 369000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(38, 10, N'Bộ mặc nhà cotton basic', N'Bộ mặc nhà cotton mềm mại, thoải mái khi sinh hoạt.', 'bo_mac_nha_cotton_basic.jpg', 299000.00, 249000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(39, 10, N'Quần jogger mặc nhà', N'Quần jogger chất thun mềm, phù hợp mặc nhà và đi dạo.', 'quan_jogger_mac_nha.jpg', 259000.00, 219000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(40, 10, N'Áo tanktop cotton nam', N'Áo tanktop cotton thoáng mát, phù hợp mặc nhà hoặc tập luyện.', 'ao_tanktop_cotton_nam.jpg', 159000.00, 129000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(41, 5, N'Túi đeo chéo mini', N'Túi đeo chéo mini tiện dụng, phù hợp đi chơi.', 'tui_deo_cheo_mini.jpg', 249000.00, 199000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(42, 5, N'Balo basic đi học', N'Balo basic many ngăn, phù hợp đi học và đi làm.', 'balo_basic_di_hoc.jpg', 399000.00, 349000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(43, 5, N'Ví da nam basic', N'Ví da nam kiểu dáng gọn, nhiều ngăn đựng thẻ.', 'vi_da_nam_basic.jpg', 229000.00, 189000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(44, 5, N'Nón lưỡi trai logo basic', N'Nón lưỡi trai basic dễ phối đồ, phù hợp đi chơi.', 'non_luoi_trai_logo_basic.jpg', 169000.00, 139000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(45, 5, N'Vớ cổ cao basic combo 3 đôi', N'Combo vớ cổ cao basic, chất liệu mềm, thấm hút tốt.', 'vo_co_cao_combo_3_doi.jpg', 99000.00, 79000.00, 'ACTIVE', '2026-06-06 13:01:48', '2026-06-06 13:01:48');
SET IDENTITY_INSERT products OFF;
GO

SET IDENTITY_INSERT product_variants ON;
INSERT INTO product_variants (id, product_id, size, color, stock_quantity, created_at, updated_at) VALUES 
(1, 1, 'M', N'Trắng', 18, '2026-06-06 12:55:43', '2026-06-06 12:58:25'),
(2, 1, 'M', N'Đen', 18, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(3, 1, 'L', N'Trắng', 15, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(4, 1, 'L', N'Đen', 12, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(5, 2, 'M', N'Xám', 9, '2026-06-06 12:55:43', '2026-06-06 12:58:25'),
(6, 2, 'M', N'Đen', 14, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(7, 2, 'L', N'Xám', 8, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(8, 2, 'L', N'Đen', 11, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(9, 3, 'M', N'Trắng', 16, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(10, 3, 'M', N'Xanh navy', 13, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(11, 3, 'L', N'Trắng', 10, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(12, 3, 'L', N'Xanh navy', 9, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(13, 4, '30', N'Xanh đậm', 12, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(14, 4, '30', N'Đen', 10, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(15, 4, '32', N'Xanh đậm', 9, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(16, 4, '32', N'Đen', 7, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(17, 5, 'S', N'Xanh nhạt', 14, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(18, 5, 'S', N'Đen', 11, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(19, 5, 'M', N'Xanh nhạt', 10, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(20, 5, 'M', N'Đen', 8, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(21, 6, 'M', N'Xanh jean', 9, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(22, 6, 'M', N'Đen', 7, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(23, 6, 'L', N'Xanh jean', 6, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(24, 6, 'L', N'Đen', 5, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(25, 7, 'S', N'Hồng', 13, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(26, 7, 'S', N'Vàng', 10, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(27, 7, 'M', N'Hồng', 8, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(28, 7, 'M', N'Vàng', 6, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(29, 8, 'M', N'Đen', 7, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(30, 8, 'M', N'Be', 9, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(31, 8, 'L', N'Đen', 6, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(32, 8, 'L', N'Be', 5, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(33, 9, 'M', N'Đỏ', 5, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(34, 9, 'M', N'Đen', 4, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(35, 9, 'L', N'Đỏ', 3, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(36, 9, 'L', N'Đen', 2, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(37, 10, 'M', N'Xanh jean', 10, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(38, 10, 'M', N'Đen', 8, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(39, 10, 'L', N'Xanh jean', 7, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(40, 10, 'L', N'Đen', 6, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(41, 11, 'M', N'Xám', 18, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(42, 11, 'M', N'Trắng', 15, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(43, 11, 'L', N'Xám', 12, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(44, 11, 'L', N'Trắng', 10, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(45, 12, 'M', N'Đen', 13, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(46, 12, 'M', N'Nâu', 11, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(47, 12, 'L', N'Đen', 9, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(48, 12, 'L', N'Nâu', 7, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(49, 13, 'Free Size', N'Đen', 25, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(50, 13, 'Free Size', N'Be', 20, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(51, 13, 'Free Size', N'Trắng', 18, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(52, 13, 'Free Size', N'Nâu', 15, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(53, 14, 'Free Size', N'Trắng', 16, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(54, 14, 'Free Size', N'Đen', 14, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(55, 14, 'Free Size', N'Be', 12, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(56, 14, 'Free Size', N'Xanh', 10, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(57, 15, 'M', N'Đen', 12, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(58, 15, 'M', N'Nâu', 10, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(59, 15, 'L', N'Đen', 8, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(60, 15, 'L', N'Nâu', 6, '2026-06-06 12:55:43', '2026-06-06 12:55:43'),
(61, 16, 'M', N'Đen', 25, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(62, 16, 'M', N'Trắng', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(63, 16, 'L', N'Đen', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(64, 16, 'XL', N'Trắng', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(65, 17, 'S', N'Trắng', 22, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(66, 17, 'M', N'Trắng', 28, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(67, 17, 'L', N'Đen', 21, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(68, 17, 'XL', N'Xám', 17, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(69, 18, 'M', N'Xám khói', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(70, 18, 'L', N'Xám khói', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(71, 18, 'M', N'Nâu', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(72, 18, 'XL', N'Nâu', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(73, 19, 'M', N'Xanh navy', 19, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(74, 19, 'L', N'Xanh navy', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(75, 19, 'M', N'Đen', 24, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(76, 19, 'XL', N'Đen', 13, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(77, 20, 'M', N'Trắng', 30, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(78, 20, 'L', N'Trắng', 24, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(79, 20, 'M', N'Đen', 26, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(80, 20, 'XL', N'Đen', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(81, 21, 'M', N'Xanh rêu', 17, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(82, 21, 'L', N'Xanh rêu', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(83, 21, 'M', N'Be', 19, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(84, 21, 'XL', N'Be', 11, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(85, 22, 'M', N'Nâu', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(86, 22, 'L', N'Nâu', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(87, 22, 'M', N'Xanh navy', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(88, 22, 'XL', N'Xanh navy', 9, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(89, 23, 'M', N'Trắng', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(90, 23, 'L', N'Trắng', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(91, 23, 'M', N'Xanh nhạt', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(92, 23, 'XL', N'Xanh nhạt', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(93, 24, 'M', N'Đỏ đen', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(94, 24, 'L', N'Đỏ đen', 13, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(95, 24, 'M', N'Xanh đen', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(96, 24, 'XL', N'Xanh đen', 8, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(97, 25, 'M', N'Be', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(98, 25, 'L', N'Be', 17, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(99, 25, 'M', N'Trắng kem', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(100, 25, 'XL', N'Trắng kem', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(101, 26, '29', N'Xanh đậm', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(102, 26, '30', N'Xanh đậm', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(103, 26, '31', N'Xanh đậm', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(104, 26, '32', N'Xanh đậm', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(105, 27, '29', N'Đen', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(106, 27, '30', N'Đen', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(107, 27, '31', N'Đen', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(108, 27, '32', N'Đen', 9, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(109, 28, '29', N'Xanh nhạt', 8, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(110, 28, '30', N'Xanh nhạt', 11, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(111, 28, '31', N'Xám', 9, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(112, 28, '32', N'Xám', 7, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(113, 29, 'M', N'Đen', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(114, 29, 'L', N'Đen', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(115, 29, 'M', N'Be', 22, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(116, 29, 'XL', N'Be', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(117, 30, 'M', N'Đen', 25, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(118, 30, 'L', N'Đen', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(119, 30, 'M', N'Xám', 21, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(120, 30, 'XL', N'Xám', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(121, 31, 'M', N'Xanh jean', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(122, 31, 'L', N'Xanh jean', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(123, 31, 'M', N'Đen', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(124, 31, 'XL', N'Đen', 9, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(125, 32, 'M', N'Đen', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(126, 32, 'L', N'Đen', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(127, 32, 'M', N'Xanh rêu', 11, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(128, 32, 'XL', N'Xanh rêu', 7, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(129, 33, 'M', N'Xám', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(130, 33, 'L', N'Xám', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(131, 33, 'M', N'Đen', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(132, 33, 'XL', N'Đen', 11, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(133, 34, 'M', N'Đen trắng', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(134, 34, 'L', N'Đen trắng', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(135, 34, 'M', N'Xanh trắng', 11, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(136, 34, 'XL', N'Xanh trắng', 6, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(137, 35, 'M', N'Đen', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(138, 35, 'L', N'Đen', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(139, 35, 'M', N'Xám', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(140, 35, 'XL', N'Xám', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(141, 36, 'M', N'Nâu', 13, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(142, 36, 'L', N'Nâu', 11, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(143, 36, 'M', N'Đen', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(144, 36, 'XL', N'Đen', 8, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(145, 37, 'M', N'Kem', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(146, 37, 'L', N'Kem', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(147, 37, 'M', N'Xanh navy', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(148, 37, 'XL', N'Xanh navy', 7, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(149, 38, 'M', N'Xám', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(150, 38, 'L', N'Xám', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(151, 38, 'M', N'Xanh navy', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(152, 38, 'XL', N'Xanh navy', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(153, 39, 'M', N'Đen', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(154, 39, 'L', N'Đen', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(155, 39, 'M', N'Xám', 17, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(156, 39, 'XL', N'Xám', 13, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(157, 40, 'M', N'Trắng', 24, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(158, 40, 'L', N'Trắng', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(159, 40, 'M', N'Đen', 22, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(160, 40, 'XL', N'Đen', 16, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(161, 41, 'Free Size', N'Đen', 30, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(162, 41, 'Free Size', N'Xám', 22, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(163, 41, 'Free Size', N'Be', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(164, 41, 'Free Size', N'Xanh rêu', 15, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(165, 42, 'Free Size', N'Đen', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(166, 42, 'Free Size', N'Xám', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(167, 42, 'Free Size', N'Xanh navy', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(168, 42, 'Free Size', N'Nâu', 9, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(169, 43, 'Free Size', N'Đen', 25, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(170, 43, 'Free Size', N'Nâu', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(171, 43, 'Free Size', N'Xám', 12, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(172, 43, 'Free Size', N'Nâu đậm', 10, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(173, 44, 'Free Size', N'Đen', 28, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(174, 44, 'Free Size', N'Trắng', 24, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(175, 44, 'Free Size', N'Be', 18, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(176, 44, 'Free Size', N'Xanh navy', 14, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(177, 45, 'Free Size', N'Trắng', 40, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(178, 45, 'Free Size', N'Đen', 35, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(179, 45, 'Free Size', N'Xám', 30, '2026-06-06 13:01:48', '2026-06-06 13:01:48'),
(180, 45, 'Free Size', N'Nâu', 20, '2026-06-06 13:01:48', '2026-06-06 13:01:48');
SET IDENTITY_INSERT product_variants OFF;
GO

SET IDENTITY_INSERT orders ON;
INSERT INTO orders (id, user_id, order_date, total_amount, shipping_address, receiver_phone, status, stock_deducted, created_at, updated_at) VALUES 
(1, 2, '2026-06-06 12:58:18', 420000.00, N'123 Nguyễn Trãi, Quận 1, TP.HCM', '0911111111', 'CONFIRMED', 1, '2026-06-06 12:58:18', '2026-06-06 13:03:39'),
(2, 2, '2026-06-06 13:04:57', 420000.00, N'123 Nguyễn Trãi, Quận 1, TP.HCM', '0911111111', 'PENDING', 0, '2026-06-06 13:04:57', '2026-06-06 13:04:57');
SET IDENTITY_INSERT orders OFF;
GO

SET IDENTITY_INSERT order_details ON;
INSERT INTO order_details (id, order_id, variant_id, quantity, price_at_order_time, subtotal) VALUES 
(1, 1, 1, 2, 120000.00, 240000.00),
(2, 1, 5, 1, 180000.00, 180000.00),
(3, 2, 1, 2, 120000.00, 240000.00),
(4, 2, 5, 1, 180000.00, 180000.00);
SET IDENTITY_INSERT order_details OFF;
GO

-- =========================================================================
-- 4. KHỞI TẠO CÁC TRIGGER NGHIỆP VỤ (BUSINESS LOGIC)
-- =========================================================================

CREATE TRIGGER trg_order_details_before_insert ON order_details INSTEAD OF INSERT AS
BEGIN
    INSERT INTO order_details (order_id, variant_id, quantity, price_at_order_time, subtotal)
    SELECT order_id, variant_id, quantity, price_at_order_time, (quantity * price_at_order_time)
    FROM inserted;
END;
GO

CREATE TRIGGER trg_orders_stock_before_update ON orders AFTER UPDATE AS 
BEGIN
    SET NOCOUNT ON;
    
    -- Khi chuyển trạng thái sang CONFIRMED và chưa từng trừ kho
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.id = d.id WHERE i.status = 'CONFIRMED' AND d.stock_deducted = 0)
    BEGIN
        DECLARE @insufficient_count INT = 0;

        SELECT @insufficient_count = COUNT(*)
        FROM inserted i
        JOIN order_details od ON i.id = od.order_id
        JOIN product_variants pv ON od.variant_id = pv.id
        JOIN deleted d ON i.id = d.id
        WHERE d.stock_deducted = 0 AND pv.stock_quantity < od.quantity;

        IF @insufficient_count > 0
        BEGIN
            RAISERROR ('Không đủ tồn kho để xác nhận đơn hàng', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE pv
        SET pv.stock_quantity = pv.stock_quantity - od.quantity
        FROM product_variants pv
        JOIN order_details od ON pv.id = od.variant_id
        JOIN inserted i ON od.order_id = i.id
        JOIN deleted d ON i.id = d.id
        WHERE i.status = 'CONFIRMED' AND d.stock_deducted = 0;

        UPDATE orders
        SET stock_deducted = 1
        WHERE id IN (SELECT i.id FROM inserted i JOIN deleted d ON i.id = d.id WHERE i.status = 'CONFIRMED' AND d.stock_deducted = 0);
    END

    -- Khi chuyển sang CANCELLED mà trước đây đã từng trừ kho
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.id = d.id WHERE i.status = 'CANCELLED' AND d.stock_deducted = 1)
    BEGIN
        UPDATE pv
        SET pv.stock_quantity = pv.stock_quantity + od.quantity
        FROM product_variants pv
        JOIN order_details od ON pv.id = od.variant_id
        JOIN inserted i ON od.order_id = i.id
        JOIN deleted d ON i.id = d.id
        WHERE i.status = 'CANCELLED' AND d.stock_deducted = 1;

        UPDATE orders
        SET stock_deducted = 0
        WHERE id IN (SELECT i.id FROM inserted i JOIN deleted d ON i.id = d.id WHERE i.status = 'CANCELLED' AND d.stock_deducted = 1);
    END
END;
GO

-- =========================================================================
-- 5. KHỞI TẠO CÁC STORED PROCEDURES (THỦ TỤC LƯU TRỮ)
-- =========================================================================

CREATE PROCEDURE sp_GetLowStockProducts
    @p_threshold_value INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        pv.id AS product_variant_id,
        p.id AS product_id,
        p.name AS product_name,
        pv.size,
        pv.color,
        pv.stock_quantity
    FROM product_variants pv
    INNER JOIN products p ON pv.product_id = p.id
    WHERE pv.stock_quantity <= @p_threshold_value
      AND p.status = 'ACTIVE'
    ORDER BY pv.stock_quantity ASC, p.name ASC;
END;
GO

CREATE PROCEDURE sp_GetProductFiltering
    @p_keyword NVARCHAR(255) = NULL,
    @p_min_price DECIMAL(12,2) = NULL,
    @p_max_price DECIMAL(12,2) = NULL,
    @p_size VARCHAR(20) = NULL,
    @p_color NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.id,
        p.category_id,
        c.name AS category_name,
        p.name,
        p.description,
        p.main_image,
        p.original_price,
        p.sale_price,
        ISNULL(p.sale_price, p.original_price) AS current_price,
        p.status,
        ISNULL(SUM(pv.stock_quantity), 0) AS total_stock
    FROM products p
    INNER JOIN categories c ON p.category_id = c.id
    INNER JOIN product_variants pv ON p.id = pv.product_id
    WHERE p.status = 'ACTIVE'
      AND (@p_keyword IS NULL OR @p_keyword = '' OR p.name LIKE '%' + @p_keyword + '%' OR p.description LIKE '%' + @p_keyword + '%' OR c.name LIKE '%' + @p_keyword + '%')
      AND (@p_min_price IS NULL OR ISNULL(p.sale_price, p.original_price) >= @p_min_price)
      AND (@p_max_price IS NULL OR ISNULL(p.sale_price, p.original_price) <= @p_max_price)
      AND (@p_size IS NULL OR @p_size = '' OR pv.size = @p_size)
      AND (@p_color IS NULL OR @p_color = '' OR pv.color = @p_color)
    GROUP BY
        p.id, p.category_id, c.name, p.name, p.description, p.main_image, p.original_price, p.sale_price, p.status
    ORDER BY p.id DESC;
END;
GO

CREATE PROCEDURE sp_GetProductsByCategory
    @p_category_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.id,
        p.category_id,
        c.name AS category_name,
        p.name,
        p.description,
        p.main_image,
        p.original_price,
        p.sale_price,
        ISNULL(p.sale_price, p.original_price) AS current_price,
        p.status,
        ISNULL(SUM(pv.stock_quantity), 0) AS total_stock,
        p.created_at,
        p.updated_at
    FROM products p
    INNER JOIN categories c ON p.category_id = c.id
    LEFT JOIN product_variants pv ON p.id = pv.product_id
    WHERE p.category_id = @p_category_id
      AND p.status = 'ACTIVE'
    GROUP BY
        p.id, p.category_id, c.name, p.name, p.description, p.main_image, p.original_price, p.sale_price, p.status, p.created_at, p.updated_at
    ORDER BY p.id DESC;
END;
GO

CREATE PROCEDURE sp_GetRevenueByMonth
    @p_year INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        MONTH(order_date) AS [month],
        SUM(total_amount) AS revenue
    FROM orders
    WHERE status = 'COMPLETED'
      AND YEAR(order_date) = @p_year
    GROUP BY MONTH(order_date)
    ORDER BY MONTH(order_date);
END;
GO

CREATE PROCEDURE sp_UpdateOrderStatus
    @p_order_id BIGINT,
    @p_new_status VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF @p_new_status NOT IN ('PENDING', 'CONFIRMED', 'SHIPPING', 'COMPLETED', 'CANCELLED')
    BEGIN
        RAISERROR ('Trạng thái đơn hàng không hợp lệ', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM orders WHERE id = @p_order_id)
    BEGIN
        RAISERROR ('Đơn hàng không tồn tại', 16, 1);
        RETURN;
    END

    UPDATE orders
    SET status = @p_new_status
    WHERE id = @p_order_id;

    SELECT id, user_id, total_amount, status, stock_deducted, updated_at
    FROM orders
    WHERE id = @p_order_id;
END;
GO

CREATE PROCEDURE sp_GetProductDetail
    @p_product_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.id,
        p.category_id,
        c.name AS category_name,
        p.name,
        p.description,
        p.main_image,
        p.original_price,
        p.sale_price,
        ISNULL(p.sale_price, p.original_price) AS current_price,
        p.status,
        (
            SELECT pv.id AS productDetailId, pv.size, pv.color, pv.stock_quantity AS stockQuantity
            FROM product_variants pv
            WHERE pv.product_id = p.id AND pv.stock_quantity > 0
            FOR JSON PATH
        ) AS variants
    FROM products p
    INNER JOIN categories c ON p.category_id = c.id
    WHERE p.id = @p_product_id AND p.status = 'ACTIVE';
END;
GO

CREATE PROCEDURE sp_CreateOrder
    @p_user_id BIGINT,
    @p_shipping_address NVARCHAR(500),
    @p_receiver_phone VARCHAR(20),
    @p_items NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_order_id BIGINT;
    DECLARE @v_total_amount DECIMAL(12,2) = 0;

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @p_user_id AND role = 'CUSTOMER')
    BEGIN
        RAISERROR ('User không tồn tại hoặc không phải tài khoản CUSTOMER', 16, 1);
        RETURN;
    END

    IF @p_items IS NULL OR ISJSON(@p_items) = 0
    BEGIN
        RAISERROR ('Danh sách sản phẩm trong giỏ hàng (JSON) không hợp lệ', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO orders (user_id, total_amount, shipping_address, receiver_phone, status, stock_deducted)
        VALUES (@p_user_id, 0, @p_shipping_address, @p_receiver_phone, 'PENDING', 0);

        SET @v_order_id = SCOPE_IDENTITY();

        -- Bóc tách chuỗi JSON khớp chính xác với cấu trúc cột variantId mới
        SELECT 
            variantId, 
            quantity,
            stock_quantity,
            ISNULL(p.sale_price, p.original_price) AS price
        INTO #CartItems
        FROM OPENJSON(@p_items)
        WITH (
            productDetailId BIGINT '$.productDetailId',
            quantity INT '$.quantity'
        ) json_data
        INNER JOIN product_variants pv ON json_data.productDetailId = pv.id
        INNER JOIN products p ON pv.product_id = p.id
        WHERE p.status = 'ACTIVE';

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR ('Biến thể sản phẩm không hợp lệ hoặc sản phẩm đã ngừng bán', 16, 1);
        END

        IF EXISTS (SELECT 1 FROM #CartItems WHERE stock_quantity < quantity)
        BEGIN
            RAISERROR ('Có sản phẩm không đủ số lượng hàng trong kho', 16, 1);
        END

        INSERT INTO order_details (order_id, variant_id, quantity, price_at_order_time, subtotal)
        SELECT @v_order_id, variantId, quantity, price, (price * quantity)
        FROM #CartItems;

        SELECT @v_total_amount = SUM(price * quantity) FROM #CartItems;

        UPDATE orders
        SET total_amount = @v_total_amount
        WHERE id = @v_order_id;

        DROP TABLE #CartItems;

        COMMIT TRANSACTION;

        SELECT 
            @v_order_id AS order_id,
            @v_total_amount AS total_amount,
            N'Tạo đơn hàng thành công!' AS message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#CartItems') IS NOT NULL DROP TABLE #CartItems;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO
USE ClothesShopDB;
GO

-- Kiểm tra nếu tồn tại rồi thì xóa đi để tạo mới không bị xung đột
IF OBJECT_ID('dbo.sp_CreateOrder', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_CreateOrder;
END
GO

-- Đổi sang dùng CREATE PROCEDURE để khởi tạo mới hoàn toàn vào Database
CREATE PROCEDURE sp_CreateOrder
    @p_user_id BIGINT,
    @p_shipping_address NVARCHAR(500),
    @p_receiver_phone VARCHAR(20),
    @p_items NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_order_id BIGINT;
    DECLARE @v_total_amount DECIMAL(12,2) = 0;

    -- 1. Kiểm tra sự tồn tại của User khách hàng
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @p_user_id AND role = 'CUSTOMER')
    BEGIN
        RAISERROR ('User không tồn tại hoặc không phải tài khoản CUSTOMER', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra tính hợp lệ của chuỗi dữ liệu JSON
    IF @p_items IS NULL OR ISJSON(@p_items) = 0
    BEGIN
        RAISERROR ('Danh sách sản phẩm trong giỏ hàng (JSON) không hợp lệ', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 3. Tạo một đơn hàng mới (Trạng thái mặc định là PENDING)
        INSERT INTO orders (user_id, total_amount, shipping_address, receiver_phone, status, stock_deducted)
        VALUES (@p_user_id, 0, @p_shipping_address, @p_receiver_phone, 'PENDING', 0);

        SET @v_order_id = SCOPE_IDENTITY();

        -- 4. Đọc chuỗi JSON và nạp vào bảng tạm #CartItems (Đã đồng bộ trường variant_id)
        SELECT 
            json_data.productDetailId AS variant_id, 
            json_data.quantity,
            pv.stock_quantity,
            ISNULL(p.sale_price, p.original_price) AS price
        INTO #CartItems
        FROM OPENJSON(@p_items)
        WITH (
            productDetailId BIGINT '$.productDetailId',
            quantity INT '$.quantity'
        ) json_data
        INNER JOIN product_variants pv ON json_data.productDetailId = pv.id
        INNER JOIN products p ON pv.product_id = p.id
        WHERE p.status = 'ACTIVE';

        -- 5. Kiểm tra tính hợp lệ của dữ liệu sau khi map
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR ('Biến thể sản phẩm không hợp lệ hoặc sản phẩm đã ngừng bán', 16, 1);
        END

        -- 6. Kiểm tra số lượng tồn kho trong kho
        IF EXISTS (SELECT 1 FROM #CartItems WHERE stock_quantity < quantity)
        BEGIN
            RAISERROR ('Có sản phẩm không đủ số lượng hàng trong kho', 16, 1);
        END

        -- 7. Chèn dữ liệu từ bảng tạm vào bảng chi tiết đơn hàng (order_details)
        INSERT INTO order_details (order_id, variant_id, quantity, price_at_order_time, subtotal)
        SELECT @v_order_id, variant_id, quantity, price, (price * quantity)
        FROM #CartItems;

        -- 8. Tính toán tổng số tiền của toàn bộ đơn hàng và cập nhật lại bảng orders
        SELECT @v_total_amount = SUM(price * quantity) FROM #CartItems;

        UPDATE orders
        SET total_amount = @v_total_amount
        WHERE id = @v_order_id;

        -- Xóa bảng tạm để giải phóng bộ nhớ
        DROP TABLE #CartItems;

        COMMIT TRANSACTION;

        -- Trả về thông báo thành công cho ứng dụng Java Backend nhận biết
        SELECT 
            @v_order_id AS order_id,
            @v_total_amount AS total_amount,
            N'Tạo đơn hàng thành công!' AS message;

    END TRY
    BEGIN CATCH
        -- Nếu xảy ra lỗi, hoàn trả (Rollback) lại toàn bộ dữ liệu để tránh lỗi bất đồng bộ
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#CartItems') IS NOT NULL DROP TABLE #CartItems;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO


-- =========================================================================
-- 6. THỐNG KÊ TỔNG HỢP HỆ THỐNG
-- =========================================================================
PRINT N'=== THỐNG KÊ TỔNG HỢP HỆ THỐNG ===';
GO

-- 1. Tổng số danh mục
SELECT 
    COUNT(*) AS TongSoDanhMuc
FROM categories;
GO

-- 2. Tổng số sản phẩm
SELECT 
    COUNT(*) AS TongSoSanPham
FROM products;
GO

-- 3. Tổng số sản phẩm đang hoạt động / ngừng hoạt động
SELECT 
    status AS TrangThaiSanPham,
    COUNT(*) AS SoLuong
FROM products
GROUP BY status;
GO

-- 4. Tổng số biến thể sản phẩm
SELECT 
    COUNT(*) AS TongSoBienThe
FROM product_variants;
GO

-- 5. Tổng tồn kho toàn hệ thống
SELECT 
    SUM(stock_quantity) AS TongTonKho
FROM product_variants;
GO

-- 6. Thống kê tài khoản theo vai trò
SELECT 
    role AS VaiTro,
    COUNT(*) AS SoLuongTaiKhoan
FROM users
GROUP BY role;
GO

-- 7. Tổng số đơn hàng
SELECT 
    COUNT(*) AS TongSoDonHang
FROM orders;
GO

-- 8. Thống kê đơn hàng theo trạng thái
SELECT 
    status AS TrangThaiDonHang,
    COUNT(*) AS SoLuongDon,
    SUM(total_amount) AS TongGiaTri
FROM orders
GROUP BY status;
GO

-- 9. Tổng doanh thu từ đơn hàng đã hoàn thành
SELECT 
    ISNULL(SUM(total_amount), 0) AS TongDoanhThu
FROM orders
WHERE status = 'COMPLETED';
GO

-- 10. Doanh thu theo tháng
SELECT 
    YEAR(order_date) AS Nam,
    MONTH(order_date) AS Thang,
    COUNT(*) AS SoDonHoanThanh,
    SUM(total_amount) AS DoanhThu
FROM orders
WHERE status = 'COMPLETED'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY Nam, Thang;
GO

-- 11. Thống kê sản phẩm theo danh mục
SELECT 
    c.id AS MaDanhMuc,
    c.name AS TenDanhMuc,
    COUNT(p.id) AS SoLuongSanPham
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.id, c.name
ORDER BY c.id;
GO

-- 12. Tồn kho theo từng sản phẩm
SELECT 
    p.id AS MaSanPham,
    p.name AS TenSanPham,
    SUM(pv.stock_quantity) AS TongTonKho
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
GROUP BY p.id, p.name
ORDER BY TongTonKho DESC;
GO

-- 13. Các biến thể sắp hết hàng
SELECT 
    pv.id AS MaBienThe,
    p.name AS TenSanPham,
    pv.size AS KichCo,
    pv.color AS MauSac,
    pv.stock_quantity AS SoLuongTon
FROM product_variants pv
INNER JOIN products p ON pv.product_id = p.id
WHERE pv.stock_quantity <= 10
ORDER BY pv.stock_quantity ASC;
GO

-- 14. Top 5 sản phẩm bán chạy
SELECT TOP 5
    p.id AS MaSanPham,
    p.name AS TenSanPham,
    SUM(od.quantity) AS TongSoLuongBan,
    SUM(od.subtotal) AS TongTienBanDuoc
FROM order_details od
INNER JOIN product_variants pv ON od.variant_id = pv.id
INNER JOIN products p ON pv.product_id = p.id
INNER JOIN orders o ON od.order_id = o.id
WHERE o.status IN ('CONFIRMED', 'SHIPPING', 'COMPLETED')
GROUP BY p.id, p.name
ORDER BY TongSoLuongBan DESC;
GO

-- 15. Top 5 khách hàng mua nhiều nhất
SELECT TOP 5
    u.id AS MaKhachHang,
    u.full_name AS TenKhachHang,
    u.email,
    COUNT(o.id) AS SoDonHang,
    SUM(o.total_amount) AS TongTienMua
FROM users u
INNER JOIN orders o ON u.id = o.user_id
WHERE u.role = 'CUSTOMER'
GROUP BY u.id, u.full_name, u.email
ORDER BY TongTienMua DESC;
GO