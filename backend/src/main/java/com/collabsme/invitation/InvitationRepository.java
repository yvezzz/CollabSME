package com.collabsme.invitation;

import com.collabsme.company.Company;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InvitationRepository extends JpaRepository<Invitation, Long> {
    List<Invitation> findByCompanyOrderByCreatedAtDesc(Company company);
    Optional<Invitation> findByToken(UUID token);
    boolean existsByCompanyAndEmail(Company company, String email);
}
