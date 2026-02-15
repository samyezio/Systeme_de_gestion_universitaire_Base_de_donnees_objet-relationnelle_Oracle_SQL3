-- =========================================================
-- UNIVERSITY COURSE MANAGEMENT SYSTEM (UCMS) - FIXED SAMPLE DATA
-- =========================================================
-- This script inserts sample data into the UCMS schema
-- Fixed to avoid errors and properly initialize all components
-- =========================================================

-- Clean up any existing data (to avoid conflicts)
BEGIN
    -- Delete in the correct order to avoid constraint violations
    EXECUTE IMMEDIATE 'DELETE FROM grades';
    EXECUTE IMMEDIATE 'DELETE FROM enrollments';
    EXECUTE IMMEDIATE 'DELETE FROM professor_courses';
    EXECUTE IMMEDIATE 'DELETE FROM assignments';
    EXECUTE IMMEDIATE 'DELETE FROM courses';
    EXECUTE IMMEDIATE 'DELETE FROM students';
    EXECUTE IMMEDIATE 'DELETE FROM departments';
    EXECUTE IMMEDIATE 'DELETE FROM professors';
    EXECUTE IMMEDIATE 'DELETE FROM classrooms';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during cleanup: ' || SQLERRM);
END;
/

-- Insert Classrooms
INSERT INTO classrooms VALUES (classroom_t('A101', 30));
INSERT INTO classrooms VALUES (classroom_t('A102', 25));
INSERT INTO classrooms VALUES (classroom_t('B201', 50));
INSERT INTO classrooms VALUES (classroom_t('B202', 45));
INSERT INTO classrooms VALUES (classroom_t('C301', 100));

-- Insert Professors (temporarily without department) with phone numbers
INSERT INTO professors VALUES (
    professor_t(
        prof_seq.NEXTVAL, 
        'Amina Chikhaoui', 
        'amina.chikhaoui@usthb.com', 
        NULL, 
        phone_list_t('0555-123-4567', '0555-765-4321')
    )
);

INSERT INTO professors VALUES (
    professor_t(
        prof_seq.NEXTVAL, 
        'Maria Garcia', 
        'maria.garcia@university.edu', 
        NULL, 
        phone_list_t('0555-234-5678')
    )
);

INSERT INTO professors VALUES (
    professor_t(
        prof_seq.NEXTVAL, 
        'Robert Johnson', 
        'robert.johnson@university.edu', 
        NULL, 
        phone_list_t('0555-345-6789', '0555-987-6543')
    )
);

INSERT INTO professors VALUES (
    professor_t(
        prof_seq.NEXTVAL, 
        'Emily Williams', 
        'emily.williams@university.edu', 
        NULL, 
        phone_list_t('0555-456-7890')
    )
);

INSERT INTO professors VALUES (
    professor_t(
        prof_seq.NEXTVAL, 
        'David Brown', 
        'david.brown@university.edu', 
        NULL, 
        phone_list_t('0555-567-8901')
    )
);

-- Insert Departments with Head Professors
DECLARE
    v_prof_ref1 REF professor_t;
    v_prof_ref2 REF professor_t;
    v_prof_ref3 REF professor_t;
BEGIN
    -- Get references to professors
    SELECT REF(p) INTO v_prof_ref1 FROM professors p WHERE p.name = 'Amina Chikhaoui';
    SELECT REF(p) INTO v_prof_ref2 FROM professors p WHERE p.name = 'Maria Garcia';
    SELECT REF(p) INTO v_prof_ref3 FROM professors p WHERE p.name = 'Robert Johnson';
    
    -- Insert departments
    INSERT INTO departments VALUES (
        department_t(
            dept_seq.NEXTVAL, 
            'Computer Science', 
            v_prof_ref1
        )
    );
    
    INSERT INTO departments VALUES (
        department_t(
            dept_seq.NEXTVAL, 
            'Mathematics', 
            v_prof_ref2
        )
    );
    
    INSERT INTO departments VALUES (
        department_t(
            dept_seq.NEXTVAL, 
            'Physics', 
            v_prof_ref3
        )
    );
END;
/

-- Update Professors with Department references
DECLARE
    v_dept_ref1 REF department_t;
    v_dept_ref2 REF department_t;
    v_dept_ref3 REF department_t;
