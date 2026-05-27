package com.collabsme.auth.dto;

public class AuthResponse {
    private UserDto user;
    private Tokens tokens;

    public AuthResponse(UserDto user, Tokens tokens) {
        this.user = user;
        this.tokens = tokens;
    }

    public UserDto getUser() { return user; }
    public Tokens getTokens() { return tokens; }

    public static class Tokens {
        private String access;
        private String refresh;

        public Tokens(String access, String refresh) {
            this.access = access;
            this.refresh = refresh;
        }

        public String getAccess() { return access; }
        public String getRefresh() { return refresh; }
    }
}
