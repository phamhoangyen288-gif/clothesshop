package com.example.clothesshop.repositories;

import com.example.clothesshop.models.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByUserUsernameOrderByOrderDateDesc(String username);

    @Query("""
            SELECT DISTINCT o
            FROM Order o
            LEFT JOIN FETCH o.user
            LEFT JOIN FETCH o.orderDetails od
            LEFT JOIN FETCH od.productVariant pv
            LEFT JOIN FETCH pv.product p
            LEFT JOIN FETCH p.category
            WHERE o.id = :id
            """)
    Optional<Order> findInvoiceById(@Param("id") Long id);
}