BEGIN
    -- Get references to departments
    SELECT REF(d) INTO v_dept_ref1 FROM departments d WHERE d.name = 'Computer Science';
    SELECT REF(d) INTO v_dept_ref2 FROM departments d WHERE d.name = 'Mathematics';
    SELECT REF(d) INTO v_dept_ref3 FROM departments d WHERE d.name = 'Physics';
    
    -- Update professors
    UPDATE professors p SET p.department = v_dept_ref1 WHERE p.name = 'Amina Chikhaoui';
    UPDATE professors p SET p.department = v_dept_ref1 WHERE p.name = 'Emily Williams';
    UPDATE professors p SET p.department = v_dept_ref2 WHERE p.name = 'Maria Garcia';
    UPDATE professors p SET p.department = v_dept_ref3 WHERE p.name = 'Robert Johnson';
    UPDATE professors p SET p.department = v_dept_ref3 WHERE p.name = 'David Brown';
END;
/

-- Insert Courses with EMPTY assignment lists first
DECLARE
    v_dept_ref1 REF department_t;
    v_dept_ref2 REF department_t;
    v_dept_ref3 REF department_t;
    v_classroom_ref1 REF classroom_t;
    v_classroom_ref2 REF classroom_t;
    v_classroom_ref3 REF classroom_t;
    v_classroom_ref4 REF classroom_t;
    v_classroom_ref5 REF classroom_t;
BEGIN
    -- Get references to departments
    SELECT REF(d) INTO v_dept_ref1 FROM departments d WHERE d.name = 'Computer Science';
    SELECT REF(d) INTO v_dept_ref2 FROM departments d WHERE d.name = 'Mathematics';
    SELECT REF(d) INTO v_dept_ref3 FROM departments d WHERE d.name = 'Physics';
    
    -- Get references to classrooms
    SELECT REF(c) INTO v_classroom_ref1 FROM classrooms c WHERE c.room_number = 'A101';
    SELECT REF(c) INTO v_classroom_ref2 FROM classrooms c WHERE c.room_number = 'A102';
    SELECT REF(c) INTO v_classroom_ref3 FROM classrooms c WHERE c.room_number = 'B201';
    SELECT REF(c) INTO v_classroom_ref4 FROM classrooms c WHERE c.room_number = 'B202';
    SELECT REF(c) INTO v_classroom_ref5 FROM classrooms c WHERE c.room_number = 'C301';
    
    -- Insert courses with EMPTY assignment lists to avoid trigger issues
    INSERT INTO courses VALUES (
        course_t(
            course_seq.NEXTVAL,
            'Introduction to Programming',
            3,
            'Basic programming concepts using Python',
            v_dept_ref1,
            v_classroom_ref1,
            time_slot_t('Monday', TIMESTAMP '2024-01-01 09:00:00', TIMESTAMP '2024-01-01 10:30:00'),
            assignment_list_t() -- Empty assignment list
        )
    );
    
    INSERT INTO courses VALUES (
        course_t(
            course_seq.NEXTVAL,
            'Database Systems',
            4,
            'Relational database concepts and SQL',
            v_dept_ref1,
            v_classroom_ref3,
            time_slot_t('Tuesday', TIMESTAMP '2024-01-01 13:00:00', TIMESTAMP '2024-01-01 15:00:00'),
            assignment_list_t() -- Empty assignment list
        )
    );
    
    INSERT INTO courses VALUES (
        course_t(
            course_seq.NEXTVAL,
            'Calculus I',
            4,
            'Limits, derivatives, and integrals',
            v_dept_ref2,
            v_classroom_ref2,
            time_slot_t('Wednesday', TIMESTAMP '2024-01-01 11:00:00', TIMESTAMP '2024-01-01 12:30:00'),
            assignment_list_t() -- Empty assignment list
        )
    );
    
    INSERT INTO courses VALUES (
        course_t(
            course_seq.NEXTVAL,
            'Mechanics',
            3,
            'Classical mechanics and Newton laws',
            v_dept_ref3,
            v_classroom_ref4,
            time_slot_t('Thursday', TIMESTAMP '2024-01-01 09:00:00', TIMESTAMP '2024-01-01 11:00:00'),
            assignment_list_t() -- Empty assignment list
        )
    );
    
    INSERT INTO courses VALUES (
        course_t(
            course_seq.NEXTVAL,
            'Data Structures',
            4,
            'Advanced data structures and algorithms',
            v_dept_ref1,
            v_classroom_ref5,
            time_slot_t('Friday', TIMESTAMP '2024-01-01 14:00:00', TIMESTAMP '2024-01-01 16:00:00'),
            assignment_list_t() -- Empty assignment list
        )
    );
END;
/

-- Insert assignments directly into the assignments table
DECLARE
    v_course_id1 NUMBER;
    v_course_id2 NUMBER;
    v_course_id3 NUMBER;
    v_course_id4 NUMBER;
    v_course_id5 NUMBER;
