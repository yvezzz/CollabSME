package com.collabsme.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final NotificationWebSocketHandler notificationWebSocketHandler;
    private final JwtTokenProvider jwtTokenProvider;

    public WebSocketConfig(NotificationWebSocketHandler notificationWebSocketHandler,
                           JwtTokenProvider jwtTokenProvider) {
        this.notificationWebSocketHandler = notificationWebSocketHandler;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(notificationWebSocketHandler, "/ws/notifications/")
                .setAllowedOrigins("*")
                .addInterceptors(new JwtWebSocketInterceptor(jwtTokenProvider));
    }
}
