-- =========================================================
-- UNIVERSITY COURSE MANAGEMENT SYSTEM (UCMS) - FIXED VERSION
-- =========================================================
-- IMPORTANT: This script must NOT be executed as SYS user
-- Create a regular user account first and run the script as that user
-- =========================================================

-- 1. Create a new user (run as SYSTEM or SYS)
-- Uncomment and run these lines if you need to create a user
/*
CREATE USER ucms_chakib IDENTIFIED BY ucms_pass;
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE TRIGGER, UNLIMITED TABLESPACE TO ucms_chakib;
CONNECT ucms_chakib/ucms_pass
*/

-- 2. Clean up existing objects
BEGIN
    -- Clean up views first
    FOR cur_rec IN (SELECT object_name FROM user_objects WHERE object_type = 'VIEW') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP VIEW ' || cur_rec.object_name;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up tables 
    FOR cur_rec IN (SELECT table_name FROM user_tables) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE ' || cur_rec.table_name || ' CASCADE CONSTRAINTS PURGE';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up sequences
    FOR cur_rec IN (SELECT sequence_name FROM user_sequences) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE ' || cur_rec.sequence_name;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up triggers
    FOR cur_rec IN (SELECT trigger_name FROM user_triggers) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TRIGGER ' || cur_rec.trigger_name;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    
    -- Clean up types
    FOR cur_rec IN (SELECT type_name FROM user_types) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TYPE ' || cur_rec.type_name || ' FORCE';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- 3. Create basic types
CREATE TYPE address_t AS OBJECT (
    street VARCHAR2(100),
    city VARCHAR2(50),
    state VARCHAR2(50),
    zip_code VARCHAR2(20)
);
/

CREATE TYPE phone_list_t AS TABLE OF VARCHAR2(20);
/

CREATE TYPE time_slot_t AS OBJECT (
    day_of_week VARCHAR2(10),
    start_time TIMESTAMP,
    end_time TIMESTAMP
);
/

CREATE TYPE assignment_t AS OBJECT (
    assignment_id NUMBER,
    title VARCHAR2(100),
    description VARCHAR2(4000),
    due_date DATE
);
/

CREATE TYPE assignment_list_t AS TABLE OF assignment_t;
/

-- 4. Create forward declarations
CREATE TYPE professor_t;
/
CREATE TYPE department_t;
/
CREATE TYPE course_t;
/
CREATE TYPE student_t;
/

-- 5. Create object types with implementations
CREATE TYPE department_t AS OBJECT (
    dept_id NUMBER,
    name VARCHAR2(100),
    head_prof REF professor_t,
    
    MEMBER FUNCTION get_info RETURN VARCHAR2
);
/

CREATE TYPE BODY department_t AS
    MEMBER FUNCTION get_info RETURN VARCHAR2 IS
    BEGIN
        RETURN 'Department: ' || name || ' (ID: ' || dept_id || ')';
    END;
END;
/

CREATE TYPE professor_t AS OBJECT (
    prof_id NUMBER,
    name VARCHAR2(100),
    email VARCHAR2(100),
    department REF department_t,
    phone_numbers phone_list_t,
    
    MEMBER FUNCTION get_info RETURN VARCHAR2
);
/

CREATE TYPE BODY professor_t AS
    MEMBER FUNCTION get_info RETURN VARCHAR2 IS
    BEGIN
        RETURN 'Professor: ' || name || ' (ID: ' || prof_id || ')';
    END;
END;
/

CREATE TYPE classroom_t AS OBJECT (
    room_number VARCHAR2(20),
    capacity NUMBER,
    
    MEMBER FUNCTION is_capacity_sufficient(required_capacity NUMBER) RETURN BOOLEAN
);
/

CREATE TYPE BODY classroom_t AS
    MEMBER FUNCTION is_capacity_sufficient(required_capacity NUMBER) RETURN BOOLEAN IS
    BEGIN
        RETURN capacity >= required_capacity;
    END;
END;
/

CREATE TYPE course_t AS OBJECT (
    course_id NUMBER,
    course_name VARCHAR2(100),
    coefficient NUMBER,
    syllabus VARCHAR2(4000),
    department REF department_t,
    classroom REF classroom_t,
    time_slot time_slot_t,
    assignments assignment_list_t,
    
    MEMBER FUNCTION get_details RETURN VARCHAR2
);
/