BEGIN
    -- Get course IDs
    SELECT c.course_id INTO v_course_id1 FROM courses c WHERE c.course_name = 'Introduction to Programming';
    SELECT c.course_id INTO v_course_id2 FROM courses c WHERE c.course_name = 'Database Systems';
    SELECT c.course_id INTO v_course_id3 FROM courses c WHERE c.course_name = 'Calculus I';
    SELECT c.course_id INTO v_course_id4 FROM courses c WHERE c.course_name = 'Mechanics';
    SELECT c.course_id INTO v_course_id5 FROM courses c WHERE c.course_name = 'Data Structures';
    
    -- Insert assignments for Introduction to Programming
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'Hello World Program', 
        'Write a simple Hello World program', 
        TO_DATE('2024-04-10', 'YYYY-MM-DD'),
        v_course_id1
    );
    
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'Calculator App', 
        'Build a simple calculator', 
        TO_DATE('2024-04-20', 'YYYY-MM-DD'),
        v_course_id1
    );
    
    -- Insert assignments for Database Systems
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'ER Diagram', 
        'Design an ER diagram for a library system', 
        TO_DATE('2024-04-15', 'YYYY-MM-DD'),
        v_course_id2
    );
    
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'SQL Queries', 
        'Write complex SQL queries', 
        TO_DATE('2024-04-30', 'YYYY-MM-DD'),
        v_course_id2
    );
    
    -- Insert assignments for Calculus I
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'Limits Problems', 
        'Solve problems on limits', 
        TO_DATE('2024-04-12', 'YYYY-MM-DD'),
        v_course_id3
    );
    
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'Derivatives', 
        'Compute derivatives of functions', 
        TO_DATE('2024-04-25', 'YYYY-MM-DD'),
        v_course_id3
    );
    
    -- Insert assignments for Mechanics
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'Forces Lab', 
        'Lab report on forces', 
        TO_DATE('2024-04-18', 'YYYY-MM-DD'),
        v_course_id4
    );
    
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'Motion Problems', 
        'Solve problems on projectile motion', 
        TO_DATE('2024-04-28', 'YYYY-MM-DD'),
        v_course_id4
    );
    
    -- Insert assignments for Data Structures
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'Linked Lists', 
        'Implement a linked list', 
        TO_DATE('2024-04-14', 'YYYY-MM-DD'),
        v_course_id5
    );
    
    INSERT INTO assignments VALUES (
        assign_seq.NEXTVAL, 
        'Binary Trees', 
        'Implement binary tree traversals', 
        TO_DATE('2024-04-27', 'YYYY-MM-DD'),
        v_course_id5
    );
END;
/

-- Insert Students (including some who will have no submissions)
DECLARE
    v_dept_ref1 REF department_t;
    v_dept_ref2 REF department_t;
    v_dept_ref3 REF department_t;
BEGIN
    -- Get references to departments
    SELECT REF(d) INTO v_dept_ref1 FROM departments d WHERE d.name = 'Computer Science';
    SELECT REF(d) INTO v_dept_ref2 FROM departments d WHERE d.name = 'Mathematics';
    SELECT REF(d) INTO v_dept_ref3 FROM departments d WHERE d.name = 'Physics';
    
    -- Insert students (some will submit assignments, some won't)
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Graba Chakib Islam',
            'grabachakkib.islam@university.edu',
            TO_DATE('2000-05-15', 'YYYY-MM-DD'),
            address_t('La perrine', 'Hydra', 'Algiers', '16000'),
            v_dept_ref1
        )
    );
    
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Zemmache Naila',
            'ZemmichNaili@university.edu',
            TO_DATE('2001-07-22', 'YYYY-MM-DD'),
            address_t('456 Oak Ave', 'Townsburg', 'State', '23456'),
            v_dept_ref1
        )
    );
    
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Nour Islam Aoudia',
            'NourIslamAoudia@university.edu',
            TO_DATE('1999-12-10', 'YYYY-MM-DD'),
            address_t('789 Pine Rd', 'Villageton', 'State', '34567'),
            v_dept_ref2
        )
    );
    
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Benamara Abderahmane',
            'abdou@university.edu',
            TO_DATE('2000-02-28', 'YYYY-MM-DD'),
            address_t('101 Elm Blvd', 'Alger', 'State', '45678'),
            v_dept_ref3
        )
    );
    
    -- Student who will have no submissions (enrolled but no grades)
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Bouikni Lydia Hana',
            'Hana@university.edu',
            TO_DATE('2001-11-05', 'YYYY-MM-DD'),
            address_t('202 Cedar Ln', 'Alger', 'State', '56789'),
            v_dept_ref1
        )
    );
    
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Fiona Taylor',
            'fiona.taylor@university.edu',
            TO_DATE('1999-09-18', 'YYYY-MM-DD'),
            address_t('303 Birch Dr', 'Countyshire', 'State', '67890'),
            v_dept_ref2
        )
    );
    
    -- Another student who will have no submissions (enrolled but no grades)
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'George Wilson',
            'george.wilson@university.edu',
            TO_DATE('2000-08-30', 'YYYY-MM-DD'),
            address_t('404 Maple Ct', 'Districtopolis', 'State', '78901'),
            v_dept_ref3
        )
    );
    
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Hannah Garcia',
            'hannah.garcia@university.edu',
            TO_DATE('2001-04-12', 'YYYY-MM-DD'),
            address_t('505 Walnut Pl', 'Boroughville', 'State', '89012'),
            v_dept_ref1
        )
    );
    
    -- Additional students with no submissions for more testing
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Ahmed Benali',
            'ahmed.benali@university.edu',
            TO_DATE('2001-03-14', 'YYYY-MM-DD'),
            address_t('123 University St', 'Algiers', 'State', '90123'),
            v_dept_ref2
        )
    );
    
    INSERT INTO students VALUES (
        student_t(
            student_seq.NEXTVAL,
            'Sara Khelif',
            'sara.khelif@university.edu',
            TO_DATE('2000-09-08', 'YYYY-MM-DD'),
            address_t('789 Student Ave', 'Oran', 'State', '01234'),
            v_dept_ref3
        )
    );
