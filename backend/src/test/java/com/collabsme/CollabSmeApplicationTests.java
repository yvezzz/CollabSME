package com.collabsme;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
    "spring.jackson.serialization.fail-on-empty-beans=false",
    "spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect"
})
@TestMethodOrder(MethodOrderer.MethodName.class)
class CollabSmeApplicationTests {

    @Autowired
    private TestRestTemplate restTemplate;

    private static String jwtToken;

    @Test
    void test1_loginSuccess() {
        var login = Map.of("email", "admin@collabsme.com", "password", "Admin123");

        ResponseEntity<Map> response = restTemplate.postForEntity("/api/auth/login/", login, Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().containsKey("tokens"));

        var tokens = (Map<String, Object>) response.getBody().get("tokens");
        assertNotNull(tokens);
        assertTrue(tokens.containsKey("access"));
        assertTrue(tokens.containsKey("refresh"));
        assertNotNull(tokens.get("access"));
        assertNotNull(tokens.get("refresh"));

        var user = (Map<String, Object>) response.getBody().get("user");
        assertNotNull(user);
        assertEquals("admin@collabsme.com", user.get("email"));

        jwtToken = (String) tokens.get("access");
    }

    @Test
    void test2_loginInvalid() {
        var login = Map.of("email", "admin@collabsme.com", "password", "wrongpassword");

        ResponseEntity<Map> response = restTemplate.postForEntity("/api/auth/login/", login, Map.class);

        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    void test3_register() {
        var register = Map.of(
                "first_name", "Jane",
                "last_name", "Doe",
                "email", "jane" + System.currentTimeMillis() + "@example.com",
                "password", "password123",
                "company_name", "New Company"
        );

        ResponseEntity<Map> response = restTemplate.postForEntity("/api/auth/register/", register, Map.class);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().containsKey("tokens"));
        assertTrue(response.getBody().containsKey("user"));
    }

    @Test
    void test4_accessWithoutToken_returns403() {
        var headers = new HttpHeaders();
        var entity = new HttpEntity<Void>(headers);

        ResponseEntity<String> response = restTemplate.exchange(
                "/api/projects/", HttpMethod.GET, entity, String.class);

        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
    }

    @Test
    void test5_getMeWithToken() {
        assertNotNull(jwtToken, "JWT should be available from test1");

        var headers = new HttpHeaders();
        headers.setBearerAuth(jwtToken);
        var entity = new HttpEntity<Void>(headers);

        ResponseEntity<Map> response = restTemplate.exchange(
                "/api/auth/me/", HttpMethod.GET, entity, Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("admin@collabsme.com", response.getBody().get("email"));
    }

    @Test
    void test6_listProjects() {
        assertNotNull(jwtToken);

        var headers = new HttpHeaders();
        headers.setBearerAuth(jwtToken);
        var entity = new HttpEntity<Void>(headers);

        ResponseEntity<String> response = restTemplate.exchange(
                "/api/projects", HttpMethod.GET, entity, String.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().startsWith("["));
        assertTrue(response.getBody().contains("\"title\""));
        assertTrue(response.getBody().contains("\"key\""));
    }

    @Test
    void test7_getProjectStats() {
        assertNotNull(jwtToken);

        var headers = new HttpHeaders();
        headers.setBearerAuth(jwtToken);
        var entity = new HttpEntity<Void>(headers);

        ResponseEntity<Map> response = restTemplate.exchange(
                "/api/projects/dashboard/stats/", HttpMethod.GET, entity, Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().containsKey("total_projects"));
        assertTrue(response.getBody().containsKey("active_tasks"));
    }

    @Test
    void test8_aiChat() {
        assertNotNull(jwtToken);

        var headers = new HttpHeaders();
        headers.setBearerAuth(jwtToken);
        headers.setContentType(MediaType.APPLICATION_JSON);
        var entity = new HttpEntity<>(Map.of("message", "Bonjour"), headers);

        ResponseEntity<Map> response = restTemplate.exchange(
                "/api/ai/chat/", HttpMethod.POST, entity, Map.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().containsKey("response"));
    }
}
