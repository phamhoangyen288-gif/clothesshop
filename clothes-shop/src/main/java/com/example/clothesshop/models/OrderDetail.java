package com.example.clothesshop.models;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "order_details")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant productVariant;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "price_at_order_time", nullable = false)
    private Double priceAtOrderTime;

    @Column(nullable = false)
    private Double subtotal;

    public void setPrice(Double price) {
        this.priceAtOrderTime = price;
        if (this.quantity != null && price != null) {
            this.subtotal = price * this.quantity;
        }
    }

    public Double getPrice() {
        return this.priceAtOrderTime;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
        if (this.priceAtOrderTime != null && quantity != null) {
            this.subtotal = this.priceAtOrderTime * quantity;
        }
    }
}
