package com.example.template.order.interfaces;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.Duration;
import java.util.Map;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class OrderControllerTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withStartupTimeout(Duration.ofMinutes(2));

    @LocalServerPort
    int port;

    @BeforeEach
    void setUp() {
        RestAssured.port = port;
    }

    private static Map<String, Object> sampleItem(String price, int qty) {
        return Map.of(
            "productId", UUID.randomUUID().toString(),
            "quantity", qty,
            "priceAmount", new java.math.BigDecimal(price),
            "priceCurrency", "KRW"
        );
    }

    @Test
    void postOrders_happy_returns201() {
        given()
            .contentType(ContentType.JSON)
            .body(Map.of("items", java.util.List.of(sampleItem("1000", 2))))
        .when()
            .post("/orders")
        .then()
            .statusCode(201)
            .body("result", equalTo("SUCCESS"))
            .body("data.id", notNullValue())
            .body("data.status", equalTo("CREATED"))
            .body("data.total.amount", equalTo(2000))
            .body("data.total.currency", equalTo("KRW"));
    }

    @Test
    void postOrders_emptyItems_returns400() {
        given()
            .contentType(ContentType.JSON)
            .body(Map.of("items", java.util.List.of()))
        .when()
            .post("/orders")
        .then()
            .statusCode(400)
            .body("result", equalTo("ERROR"))
            .body("error.code", equalTo("VALIDATION_FAILED"));
    }

    @Test
    void getOrder_notFound_returns404() {
        given()
        .when()
            .get("/orders/" + UUID.randomUUID())
        .then()
            .statusCode(404)
            .body("error.code", equalTo("NOT_FOUND"));
    }

    @Test
    void cancelOrder_invalidTransition_returns400() {
        // Create + cancel + cancel again -> 400 INVALID_STATUS_TRANSITION
        String id = given()
            .contentType(ContentType.JSON)
            .body(Map.of("items", java.util.List.of(sampleItem("1000", 1))))
        .when().post("/orders").then().extract().path("data.id");

        given().when().post("/orders/" + id + "/cancel").then().statusCode(200);

        given()
        .when()
            .post("/orders/" + id + "/cancel")
        .then()
            .statusCode(400)
            .body("error.code", equalTo("INVALID_STATUS_TRANSITION"));
    }

    @Test
    void payOrder_happy_returns200() {
        String id = given()
            .contentType(ContentType.JSON)
            .body(Map.of("items", java.util.List.of(sampleItem("1000", 1))))
        .when().post("/orders").then().extract().path("data.id");

        given()
            .contentType(ContentType.JSON)
            .body(Map.of("paymentRef", "PAY-12345"))
        .when()
            .post("/orders/" + id + "/pay")
        .then()
            .statusCode(200)
            .body("data.status", equalTo("PAID"));
    }
}