END;
/

-- Associate Professors with Courses
DECLARE
    v_prof_id1 NUMBER;
    v_prof_id2 NUMBER;
    v_prof_id3 NUMBER;
    v_prof_id4 NUMBER;
    v_prof_id5 NUMBER;
    v_course_id1 NUMBER;
    v_course_id2 NUMBER;
    v_course_id3 NUMBER;
    v_course_id4 NUMBER;
    v_course_id5 NUMBER;
    v_prof_ref1 REF professor_t;
    v_prof_ref2 REF professor_t;
    v_prof_ref3 REF professor_t;
    v_prof_ref4 REF professor_t;
    v_prof_ref5 REF professor_t;
    v_course_ref1 REF course_t;
    v_course_ref2 REF course_t;
    v_course_ref3 REF course_t;
    v_course_ref4 REF course_t;
    v_course_ref5 REF course_t;
BEGIN
    -- Get professor IDs and references
    SELECT p.prof_id, REF(p) INTO v_prof_id1, v_prof_ref1 FROM professors p WHERE p.name = 'Amina Chikhaoui';
    SELECT p.prof_id, REF(p) INTO v_prof_id2, v_prof_ref2 FROM professors p WHERE p.name = 'Maria Garcia';
    SELECT p.prof_id, REF(p) INTO v_prof_id3, v_prof_ref3 FROM professors p WHERE p.name = 'Robert Johnson';
    SELECT p.prof_id, REF(p) INTO v_prof_id4, v_prof_ref4 FROM professors p WHERE p.name = 'Emily Williams';
    SELECT p.prof_id, REF(p) INTO v_prof_id5, v_prof_ref5 FROM professors p WHERE p.name = 'David Brown';
    
    -- Get course IDs and references
    SELECT c.course_id, REF(c) INTO v_course_id1, v_course_ref1 FROM courses c WHERE c.course_name = 'Introduction to Programming';
    SELECT c.course_id, REF(c) INTO v_course_id2, v_course_ref2 FROM courses c WHERE c.course_name = 'Database Systems';
    SELECT c.course_id, REF(c) INTO v_course_id3, v_course_ref3 FROM courses c WHERE c.course_name = 'Calculus I';
    SELECT c.course_id, REF(c) INTO v_course_id4, v_course_ref4 FROM courses c WHERE c.course_name = 'Mechanics';
    SELECT c.course_id, REF(c) INTO v_course_id5, v_course_ref5 FROM courses c WHERE c.course_name = 'Data Structures';
    
    -- Associate professors with courses
    INSERT INTO professor_courses VALUES (prof_course_seq.NEXTVAL, v_prof_id1, v_course_id2, v_prof_ref1, v_course_ref2);
    INSERT INTO professor_courses VALUES (prof_course_seq.NEXTVAL, v_prof_id4, v_course_id1, v_prof_ref4, v_course_ref1);
    INSERT INTO professor_courses VALUES (prof_course_seq.NEXTVAL, v_prof_id2, v_course_id3, v_prof_ref2, v_course_ref3);
    INSERT INTO professor_courses VALUES (prof_course_seq.NEXTVAL, v_prof_id3, v_course_id4, v_prof_ref3, v_course_ref4);
    INSERT INTO professor_courses VALUES (prof_course_seq.NEXTVAL, v_prof_id5, v_course_id5, v_prof_ref5, v_course_ref5);
    
    -- Additional assignments to demonstrate many-to-many
    INSERT INTO professor_courses VALUES (prof_course_seq.NEXTVAL, v_prof_id1, v_course_id5, v_prof_ref1, v_course_ref5);
    INSERT INTO professor_courses VALUES (prof_course_seq.NEXTVAL, v_prof_id4, v_course_id2, v_prof_ref4, v_course_ref2);