CREATE TYPE BODY course_t AS
    MEMBER FUNCTION get_details RETURN VARCHAR2 IS
    BEGIN
        RETURN 'Course: ' || course_name || ' (ID: ' || course_id || 
               ', Coefficient: ' || coefficient || ')';
    END;
END;
/

CREATE TYPE student_t AS OBJECT (
    student_id NUMBER,
    name VARCHAR2(100),
    email VARCHAR2(100),
    date_of_birth DATE,
    address address_t,
    department REF department_t,
    
    MEMBER FUNCTION get_info RETURN VARCHAR2
);
/

CREATE TYPE BODY student_t AS
    MEMBER FUNCTION get_info RETURN VARCHAR2 IS
    BEGIN
        RETURN 'Student: ' || name || ' (ID: ' || student_id || ')';
    END;
END;
/

-- 6. Create sequences
CREATE SEQUENCE dept_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE student_seq START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE prof_seq START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE course_seq START WITH 200 INCREMENT BY 1;
CREATE SEQUENCE enroll_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE assign_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE grade_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE prof_course_seq START WITH 1 INCREMENT BY 1;

-- 7. Create base tables
CREATE TABLE departments OF department_t (
    dept_id PRIMARY KEY,
    name NOT NULL UNIQUE
);

CREATE TABLE classrooms OF classroom_t (
    room_number PRIMARY KEY,
    capacity NOT NULL CHECK (capacity > 0)
);

CREATE TABLE professors OF professor_t (
    prof_id PRIMARY KEY,
    name NOT NULL,
    email NOT NULL UNIQUE
)
NESTED TABLE phone_numbers STORE AS professor_phones;

CREATE TABLE courses OF course_t (
    course_id PRIMARY KEY,
    course_name NOT NULL,
    coefficient NOT NULL CHECK (coefficient > 0)
)
NESTED TABLE assignments STORE AS course_assignments;

CREATE TABLE students OF student_t (
    student_id PRIMARY KEY,
    name NOT NULL,
    email NOT NULL UNIQUE,
    date_of_birth NOT NULL
);

-- 8. Add scopes to REF columns
ALTER TABLE professors ADD SCOPE FOR (department) IS departments;
ALTER TABLE courses ADD SCOPE FOR (department) IS departments;
ALTER TABLE courses ADD SCOPE FOR (classroom) IS classrooms;
ALTER TABLE students ADD SCOPE FOR (department) IS departments;
ALTER TABLE departments ADD SCOPE FOR (head_prof) IS professors;

-- 9. Create relationship tables using OIDs (object IDs) instead of REF columns for constraints
-- Professor-Course relationship (many professors teach many courses)
CREATE TABLE professor_courses (
    id NUMBER PRIMARY KEY,
    professor_id NUMBER NOT NULL,
    course_id NUMBER NOT NULL,
    professor_ref REF professor_t SCOPE IS professors,
    course_ref REF course_t SCOPE IS courses,
    CONSTRAINT uk_prof_courses UNIQUE(professor_id, course_id),
    CONSTRAINT fk_prof_courses_prof FOREIGN KEY(professor_id) REFERENCES professors(prof_id),
    CONSTRAINT fk_prof_courses_course FOREIGN KEY(course_id) REFERENCES courses(course_id)
);

-- Enrollment relationship (many-to-many between students and courses)
CREATE TABLE enrollments (
    id NUMBER PRIMARY KEY,
    student_id NUMBER NOT NULL,
    course_id NUMBER NOT NULL,
    enrollment_date DATE DEFAULT SYSDATE,
    student_ref REF student_t SCOPE IS students,
    course_ref REF course_t SCOPE IS courses,
    CONSTRAINT uk_enrollments UNIQUE(student_id, course_id),
    CONSTRAINT fk_enrollments_student FOREIGN KEY(student_id) REFERENCES students(student_id),
    CONSTRAINT fk_enrollments_course FOREIGN KEY(course_id) REFERENCES courses(course_id)
);

-- Create assignment table to manage assignments outside the nested table
CREATE TABLE assignments (
    assignment_id NUMBER PRIMARY KEY,
    title VARCHAR2(100) NOT NULL,
    description VARCHAR2(4000),
    due_date DATE NOT NULL,
    course_id NUMBER NOT NULL,
    CONSTRAINT fk_assignments_course FOREIGN KEY(course_id) REFERENCES courses(course_id)
);

