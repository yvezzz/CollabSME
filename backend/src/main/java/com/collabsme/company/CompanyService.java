package com.collabsme.company;

import com.collabsme.auth.dto.UserDto;
import com.collabsme.exception.ResourceNotFoundException;
import com.collabsme.user.Role;
import com.collabsme.user.User;
import com.collabsme.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CompanyService {

    private final CompanyRepository companyRepository;
    private final UserRepository userRepository;

    public CompanyService(CompanyRepository companyRepository, UserRepository userRepository) {
        this.companyRepository = companyRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public CompanyDto getCompany(User user) {
        Company company = companyRepository.findById(user.getCompany().getId())
                .orElseThrow(() -> new ResourceNotFoundException("Aucune entreprise associée."));
        return CompanyDto.fromCompany(company);
    }

    @Transactional
    public CompanyDto updateCompany(User user, CompanyDto dto) {
        Company company = user.getCompany();
        if (company == null) {
            throw new ResourceNotFoundException("Aucune entreprise associée.");
        }
        if (dto.getName() != null) company.setName(dto.getName());
        if (dto.getSector() != null) company.setSector(dto.getSector());
        if (dto.getSize() != null) company.setSize(dto.getSize());
        if (dto.getWebsite() != null) company.setWebsite(dto.getWebsite());
        if (dto.getBillingEmail() != null) company.setBillingEmail(dto.getBillingEmail());
        if (dto.getAddress() != null) company.setAddress(dto.getAddress());
        if (dto.getCity() != null) company.setCity(dto.getCity());
        if (dto.getPostalCode() != null) company.setPostalCode(dto.getPostalCode());
        if (dto.getCountry() != null) company.setCountry(dto.getCountry());
        if (dto.getLogoUrl() != null) company.setLogoUrl(dto.getLogoUrl());
        company = companyRepository.save(company);
        return CompanyDto.fromCompany(company);
    }

    @Transactional
    public void removeMember(User currentUser, Long userId) {
        if (!currentUser.isCompanyAdmin()) {
            throw new SecurityException("Action non autorisée.");
        }
        Company company = currentUser.getCompany();
        User target = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        if (!company.equals(target.getCompany())) {
            throw new ResourceNotFoundException("Utilisateur introuvable.");
        }
        if (target.getId().equals(currentUser.getId())) {
            throw new IllegalArgumentException("Vous ne pouvez pas vous retirer vous-même.");
        }
        target.setCompany(null);
        target.setRole(Role.MEMBER);
        target.setCompanyAdmin(false);
        userRepository.save(target);
    }

    @Transactional
    public UserDto changeMemberRole(User currentUser, Long userId, String newRole) {
        if (!currentUser.isCompanyAdmin()) {
            throw new SecurityException("Action non autorisée.");
        }
        Company company = currentUser.getCompany();
        User target = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        if (!company.equals(target.getCompany())) {
            throw new ResourceNotFoundException("Utilisateur introuvable.");
        }
        try {
            Role role = Role.valueOf(newRole);
            target.setRole(role);
            target.setCompanyAdmin(role == Role.ADMIN);
            userRepository.save(target);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Rôle invalide.");
        }
        return UserDto.fromUser(target);
    }
}