END;
/

-- Enroll Students in Courses
DECLARE
    v_student_id1 NUMBER;
    v_student_id2 NUMBER;
    v_student_id3 NUMBER;
    v_student_id4 NUMBER;
    v_student_id5 NUMBER;
    v_student_id6 NUMBER;
    v_student_id7 NUMBER;
    v_student_id8 NUMBER;
    v_student_id9 NUMBER;
    v_student_id10 NUMBER;
    
    v_course_id1 NUMBER;
    v_course_id2 NUMBER;
    v_course_id3 NUMBER;
    v_course_id4 NUMBER;
    v_course_id5 NUMBER;
    
    v_student_ref1 REF student_t;
    v_student_ref2 REF student_t;
    v_student_ref3 REF student_t;
    v_student_ref4 REF student_t;
    v_student_ref5 REF student_t;
    v_student_ref6 REF student_t;
    v_student_ref7 REF student_t;
    v_student_ref8 REF student_t;
    v_student_ref9 REF student_t;
    v_student_ref10 REF student_t;
    
    v_course_ref1 REF course_t;
    v_course_ref2 REF course_t;
    v_course_ref3 REF course_t;
    v_course_ref4 REF course_t;
    v_course_ref5 REF course_t;
BEGIN
    -- Get student IDs and references
    SELECT s.student_id, REF(s) INTO v_student_id1, v_student_ref1 FROM students s WHERE s.name = 'Graba Chakib Islam';
    SELECT s.student_id, REF(s) INTO v_student_id2, v_student_ref2 FROM students s WHERE s.name = 'Zemmache Naila';
    SELECT s.student_id, REF(s) INTO v_student_id3, v_student_ref3 FROM students s WHERE s.name = 'Nour Islam Aoudia';
    SELECT s.student_id, REF(s) INTO v_student_id4, v_student_ref4 FROM students s WHERE s.name = 'Benamara Abderahmane';
    SELECT s.student_id, REF(s) INTO v_student_id5, v_student_ref5 FROM students s WHERE s.name = 'Bouikni Lydia Hana';
    SELECT s.student_id, REF(s) INTO v_student_id6, v_student_ref6 FROM students s WHERE s.name = 'Fiona Taylor';
    SELECT s.student_id, REF(s) INTO v_student_id7, v_student_ref7 FROM students s WHERE s.name = 'George Wilson';
    SELECT s.student_id, REF(s) INTO v_student_id8, v_student_ref8 FROM students s WHERE s.name = 'Hannah Garcia';
    SELECT s.student_id, REF(s) INTO v_student_id9, v_student_ref9 FROM students s WHERE s.name = 'Ahmed Benali';
    SELECT s.student_id, REF(s) INTO v_student_id10, v_student_ref10 FROM students s WHERE s.name = 'Sara Khelif';
    
    -- Get course IDs and references
    SELECT c.course_id, REF(c) INTO v_course_id1, v_course_ref1 FROM courses c WHERE c.course_name = 'Introduction to Programming';
    SELECT c.course_id, REF(c) INTO v_course_id2, v_course_ref2 FROM courses c WHERE c.course_name = 'Database Systems';
    SELECT c.course_id, REF(c) INTO v_course_id3, v_course_ref3 FROM courses c WHERE c.course_name = 'Calculus I';
    SELECT c.course_id, REF(c) INTO v_course_id4, v_course_ref4 FROM courses c WHERE c.course_name = 'Mechanics';
    SELECT c.course_id, REF(c) INTO v_course_id5, v_course_ref5 FROM courses c WHERE c.course_name = 'Data Structures';
    
    -- Students who will submit assignments
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id1, v_course_id1, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 
                                  v_student_ref1, v_course_ref1);
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id1, v_course_id2, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 
                                  v_student_ref1, v_course_ref2);
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id1, v_course_id5, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 
                                  v_student_ref1, v_course_ref5);
    
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id2, v_course_id1, TO_DATE('2024-02-02', 'YYYY-MM-DD'), 
                                  v_student_ref2, v_course_ref1);
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id2, v_course_id2, TO_DATE('2024-02-02', 'YYYY-MM-DD'), 
                                  v_student_ref2, v_course_ref2);
    
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id3, v_course_id3, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 
                                  v_student_ref3, v_course_ref3);
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id3, v_course_id1, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 
                                  v_student_ref3, v_course_ref1);
    
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id4, v_course_id4, TO_DATE('2024-02-03', 'YYYY-MM-DD'), 
                                  v_student_ref4, v_course_ref4);
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id4, v_course_id3, TO_DATE('2024-02-03', 'YYYY-MM-DD'), 
                                  v_student_ref4, v_course_ref3);
    
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id8, v_course_id1, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 
                                  v_student_ref8, v_course_ref1);
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id8, v_course_id2, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 
                                  v_student_ref8, v_course_ref2);
    
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id6, v_course_id3, TO_DATE('2024-02-02', 'YYYY-MM-DD'), 
                                  v_student_ref6, v_course_ref3);
    
    -- Students enrolled but will have NO submissions (to test the view)
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id5, v_course_id1, TO_DATE('2024-02-03', 'YYYY-MM-DD'), 
                                  v_student_ref5, v_course_ref1);
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id5, v_course_id5, TO_DATE('2024-02-03', 'YYYY-MM-DD'), 
                                  v_student_ref5, v_course_ref5);
    
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id7, v_course_id4, TO_DATE('2024-02-02', 'YYYY-MM-DD'), 
                                  v_student_ref7, v_course_ref4);
    
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id9, v_course_id3, TO_DATE('2024-02-04', 'YYYY-MM-DD'), 
                                  v_student_ref9, v_course_ref3);
    
    INSERT INTO enrollments VALUES (enroll_seq.NEXTVAL, v_student_id10, v_course_id4, TO_DATE('2024-02-05', 'YYYY-MM-DD'), 
                                  v_student_ref10, v_course_ref4);