-- Grades relationship - Using Algerian grading scale (0-20)
CREATE TABLE grades (
    id NUMBER PRIMARY KEY,
    student_id NUMBER NOT NULL,
    course_id NUMBER NOT NULL,
    assignment_id NUMBER NOT NULL,
    grade_value NUMBER NOT NULL CHECK (grade_value BETWEEN 0 AND 20),
    graded_date DATE NOT NULL,
    professor_id NUMBER NOT NULL,
    student_ref REF student_t SCOPE IS students,
    course_ref REF course_t SCOPE IS courses,
    professor_ref REF professor_t SCOPE IS professors,
    CONSTRAINT uk_grades UNIQUE(student_id, course_id, assignment_id),
    CONSTRAINT fk_grades_student FOREIGN KEY(student_id) REFERENCES students(student_id),
    CONSTRAINT fk_grades_course FOREIGN KEY(course_id) REFERENCES courses(course_id),
    CONSTRAINT fk_grades_professor FOREIGN KEY(professor_id) REFERENCES professors(prof_id)
);

-- 10. Create triggers
-- Prevent student from enrolling in the same course more than once
CREATE OR REPLACE TRIGGER trg_prevent_duplicate_enrollment
BEFORE INSERT OR UPDATE ON enrollments
FOR EACH ROW
DECLARE
    count_enrollments NUMBER;
BEGIN
    IF INSERTING THEN
        SELECT COUNT(*)
        INTO count_enrollments
        FROM enrollments
        WHERE student_id = :NEW.student_id
        AND course_id = :NEW.course_id;
        
        IF count_enrollments > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Student already enrolled in this course');
        END IF;
    END IF;
END;
/

-- Ensure classroom capacity is sufficient
CREATE OR REPLACE TRIGGER trg_check_classroom_capacity
BEFORE INSERT OR UPDATE ON enrollments
FOR EACH ROW
DECLARE
    classroom_capacity NUMBER;
    students_count NUMBER;
    v_classroom_ref REF classroom_t;
BEGIN
    -- Get the classroom reference for this course
    SELECT c.classroom INTO v_classroom_ref
    FROM courses c
    WHERE c.course_id = :NEW.course_id;
    
    -- Get the classroom capacity
    SELECT cl.capacity INTO classroom_capacity
    FROM classrooms cl
    WHERE REF(cl) = v_classroom_ref;
    
    -- Get the number of enrolled students for this course
    SELECT COUNT(*) INTO students_count
    FROM enrollments e
    WHERE e.course_id = :NEW.course_id;
    
    -- Check if capacity is sufficient (including the new enrollment)
    IF classroom_capacity < (students_count + 1) THEN
        RAISE_APPLICATION_ERROR(-20002, 'Classroom capacity is insufficient for the number of enrolled students');
    END IF;
END;
/

-- Ensure no time overlap for courses in the same classroom
CREATE OR REPLACE TRIGGER trg_prevent_time_overlap
BEFORE INSERT OR UPDATE ON courses
FOR EACH ROW
DECLARE
    overlap_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO overlap_count
    FROM courses c
    WHERE c.classroom = :NEW.classroom
    AND c.course_id != :NEW.course_id
    AND c.time_slot.day_of_week = :NEW.time_slot.day_of_week
    AND (
        (:NEW.time_slot.start_time BETWEEN c.time_slot.start_time AND c.time_slot.end_time)
        OR
        (:NEW.time_slot.end_time BETWEEN c.time_slot.start_time AND c.time_slot.end_time)
        OR
        (c.time_slot.start_time BETWEEN :NEW.time_slot.start_time AND :NEW.time_slot.end_time)
    );
    
    IF overlap_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Time slot overlaps with an existing course in the same classroom');
    END IF;
END;
/

-- Prevent course deletion if students are enrolled
CREATE OR REPLACE TRIGGER trg_prevent_course_deletion
BEFORE DELETE ON courses
FOR EACH ROW
DECLARE
    enrollments_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO enrollments_count
    FROM enrollments e
    WHERE e.course_id = :OLD.course_id;
    
    IF enrollments_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot delete course with enrolled students');
    END IF;
END;
/

