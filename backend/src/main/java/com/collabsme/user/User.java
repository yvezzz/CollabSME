package com.collabsme.user;

import com.collabsme.company.Company;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    private String phoneNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id")
    private Company company;

    @Enumerated(EnumType.STRING)
    private Role role = Role.MEMBER;

    private boolean isCompanyAdmin = false;

    private String avatarUrl;
    private String bio;

    @Column(columnDefinition = "TEXT")
    private String preferences = "{}";

    private LocalDateTime dateJoined;

    @PrePersist
    protected void onCreate() {
        dateJoined = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public Company getCompany() { return company; }
    public void setCompany(Company company) { this.company = company; }
    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }
    public boolean isCompanyAdmin() { return isCompanyAdmin; }
    public void setCompanyAdmin(boolean companyAdmin) { isCompanyAdmin = companyAdmin; }
    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }
    public String getPreferences() { return preferences; }
    public void setPreferences(String preferences) { this.preferences = preferences; }
    public LocalDateTime getDateJoined() { return dateJoined; }
}