END;
/

-- Insert Grades ONLY for some students (others will have NO submissions)
DECLARE
    -- Student IDs and references (only those who will have grades)
    v_student_id1 NUMBER;
    v_student_id2 NUMBER;
    v_student_id3 NUMBER;
    v_student_id4 NUMBER;
    v_student_id6 NUMBER;
    v_student_id8 NUMBER;
    
    v_student_ref1 REF student_t;
    v_student_ref2 REF student_t;
    v_student_ref3 REF student_t;
    v_student_ref4 REF student_t;
    v_student_ref6 REF student_t;
    v_student_ref8 REF student_t;
    
    -- Course IDs and references
    v_course_id1 NUMBER;
    v_course_id2 NUMBER;
    v_course_id3 NUMBER;
    v_course_id4 NUMBER;
    v_course_id5 NUMBER;
    
    v_course_ref1 REF course_t;
    v_course_ref2 REF course_t;
    v_course_ref3 REF course_t;
    v_course_ref4 REF course_t;
    v_course_ref5 REF course_t;
    
    -- Professor IDs and references
    v_prof_id1 NUMBER;
    v_prof_id2 NUMBER;
    v_prof_id3 NUMBER;
    v_prof_id4 NUMBER;
    v_prof_id5 NUMBER;
    
    v_prof_ref1 REF professor_t;
    v_prof_ref2 REF professor_t;
    v_prof_ref3 REF professor_t;
    v_prof_ref4 REF professor_t;
    v_prof_ref5 REF professor_t;
    
    -- Assignment IDs
    v_hello_world_id NUMBER;
    v_calculator_id NUMBER;
    v_er_diagram_id NUMBER;
    v_sql_queries_id NUMBER;
    v_limits_id NUMBER;
    v_derivatives_id NUMBER;
    v_forces_id NUMBER;
    v_motion_id NUMBER;
    v_linked_lists_id NUMBER;
    v_binary_trees_id NUMBER;