-- Ensure each department has a head professor
CREATE OR REPLACE TRIGGER trg_check_department_head
BEFORE INSERT OR UPDATE ON departments
FOR EACH ROW
BEGIN
    IF :NEW.head_prof IS NULL THEN
        RAISE_APPLICATION_ERROR(-20005, 'Each department must have a head professor');
    END IF;
END;
/

-- Ensure a professor can head only one department
CREATE OR REPLACE TRIGGER trg_check_prof_head_one_dept
BEFORE INSERT OR UPDATE ON departments
FOR EACH ROW
DECLARE
    dept_count NUMBER;
    v_prof_id NUMBER;
BEGIN
    -- Get the professor ID from the REF
    SELECT p.prof_id INTO v_prof_id
    FROM professors p
    WHERE REF(p) = :NEW.head_prof;
    
    -- Check if this professor is heading any other department
    SELECT COUNT(*) INTO dept_count
    FROM departments d
    WHERE d.dept_id != :NEW.dept_id
    AND DEREF(d.head_prof).prof_id = v_prof_id;
    
    IF dept_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'A professor can head only one department');
    END IF;
END;
/

-- Ensure assignment belongs to only one course (consistency with nested table)
CREATE OR REPLACE TRIGGER trg_sync_assignments_with_courses
AFTER INSERT OR UPDATE ON assignments
FOR EACH ROW
DECLARE
    v_assignment_exists NUMBER;
BEGIN
    -- Check if this assignment_id exists in any course's nested assignment list
    SELECT COUNT(*)
    INTO v_assignment_exists
    FROM courses c, TABLE(c.assignments) a
    WHERE a.assignment_id = :NEW.assignment_id
    AND c.course_id != :NEW.course_id;
    
    IF v_assignment_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Each assignment can belong to only one course');
    END IF;
END;
/

-- Synchronize assignments when course nested table is updated
CREATE OR REPLACE TRIGGER trg_sync_course_assignments
AFTER INSERT ON courses
FOR EACH ROW
DECLARE
BEGIN
    -- For each assignment in the nested table, insert into assignments table
    FOR i IN 1..(:NEW.assignments.COUNT) LOOP
        INSERT INTO assignments (
            assignment_id, 
            title, 
            description, 
            due_date, 
            course_id
        ) VALUES (
            :NEW.assignments(i).assignment_id,
            :NEW.assignments(i).title,
            :NEW.assignments(i).description,
            :NEW.assignments(i).due_date,
            :NEW.course_id
        );
    END LOOP;
END;
/

-- 11. Create views
-- View that displays students along with their enrolled courses
CREATE OR REPLACE VIEW vw_student_courses AS
SELECT 
    s.student_id,
    s.name AS student_name,
    c.course_id,
    c.course_name,
    e.enrollment_date
FROM 
    students s,
    courses c,
    enrollments e
WHERE 
    e.student_id = s.student_id
    AND e.course_id = c.course_id;

-- View that returns a student's transcript with all grades
CREATE OR REPLACE VIEW vw_student_transcript AS
SELECT 
    s.student_id,
    s.name AS student_name,
    c.course_id,
    c.course_name,
    a.assignment_id,
    a.title AS assignment_title,
    g.grade_value,
    g.graded_date
FROM 
    students s,
    courses c,
    grades g,
    assignments a
WHERE 
    g.student_id = s.student_id
    AND g.course_id = c.course_id
    AND g.assignment_id = a.assignment_id
ORDER BY 
    s.student_id, c.course_id, a.assignment_id;

-- View that displays a weekly schedule for a student or professor
CREATE OR REPLACE VIEW vw_weekly_schedule AS
SELECT 
    'Student' AS person_type,
    s.student_id AS person_id,
    s.name AS person_name,
    c.course_id,
    c.course_name,
    c.time_slot.day_of_week,
    c.time_slot.start_time,
    c.time_slot.end_time,
    cl.room_number
FROM 
    students s,
    courses c,
    enrollments e,
    classrooms cl
WHERE 
    e.student_id = s.student_id
    AND e.course_id = c.course_id
    AND c.classroom = REF(cl)
UNION
SELECT 
    'Professor' AS person_type,
    p.prof_id AS person_id,
    p.name AS person_name,
    c.course_id,
    c.course_name,
    c.time_slot.day_of_week,
    c.time_slot.start_time,
    c.time_slot.end_time,
    cl.room_number
FROM 
    professors p,
    courses c,
    professor_courses pc,
    classrooms cl
