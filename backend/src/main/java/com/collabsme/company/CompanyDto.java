package com.collabsme.company;

public class CompanyDto {
    private Long id;
    private String name;
    private String sector;
    private String size;
    private String website;
    private String billingEmail;
    private String address;
    private String city;
    private String postalCode;
    private String country;
    private String logoUrl;
    private String subscriptionStatus;

    public static CompanyDto fromCompany(Company c) {
        CompanyDto dto = new CompanyDto();
        dto.setId(c.getId());
        dto.setName(c.getName());
        dto.setSector(c.getSector());
        dto.setSize(c.getSize());
        dto.setWebsite(c.getWebsite());
        dto.setBillingEmail(c.getBillingEmail());
        dto.setAddress(c.getAddress());
        dto.setCity(c.getCity());
        dto.setPostalCode(c.getPostalCode());
        dto.setCountry(c.getCountry());
        dto.setLogoUrl(c.getLogoUrl());
        dto.setSubscriptionStatus(c.getSubscriptionStatus() != null ? c.getSubscriptionStatus().name() : "FREE");
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getSector() { return sector; }
    public void setSector(String sector) { this.sector = sector; }
    public String getSize() { return size; }
    public void setSize(String size) { this.size = size; }
    public String getWebsite() { return website; }
    public void setWebsite(String website) { this.website = website; }
    public String getBillingEmail() { return billingEmail; }
    public void setBillingEmail(String billingEmail) { this.billingEmail = billingEmail; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }
    public String getPostalCode() { return postalCode; }
    public void setPostalCode(String postalCode) { this.postalCode = postalCode; }
    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }
    public String getLogoUrl() { return logoUrl; }
    public void setLogoUrl(String logoUrl) { this.logoUrl = logoUrl; }
    public String getSubscriptionStatus() { return subscriptionStatus; }
    public void setSubscriptionStatus(String subscriptionStatus) { this.subscriptionStatus = subscriptionStatus; }
}