BEGIN
    -- Get student IDs and references (only those who will have grades)
    SELECT s.student_id, REF(s) INTO v_student_id1, v_student_ref1 FROM students s WHERE s.name = 'Graba Chakib Islam';
    SELECT s.student_id, REF(s) INTO v_student_id2, v_student_ref2 FROM students s WHERE s.name = 'Zemmache Naila';
    SELECT s.student_id, REF(s) INTO v_student_id3, v_student_ref3 FROM students s WHERE s.name = 'Nour Islam Aoudia';
    SELECT s.student_id, REF(s) INTO v_student_id4, v_student_ref4 FROM students s WHERE s.name = 'Benamara Abderahmane';
    SELECT s.student_id, REF(s) INTO v_student_id6, v_student_ref6 FROM students s WHERE s.name = 'Fiona Taylor';
    SELECT s.student_id, REF(s) INTO v_student_id8, v_student_ref8 FROM students s WHERE s.name = 'Hannah Garcia';
    
    -- Get course IDs and references
    SELECT c.course_id, REF(c) INTO v_course_id1, v_course_ref1 FROM courses c WHERE c.course_name = 'Introduction to Programming';
    SELECT c.course_id, REF(c) INTO v_course_id2, v_course_ref2 FROM courses c WHERE c.course_name = 'Database Systems';
    SELECT c.course_id, REF(c) INTO v_course_id3, v_course_ref3 FROM courses c WHERE c.course_name = 'Calculus I';
    SELECT c.course_id, REF(c) INTO v_course_id4, v_course_ref4 FROM courses c WHERE c.course_name = 'Mechanics';
    SELECT c.course_id, REF(c) INTO v_course_id5, v_course_ref5 FROM courses c WHERE c.course_name = 'Data Structures';
    
    -- Get professor IDs and references
    SELECT p.prof_id, REF(p) INTO v_prof_id1, v_prof_ref1 FROM professors p WHERE p.name = 'Amina Chikhaoui';
    SELECT p.prof_id, REF(p) INTO v_prof_id2, v_prof_ref2 FROM professors p WHERE p.name = 'Maria Garcia';
    SELECT p.prof_id, REF(p) INTO v_prof_id3, v_prof_ref3 FROM professors p WHERE p.name = 'Robert Johnson';
    SELECT p.prof_id, REF(p) INTO v_prof_id4, v_prof_ref4 FROM professors p WHERE p.name = 'Emily Williams';
    SELECT p.prof_id, REF(p) INTO v_prof_id5, v_prof_ref5 FROM professors p WHERE p.name = 'David Brown';
    
    -- Get assignment IDs
    SELECT assignment_id INTO v_hello_world_id FROM assignments WHERE title = 'Hello World Program';
    SELECT assignment_id INTO v_calculator_id FROM assignments WHERE title = 'Calculator App';
    SELECT assignment_id INTO v_er_diagram_id FROM assignments WHERE title = 'ER Diagram';
    SELECT assignment_id INTO v_sql_queries_id FROM assignments WHERE title = 'SQL Queries';
    SELECT assignment_id INTO v_limits_id FROM assignments WHERE title = 'Limits Problems';
    SELECT assignment_id INTO v_derivatives_id FROM assignments WHERE title = 'Derivatives';
    SELECT assignment_id INTO v_forces_id FROM assignments WHERE title = 'Forces Lab';
    SELECT assignment_id INTO v_motion_id FROM assignments WHERE title = 'Motion Problems';
    SELECT assignment_id INTO v_linked_lists_id FROM assignments WHERE title = 'Linked Lists';
    SELECT assignment_id INTO v_binary_trees_id FROM assignments WHERE title = 'Binary Trees';
    
    -- Insert grades for SOME students only (using 0-20 scale)
    
    -- Graba Chakib Islam's grades
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id1, v_course_id1, v_hello_world_id, 18, TO_DATE('2024-04-15', 'YYYY-MM-DD'), 
        v_prof_id4, v_student_ref1, v_course_ref1, v_prof_ref4
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id1, v_course_id1, v_calculator_id, 16, TO_DATE('2024-04-25', 'YYYY-MM-DD'), 
        v_prof_id4, v_student_ref1, v_course_ref1, v_prof_ref4
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id1, v_course_id2, v_er_diagram_id, 17, TO_DATE('2024-04-18', 'YYYY-MM-DD'), 
        v_prof_id1, v_student_ref1, v_course_ref2, v_prof_ref1
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id1, v_course_id5, v_linked_lists_id, 19, TO_DATE('2024-04-20', 'YYYY-MM-DD'), 
        v_prof_id5, v_student_ref1, v_course_ref5, v_prof_ref5
    );
    
    -- Zemmache Naila's grades
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id2, v_course_id1, v_hello_world_id, 15, TO_DATE('2024-04-15', 'YYYY-MM-DD'), 
        v_prof_id4, v_student_ref2, v_course_ref1, v_prof_ref4
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id2, v_course_id1, v_calculator_id, 14, TO_DATE('2024-04-25', 'YYYY-MM-DD'), 
        v_prof_id4, v_student_ref2, v_course_ref1, v_prof_ref4
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id2, v_course_id2, v_er_diagram_id, 13, TO_DATE('2024-04-18', 'YYYY-MM-DD'), 
        v_prof_id1, v_student_ref2, v_course_ref2, v_prof_ref1
    );
    
    -- Nour Islam Aoudia's grades
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id3, v_course_id3, v_limits_id, 16, TO_DATE('2024-04-16', 'YYYY-MM-DD'), 
        v_prof_id2, v_student_ref3, v_course_ref3, v_prof_ref2
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id3, v_course_id3, v_derivatives_id, 17, TO_DATE('2024-04-30', 'YYYY-MM-DD'), 
        v_prof_id2, v_student_ref3, v_course_ref3, v_prof_ref2
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id3, v_course_id1, v_hello_world_id, 14, TO_DATE('2024-04-15', 'YYYY-MM-DD'), 
        v_prof_id4, v_student_ref3, v_course_ref1, v_prof_ref4
    );
    
    -- Benamara Abderahmane's grades
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id4, v_course_id4, v_forces_id, 13, TO_DATE('2024-04-22', 'YYYY-MM-DD'), 
        v_prof_id3, v_student_ref4, v_course_ref4, v_prof_ref3
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id4, v_course_id3, v_limits_id, 18, TO_DATE('2024-04-16', 'YYYY-MM-DD'), 
        v_prof_id2, v_student_ref4, v_course_ref3, v_prof_ref2
    );
    
    -- Fiona Taylor's grades
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id6, v_course_id3, v_limits_id, 15, TO_DATE('2024-04-16', 'YYYY-MM-DD'), 
        v_prof_id2, v_student_ref6, v_course_ref3, v_prof_ref2
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id6, v_course_id3, v_derivatives_id, 12, TO_DATE('2024-04-30', 'YYYY-MM-DD'), 
        v_prof_id2, v_student_ref6, v_course_ref3, v_prof_ref2
    );
    
    -- Hannah Garcia's grades
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id8, v_course_id1, v_hello_world_id, 20, TO_DATE('2024-04-15', 'YYYY-MM-DD'), 
        v_prof_id4, v_student_ref8, v_course_ref1, v_prof_ref4
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id8, v_course_id1, v_calculator_id, 18, TO_DATE('2024-04-25', 'YYYY-MM-DD'), 
        v_prof_id4, v_student_ref8, v_course_ref1, v_prof_ref4
    );
    
    INSERT INTO grades VALUES (
        grade_seq.NEXTVAL, v_student_id8, v_course_id2, v_er_diagram_id, 19, TO_DATE('2024-04-18', 'YYYY-MM-DD'), 
        v_prof_id1, v_student_ref8, v_course_ref2, v_prof_ref1
    );
    
    -- NOTE: Students with names 'Bouikni Lydia Hana', 'George Wilson', 'Ahmed Benali', 'Sara Khelif' 
    -- are enrolled in courses but have NO grades - they will appear in vw_students_without_submissions