WHERE 
    pc.professor_id = p.prof_id
    AND pc.course_id = c.course_id
    AND c.classroom = REF(cl);

-- View that finds the total number of students in each course
CREATE OR REPLACE VIEW vw_course_enrollment_count AS
SELECT 
    c.course_id,
    c.course_name,
    COUNT(e.student_id) AS num_students
FROM 
    courses c
    LEFT JOIN enrollments e ON e.course_id = c.course_id
GROUP BY 
    c.course_id, c.course_name;

-- FIXED VIEW: View that lists students who haven't submitted ANY assignments (not just some)
CREATE OR REPLACE VIEW vw_students_without_submissions AS
SELECT 
    s.student_id,
    s.name
FROM 
    students s
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM grades g
        WHERE g.student_id = s.student_id
    );

-- View that finds the student with the highest average
CREATE OR REPLACE VIEW vw_highest_avg_student AS
WITH student_averages AS (
    SELECT 
        s.student_id,
        s.name,
        AVG(g.grade_value) AS avg_grade,
        RANK() OVER (ORDER BY AVG(g.grade_value) DESC) AS grade_rank
    FROM 
        students s,
        grades g
    WHERE 
        g.student_id = s.student_id
    GROUP BY 
        s.student_id, s.name
)
SELECT 
    student_id,
    name,
    avg_grade
FROM 
    student_averages
WHERE 
    grade_rank = 1;

-- View that finds the average grade for each course
CREATE OR REPLACE VIEW vw_course_avg_grades AS
SELECT 
    c.course_id,
    c.course_name,
    AVG(g.grade_value) AS avg_grade
FROM 
    courses c,
    grades g
WHERE 
    g.course_id = c.course_id
GROUP BY 
    c.course_id, c.course_name;

-- Create a view that lists assignments per course
CREATE OR REPLACE VIEW vw_course_assignments AS
SELECT 
    c.course_id,
    c.course_name,
    a.assignment_id,
    a.title,
    a.description,
    a.due_date
FROM 
    courses c,
    assignments a
WHERE 
    a.course_id = c.course_id
ORDER BY 
    c.course_id, a.due_date;

-- Create a view that shows assignment submissions and grades
CREATE OR REPLACE VIEW vw_assignment_submissions AS
SELECT 
    a.assignment_id,
    a.title,
    a.due_date,
    c.course_id,
    c.course_name,
    s.student_id,
    s.name AS student_name,
    g.grade_value,
    g.graded_date,
    CASE
        WHEN g.grade_value IS NULL THEN 'Not Submitted'
        ELSE 'Submitted'
    END AS submission_status
FROM 
    assignments a
    JOIN courses c ON a.course_id = c.course_id
    JOIN enrollments e ON c.course_id = e.course_id
    JOIN students s ON e.student_id = s.student_id
    LEFT JOIN grades g ON g.student_id = s.student_id 
                      AND g.course_id = c.course_id 
                      AND g.assignment_id = a.assignment_id
ORDER BY 
    a.due_date, c.course_name, s.name;

-- 12. Final commit to save all changes
COMMIT;

-- 13. Test Case: Create a simple script to demonstrate that the schema is ready
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== University Course Management System (UCMS) =====');
    DBMS_OUTPUT.PUT_LINE('Schema successfully created with the following objects:');
    
    -- Count object types
    DECLARE
        type_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO type_count FROM user_types;
        DBMS_OUTPUT.PUT_LINE('- ' || type_count || ' object types');
    END;
    
    -- Count tables
    DECLARE
        table_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO table_count FROM user_tables;
        DBMS_OUTPUT.PUT_LINE('- ' || table_count || ' tables');
    END;
    
    -- Count triggers
    DECLARE
        trigger_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO trigger_count FROM user_triggers;
        DBMS_OUTPUT.PUT_LINE('- ' || trigger_count || ' triggers');
    END;
    
    -- Count views
    DECLARE
        view_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO view_count FROM user_views;
        DBMS_OUTPUT.PUT_LINE('- ' || view_count || ' views');
    END;
    
    -- Count sequences
    DECLARE
        seq_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO seq_count FROM user_sequences;
        DBMS_OUTPUT.PUT_LINE('- ' || seq_count || ' sequences');
    END;
    
    DBMS_OUTPUT.PUT_LINE('Schema creation completed successfully. Ready for data insertion.');
END;
/