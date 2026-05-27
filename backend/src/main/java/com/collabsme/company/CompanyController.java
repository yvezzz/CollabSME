package com.collabsme.company;

import com.collabsme.auth.dto.UserDto;
import com.collabsme.user.User;
import com.collabsme.user.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/companies")
public class CompanyController {

    private final CompanyService companyService;
    private final UserRepository userRepository;

    public CompanyController(CompanyService companyService, UserRepository userRepository) {
        this.companyService = companyService;
        this.userRepository = userRepository;
    }

    @GetMapping("/detail/")
    public ResponseEntity<CompanyDto> getDetail(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(companyService.getCompany(user));
    }

    @PatchMapping("/detail/")
    public ResponseEntity<CompanyDto> updateDetail(@AuthenticationPrincipal User user,
                                                    @RequestBody CompanyDto dto) {
        return ResponseEntity.ok(companyService.updateCompany(user, dto));
    }

    @GetMapping("/members/")
    public ResponseEntity<?> getMembers(@AuthenticationPrincipal User user) {
        if (user.getCompany() == null) {
            return ResponseEntity.ok(java.util.Collections.emptyList());
        }
        return ResponseEntity.ok(UserDto.fromUsers(
                userRepository.findByCompanyOrderByEmail(user.getCompany())));
    }

    @DeleteMapping("/members/{userId}/remove/")
    public ResponseEntity<Map<String, String>> removeMember(@AuthenticationPrincipal User user,
                                                             @PathVariable Long userId) {
        companyService.removeMember(user, userId);
        return ResponseEntity.ok(Map.of("message", "Membre retiré avec succès."));
    }

    @PatchMapping("/members/{userId}/role/")
    public ResponseEntity<UserDto> changeRole(@AuthenticationPrincipal User user,
                                               @PathVariable Long userId,
                                               @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(companyService.changeMemberRole(user, userId, body.get("role")));
    }
}
