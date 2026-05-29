package com.collabsme.auth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.collabsme.user.User;
import java.util.List;
import java.util.stream.Collectors;

public class UserDto {
    private Long id;
    private String email;
    private String firstName;
    private String lastName;
    private String fullName;
    private String phoneNumber;
    private Long companyId;
    private String role;
    private boolean isCompanyAdmin;
    private String bio;
    private String preferences;

    public static UserDto fromUser(User user) {
        UserDto dto = new UserDto();
        dto.setId(user.getId());
        dto.setEmail(user.getEmail());
        dto.setFirstName(user.getFirstName());
        dto.setLastName(user.getLastName());
        dto.setFullName((user.getFirstName() + " " + user.getLastName()).trim());
        dto.setPhoneNumber(user.getPhoneNumber());
        dto.setCompanyId(user.getCompany() != null ? user.getCompany().getId() : null);
        dto.setRole(user.getRole() != null ? user.getRole().name() : "MEMBER");
        dto.setCompanyAdmin(user.isCompanyAdmin());
        dto.setBio(user.getBio());
        dto.setPreferences(user.getPreferences());
        return dto;
    }

    public static List<UserDto> fromUsers(List<User> users) {
        return users.stream().map(UserDto::fromUser).collect(Collectors.toList());
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    @JsonProperty("company")
    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    @JsonProperty("is_company_admin")
    public boolean isCompanyAdmin() { return isCompanyAdmin; }
    public void setCompanyAdmin(boolean companyAdmin) { isCompanyAdmin = companyAdmin; }
    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }
    public String getPreferences() { return preferences; }
    public void setPreferences(String preferences) { this.preferences = preferences; }
}
