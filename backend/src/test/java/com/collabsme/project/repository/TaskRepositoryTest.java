package com.collabsme.project.repository;

import com.collabsme.company.Company;
import com.collabsme.company.SubscriptionStatus;
import com.collabsme.project.model.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest
@TestMethodOrder(MethodOrderer.MethodName.class)
class TaskRepositoryTest {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private TestEntityManager em;

    private Project project;

    @BeforeEach
    void setUp() {
        Company company = new Company();
        company.setName("TestCo");
        company.setSubscriptionStatus(SubscriptionStatus.FREE);
        em.persistAndFlush(company);

        Project p = new Project();
        p.setCompany(company);
        p.setKey("PRJ");
        p.setTitle("Test Project");
        p.setDescription("A test project");
        p.setStatus(ProjectStatus.ACTIVE);
        p.setPriority(Priority.HIGH);
        project = em.persistAndFlush(p);

        Task t1 = new Task();
        t1.setProject(project);
        t1.setTitle("Task B");
        t1.setStatus(TaskStatus.TODO);
        t1.setOrder(2);
        em.persistAndFlush(t1);

        Task t2 = new Task();
        t2.setProject(project);
        t2.setTitle("Task A");
        t2.setStatus(TaskStatus.IN_PROGRESS);
        t2.setOrder(1);
        em.persistAndFlush(t2);

        Task t3 = new Task();
        t3.setProject(project);
        t3.setTitle("Task C");
        t3.setStatus(TaskStatus.DONE);
        t3.setOrder(3);
        em.persistAndFlush(t3);
    }

    @Test
    void test1_findByProjectReturnsTasks() {
        Page<Task> tasks = taskRepository.findByProject(project, PageRequest.of(0, 10));

        assertNotNull(tasks);
        assertEquals(3, tasks.getTotalElements());
    }

    @Test
    void test2_countByProjectReturnsCorrectCount() {
        long count = taskRepository.countByProject(project);

        assertEquals(3, count);
    }

    @Test
    void test3_findByProjectOrderedReturnsTasksSorted() {
        List<Task> tasks = taskRepository.findByProjectOrdered(project);

        assertNotNull(tasks);
        assertEquals(3, tasks.size());
        assertEquals("Task A", tasks.get(0).getTitle());
        assertEquals("Task B", tasks.get(1).getTitle());
        assertEquals("Task C", tasks.get(2).getTitle());
    }
}