END;
/

-- Verify data was inserted correctly
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== UCMS Fixed Sample Data Verification =====');
    
    -- Count departments
    DECLARE
        dept_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO dept_count FROM departments;
        DBMS_OUTPUT.PUT_LINE('- ' || dept_count || ' departments');
    END;
    
    -- Count professors
    DECLARE
        prof_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO prof_count FROM professors;
        DBMS_OUTPUT.PUT_LINE('- ' || prof_count || ' professors');
    END;
    
    -- Count students
    DECLARE
        student_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO student_count FROM students;
        DBMS_OUTPUT.PUT_LINE('- ' || student_count || ' students');
    END;
    
    -- Count courses
    DECLARE
        course_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO course_count FROM courses;
        DBMS_OUTPUT.PUT_LINE('- ' || course_count || ' courses');
    END;
    
    -- Count assignments
    DECLARE
        assignment_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO assignment_count FROM assignments;
        DBMS_OUTPUT.PUT_LINE('- ' || assignment_count || ' assignments');
    END;
    
    -- Count professor-course assignments
    DECLARE
        prof_course_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO prof_course_count FROM professor_courses;
        DBMS_OUTPUT.PUT_LINE('- ' || prof_course_count || ' professor-course assignments');
    END;
    
    -- Count enrollments
    DECLARE
        enrollment_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO enrollment_count FROM enrollments;
        DBMS_OUTPUT.PUT_LINE('- ' || enrollment_count || ' enrollments');
    END;
    
    -- Count grades
    DECLARE
        grade_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO grade_count FROM grades;
        DBMS_OUTPUT.PUT_LINE('- ' || grade_count || ' grades');
    END;
    
    -- Count students with no submissions
    DECLARE
        no_sub_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO no_sub_count FROM vw_students_without_submissions;
        DBMS_OUTPUT.PUT_LINE('- ' || no_sub_count || ' students with no submissions');
    END;
    
    DBMS_OUTPUT.PUT_LINE('Fixed sample data loaded successfully');
    DBMS_OUTPUT.PUT_LINE('Students with no submissions: Bouikni Lydia Hana, George Wilson, Ahmed Benali, Sara Khelif');
END;
/

-- Final commit to save all changes
COMMIT;