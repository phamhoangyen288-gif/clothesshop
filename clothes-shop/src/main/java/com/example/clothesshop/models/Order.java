package com.example.clothesshop.models;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "order_date")
    private LocalDateTime orderDate;

    @Column(name = "total_amount")
    private Double totalAmount;

    @Column(name = "shipping_address")
    private String shippingAddress;

    @Column(name = "receiver_phone")
    private String phoneNumber;

    @Column(length = 20)
    private String status;

    @Column(name = "stock_deducted")
    private Integer stockDeducted = 0;

    @OneToMany(mappedBy = "order")
    @OrderBy("id ASC")
    private List<OrderDetail> orderDetails = new ArrayList<>();
}
